require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY);

// ==========================================
// TASKS ROUTING (CRUD)
// ==========================================

app.get('/api/tasks', async (req, res) => {
  const { data, error } = await supabase.from('tasks').select('*').order('start_time', { ascending: true });
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.post('/api/tasks', async (req, res) => {
  const { title, category, day_of_week, start_time, end_time, milestone_id, alarm_enabled } = req.body;
  if (!title || !category || !day_of_week || !start_time || !end_time)
    return res.status(400).json({ error: 'Please provide all required task fields.' });
  const { data, error } = await supabase.from('tasks')
    .insert([{ title, category, day_of_week, start_time, end_time, milestone_id: milestone_id || null, alarm_enabled: alarm_enabled !== undefined ? alarm_enabled : true }])
    .select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.status(201).json(data);
});

app.put('/api/tasks/:id', async (req, res) => {
  const { data, error } = await supabase.from('tasks').update(req.body).eq('id', req.params.id).select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.delete('/api/tasks/:id', async (req, res) => {
  const { error } = await supabase.from('tasks').delete().eq('id', req.params.id);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ message: 'Task deleted successfully', id: req.params.id });
});

// ==========================================
// PROJECTS & MILESTONES ROUTING (CRUD)
// ==========================================

app.get('/api/projects', async (req, res) => {
  const { data: projects, error } = await supabase.from('projects').select('*, milestones(*)').order('created_at', { ascending: false });
  if (error) return res.status(500).json({ error: error.message });
  res.json(projects);
});

app.post('/api/projects', async (req, res) => {
  const { title, description } = req.body;
  if (!title) return res.status(400).json({ error: 'Project title is required' });
  const { data, error } = await supabase.from('projects').insert([{ title, description }]).select().single();
  if (error) return res.status(500).json({ error: error.message });
  data.milestones = [];
  res.status(201).json(data);
});

app.delete('/api/projects/:id', async (req, res) => {
  const { error } = await supabase.from('projects').delete().eq('id', req.params.id);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ message: 'Project deleted', id: req.params.id });
});

app.post('/api/projects/:id/milestones', async (req, res) => {
  const { title, due_date } = req.body;
  if (!title) return res.status(400).json({ error: 'Milestone title is required' });
  const { data, error } = await supabase.from('milestones')
    .insert([{ project_id: req.params.id, title, due_date: due_date || null }])
    .select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.status(201).json(data);
});

app.put('/api/milestones/:id', async (req, res) => {
  const { data, error } = await supabase.from('milestones').update(req.body).eq('id', req.params.id).select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.delete('/api/milestones/:id', async (req, res) => {
  const { error } = await supabase.from('milestones').delete().eq('id', req.params.id);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ message: 'Milestone deleted', id: req.params.id });
});

// ==========================================
// REFLECTIONS ROUTING (CRUD)
// ==========================================

