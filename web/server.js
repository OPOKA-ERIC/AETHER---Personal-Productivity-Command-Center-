const express = require('express');
const cors = require('cors');
const path = require('path');
const sqlite3 = require('sqlite3');

const app = express();
const PORT = process.env.PORT || 3000;
const DB_PATH = path.join(__dirname, '..', 'tracker.db');

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

function getDB() {
  return new sqlite3.Database(DB_PATH, sqlite3.OPEN_READWRITE);
}

function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    const db = getDB();
    db.run(sql, params, function (err) {
      db.close();
      if (err) reject(err);
      else resolve({ lastID: this.lastID, changes: this.changes });
    });
  });
}

function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    const db = getDB();
    db.get(sql, params, (err, row) => {
      db.close();
      if (err) reject(err);
      else resolve(row);
    });
  });
}

function all(sql, params = []) {
  return new Promise((resolve, reject) => {
    const db = getDB();
    db.all(sql, params, (err, rows) => {
      db.close();
      if (err) reject(err);
      else resolve(rows);
    });
  });
}

// ==========================================
// TASKS ROUTING (CRUD)
// ==========================================

app.get('/api/tasks', async (req, res) => {
  try {
    const data = await all('SELECT * FROM tasks ORDER BY start_time ASC');
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/tasks', async (req, res) => {
  const { title, category, day_of_week, start_time, end_time, milestone_id, alarm_enabled, completed, actual_minutes_spent } = req.body;
  if (!title || !category || !day_of_week || !start_time || !end_time)
    return res.status(400).json({ error: 'Please provide all required task fields.' });
  try {
    const result = await run(
      'INSERT INTO tasks (title, category, day_of_week, start_time, end_time, milestone_id, alarm_enabled, completed, actual_minutes_spent) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [title, category, day_of_week, start_time, end_time, milestone_id || null, alarm_enabled !== undefined ? (alarm_enabled ? 1 : 0) : 1, completed ? 1 : 0, actual_minutes_spent || 0]
    );
    const data = await get('SELECT * FROM tasks WHERE id = ?', [result.lastID]);
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/tasks/:id', async (req, res) => {
  try {
    const fields = [];
    const values = [];
    const allowed = ['title', 'category', 'day_of_week', 'start_time', 'end_time', 'milestone_id', 'alarm_enabled', 'completed', 'actual_minutes_spent'];
    allowed.forEach(f => {
      if (req.body[f] !== undefined) {
        fields.push(f + ' = ?');
        values.push(f === 'alarm_enabled' || f === 'completed' ? (req.body[f] ? 1 : 0) : req.body[f]);
      }
    });
    if (fields.length === 0) return res.status(400).json({ error: 'No fields to update' });
    values.push(req.params.id);
    await run('UPDATE tasks SET ' + fields.join(', ') + ' WHERE id = ?', values);
    const data = await get('SELECT * FROM tasks WHERE id = ?', [req.params.id]);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/tasks/:id', async (req, res) => {
  try {
    await run('DELETE FROM tasks WHERE id = ?', [req.params.id]);
    res.json({ message: 'Task deleted successfully', id: req.params.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// PROJECTS & MILESTONES ROUTING (CRUD)
// ==========================================

app.get('/api/projects', async (req, res) => {
  try {
    const projects = await all('SELECT * FROM projects ORDER BY created_at DESC');
    for (let p of projects) {
      p.milestones = await all('SELECT * FROM milestones WHERE project_id = ?', [p.id]);
    }
    res.json(projects);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/projects', async (req, res) => {
  const { title, description } = req.body;
  if (!title) return res.status(400).json({ error: 'Project title is required' });
  try {
    const result = await run('INSERT INTO projects (title, description) VALUES (?, ?)', [title, description || '']);
    const data = await get('SELECT * FROM projects WHERE id = ?', [result.lastID]);
    data.milestones = [];
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/projects/:id', async (req, res) => {
  try {
    await run('DELETE FROM milestones WHERE project_id = ?', [req.params.id]);
    await run('DELETE FROM projects WHERE id = ?', [req.params.id]);
    res.json({ message: 'Project deleted', id: req.params.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/projects/:id/milestones', async (req, res) => {
  const { title, due_date } = req.body;
  if (!title) return res.status(400).json({ error: 'Milestone title is required' });
  try {
    const project = await get('SELECT id FROM projects WHERE id = ?', [req.params.id]);
    if (!project) return res.status(404).json({ error: 'Project not found' });
    const result = await run('INSERT INTO milestones (project_id, title, due_date) VALUES (?, ?, ?)', [req.params.id, title, due_date || null]);
    const data = await get('SELECT * FROM milestones WHERE id = ?', [result.lastID]);
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/milestones/:id', async (req, res) => {
  try {
    const fields = [];
    const values = [];
    const allowed = ['title', 'due_date', 'completed'];
    allowed.forEach(f => {
      if (req.body[f] !== undefined) {
        fields.push(f + ' = ?');
        values.push(f === 'completed' ? (req.body[f] ? 1 : 0) : req.body[f]);
      }
    });
    if (fields.length === 0) return res.status(400).json({ error: 'No fields to update' });
    values.push(req.params.id);
    await run('UPDATE milestones SET ' + fields.join(', ') + ' WHERE id = ?', values);
    const data = await get('SELECT * FROM milestones WHERE id = ?', [req.params.id]);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/milestones/:id', async (req, res) => {
  try {
    await run('DELETE FROM milestones WHERE id = ?', [req.params.id]);
    res.json({ message: 'Milestone deleted', id: req.params.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// REFLECTIONS ROUTING (CRUD)
// ==========================================

app.get('/api/reflections', async (req, res) => {
  try {
    const data = await all('SELECT * FROM reflections ORDER BY date DESC');
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/reflections', async (req, res) => {
  const { date, adherence_score, focus_score, energy_score, notes_success, notes_struggles, notes_improvements } = req.body;
  if (!date || adherence_score === undefined || focus_score === undefined || energy_score === undefined)
    return res.status(400).json({ error: 'Please provide date, adherence, focus and energy scores.' });
  try {
    const existing = await get('SELECT id FROM reflections WHERE date = ?', [date]);
    if (existing) {
      await run(
        'UPDATE reflections SET adherence_score = ?, focus_score = ?, energy_score = ?, notes_success = ?, notes_struggles = ?, notes_improvements = ? WHERE id = ?',
        [adherence_score, focus_score, energy_score, notes_success || '', notes_struggles || '', notes_improvements || '', existing.id]
      );
    } else {
      await run(
        'INSERT INTO reflections (date, adherence_score, focus_score, energy_score, notes_success, notes_struggles, notes_improvements) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [date, adherence_score, focus_score, energy_score, notes_success || '', notes_struggles || '', notes_improvements || '']
      );
    }
    const data = await get('SELECT * FROM reflections WHERE date = ?', [date]);
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// ANALYTICS & SMART COACHING ENGINE
// ==========================================
app.get('/api/analytics', async (req, res) => {
  try {
    const tasks = await all("SELECT * FROM tasks");
    const reflections = await all("SELECT * FROM reflections ORDER BY date ASC");

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