app.get('/api/reflections', async (req, res) => {
  const { data, error } = await supabase.from('reflections').select('*').order('date', { ascending: false });
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.post('/api/reflections', async (req, res) => {
  const { date, adherence_score, focus_score, energy_score, notes_success, notes_struggles, notes_improvements } = req.body;
  if (!date || adherence_score === undefined || focus_score === undefined || energy_score === undefined)
    return res.status(400).json({ error: 'Please provide date, adherence, focus and energy scores.' });
  const { data, error } = await supabase.from('reflections')
    .upsert({ date, adherence_score, focus_score, energy_score, notes_success: notes_success || '', notes_struggles: notes_struggles || '', notes_improvements: notes_improvements || '' }, { onConflict: 'date' })
    .select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.status(201).json(data);
});

// ==========================================
// ANALYTICS & SMART COACHING ENGINE
// ==========================================
app.get('/api/analytics', async (req, res) => {
  try {
    const { data: tasks, error: tasksError } = await supabase.from('tasks').select('*');
    const { data: reflections, error: refError } = await supabase.from('reflections').select('*').order('date', { ascending: true });
    
    if (tasksError) throw tasksError;
    if (refError) throw refError;

    const categoryStats = {};
    let totalScheduledMinutes = 0;
    let totalActualMinutes = 0;
    let completedCount = 0;
    let totalCount = tasks.length;

    tasks.forEach(t => {
      const [sh, sm] = t.start_time.split(':').map(Number);
      const [eh, em] = t.end_time.split(':').map(Number);
      let diff = (eh * 60 + em) - (sh * 60 + sm);
      if (diff < 0) diff += 24 * 60;

      if (!categoryStats[t.category]) {
        categoryStats[t.category] = { scheduled: 0, actual: 0, tasksCount: 0, completedCount: 0 };
      }

      categoryStats[t.category].scheduled += diff;
      categoryStats[t.category].actual += t.actual_minutes_spent || 0;
      categoryStats[t.category].tasksCount++;
      if (t.completed) {
        categoryStats[t.category].completedCount++;
        completedCount++;
      }

      totalScheduledMinutes += diff;
      totalActualMinutes += t.actual_minutes_spent || 0;
    });

    let overallTaskAdherence = totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;

    const focusTrend = reflections.map(r => ({ date: r.date, score: r.focus_score }));
    const energyTrend = reflections.map(r => ({ date: r.date, score: r.energy_score }));
    const adherenceTrend = reflections.map(r => ({ date: r.date, score: r.adherence_score }));

    const suggestions = [];

    if (adherenceTrend.length > 0) {
      const avgAdherence = adherenceTrend.reduce((acc, curr) => acc + curr.score, 0) / adherenceTrend.length;
      if (avgAdherence < 70) {
        suggestions.push({
          type: 'warning',
          title: 'Schedule Overload Detected',
          text: `Your average daily plan adherence is only ${Math.round(avgAdherence)}%. You may be scheduling too many back-to-back blocks.`
        });
      }
    }

    Object.keys(categoryStats).forEach(cat => {
      const stats = categoryStats[cat];
      const completionRate = (stats.completedCount / stats.tasksCount) * 100;
      if (completionRate < 60 && stats.tasksCount >= 2) {
        suggestions.push({
          type: 'danger',
          title: `Slipping in ${cat.toUpperCase()}`,
          text: `You have completed only ${Math.round(completionRate)}% of your scheduled "${cat}" tasks. Consider rescheduling them.`
        });
      }
    });

    if (reflections.length >= 3) {
      const lowEnergyDays = reflections.filter(r => r.energy_score <= 5);
      const highEnergyDays = reflections.filter(r => r.energy_score >= 8);
      
      const avgFocusLowEnergy = lowEnergyDays.length > 0 
        ? lowEnergyDays.reduce((acc, curr) => acc + curr.focus_score, 0) / lowEnergyDays.length : 0;
      const avgFocusHighEnergy = highEnergyDays.length > 0 
        ? highEnergyDays.reduce((acc, curr) => acc + curr.focus_score, 0) / highEnergyDays.length : 0;

      if (avgFocusHighEnergy - avgFocusLowEnergy > 2) {
        suggestions.push({
          type: 'success',
          title: 'Energy Drives Focus',
          text: `On high energy days, your focus scores averaged ${Math.round(avgFocusHighEnergy * 10) / 10}, significantly higher than low energy days (${Math.round(avgFocusLowEnergy * 10) / 10}).`
        });
      }
    }

    if (suggestions.length === 0) {
      suggestions.push({
        type: 'success',
        title: 'Maintaining Excellent Flow',
        text: 'Fantastic! Your planned schedules and completed reflections show high consistency.'
      });
    }

    res.json({
      summary: {
        totalTasks: totalCount,
        completedTasks: completedCount,
        completionRate: overallTaskAdherence,
        scheduledMinutes: totalScheduledMinutes,
        actualMinutes: totalActualMinutes
      },
      categoryStats,
      trends: { focusTrend, energyTrend, adherenceTrend },
      suggestions
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Aether API Server running on port ${PORT}`);
});
