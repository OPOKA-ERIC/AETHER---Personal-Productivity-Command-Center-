const express = require('express');
const cors = require('cors');
const path = require('path');
const { supabase } = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const USE_SUPABASE = !!supabase;

// Check if Supabase tasks table has 'date' column
if (USE_SUPABASE) {
  (async () => {
    try {
      const { error } = await supabase.from('tasks').select('date').limit(0);
      if (error) {
        console.warn('\n⚠️  Supabase tasks table is missing the "date" column.');
        console.warn('   Run this in your Supabase SQL editor:');
        console.warn('   https://supabase.com/dashboard/project/itrdghrsjztzlgtnrmds/sql/new');
        console.warn('   SQL: ALTER TABLE tasks ADD COLUMN IF NOT EXISTS date TEXT;\n');
      }
    } catch (_) {}
  })();
}

// ---- Database abstraction layer ----
const db = {};

if (!USE_SUPABASE) {
  const fs = require('fs');
  const sqlite3 = require('sqlite3');
  const DB_PATH = path.join(__dirname, '..', 'tracker.db');

  function getDB() {
    return new sqlite3.Database(DB_PATH, sqlite3.OPEN_CREATE | sqlite3.OPEN_READWRITE);
  }

  (function initSQLite() {
    const d = getDB();
    d.serialize(() => {
      d.run(`CREATE TABLE IF NOT EXISTS projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'active',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);
      d.run(`CREATE TABLE IF NOT EXISTS milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        due_date TEXT,
        completed INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);
      d.run(`CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        day_of_week TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        milestone_id INTEGER REFERENCES milestones(id) ON DELETE SET NULL,
        alarm_enabled INTEGER DEFAULT 1,
        actual_minutes_spent INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0,
        date TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);
      d.run(`ALTER TABLE tasks ADD COLUMN date TEXT`, () => {});
      d.run(`CREATE TABLE IF NOT EXISTS reflections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        adherence_score INTEGER NOT NULL,
        focus_score INTEGER NOT NULL,
        energy_score INTEGER NOT NULL,
        notes_success TEXT,
        notes_struggles TEXT,
        notes_improvements TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);
    });
    d.close();
    console.log(`SQLite ready at ${DB_PATH}`);
  })();

  db.run = function run(sql, params = []) {
    return new Promise((resolve, reject) => {
      const d = getDB();
      d.run(sql, params, function (err) {
        d.close();
        if (err) reject(err);
        else resolve({ lastID: this.lastID, changes: this.changes });
      });
    });
  };

  db.get = function get(sql, params = []) {
    return new Promise((resolve, reject) => {
      const d = getDB();
      d.get(sql, params, (err, row) => {
        d.close();
        if (err) reject(err);
        else resolve(row);
      });
    });
  };

  db.all = function all(sql, params = []) {
    return new Promise((resolve, reject) => {
      const d = getDB();
      d.all(sql, params, (err, rows) => {
        d.close();
        if (err) reject(err);
        else resolve(rows);
      });
    });
  };

  console.log('Using SQLite backend');
} else {
  // ---- Supabase backend ----
  console.log('Supabase mode active — ensure tables exist (run schema.sql in Supabase SQL editor)');

  db.run = async function run(table, data) {
    const { data: inserted, error } = await supabase.from(table).insert(data).select();
    if (error) throw error;
    return { lastID: inserted?.[0]?.id, data: inserted?.[0] };
  };

  db.get = async function get(table, field, value) {
    const { data, error } = await supabase.from(table).select('*').eq(field, value).maybeSingle();
    if (error) throw error;
    return data;
  };

  db.all = async function all(table, orderBy) {
    let query = supabase.from(table).select('*');
    if (orderBy) {
      const parts = orderBy.split(' ');
      query = query.order(parts[0], { ascending: parts[1] !== 'DESC' });
    }
    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  };

  db.allWhere = async function allWhere(table, field, value, orderBy) {
    let query = supabase.from(table).select('*').eq(field, value);
    if (orderBy) {
      const parts = orderBy.split(' ');
      query = query.order(parts[0], { ascending: parts[1] !== 'DESC' });
    }
    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  };

  db.update = async function update(table, id, updates) {
    const { data, error } = await supabase.from(table).update(updates).eq('id', id).select();
    if (error) throw error;
    return data?.[0];
  };

  db.remove = async function remove(table, id) {
    const { error } = await supabase.from(table).delete().eq('id', id);
    if (error) throw error;
  };

  db.removeWhere = async function removeWhere(table, field, value) {
    const { error } = await supabase.from(table).delete().eq(field, value);
    if (error) throw error;
  };

  console.log('Using Supabase backend');
}

// ==========================================
// TASKS CRUD
// ==========================================

app.get('/api/tasks', async (req, res) => {
  try {
    if (USE_SUPABASE) {
      const data = await db.all('tasks', 'start_time ASC');
      res.json(data.map(normalizeTask));
    } else {
      const data = await db.all('SELECT * FROM tasks ORDER BY start_time ASC');
      res.json(data);
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/tasks', async (req, res) => {
  const { title, category, day_of_week, start_time, end_time, milestone_id, alarm_enabled, completed, actual_minutes_spent, date } = req.body;
  if (!title || !category || !day_of_week || !start_time || !end_time)
    return res.status(400).json({ error: 'Please provide all required task fields.' });
  try {
    let data;
    if (USE_SUPABASE) {
      const payload = {
        title, category, day_of_week, start_time, end_time,
        milestone_id: milestone_id || null,
        alarm_enabled: alarm_enabled !== undefined ? !!alarm_enabled : true,
        completed: !!completed,
        actual_minutes_spent: actual_minutes_spent || 0
      };
      if (date) payload.date = date;
      const { data: inserted, error } = await supabase.from('tasks').insert(payload).select();
      if (error) {
        // If date column doesn't exist, retry without it
        if (error.message?.includes('date') && error.code === 'PGRST204') {
          delete payload.date;
          const { data: retry, error: retryErr } = await supabase.from('tasks').insert(payload).select();
          if (retryErr) throw retryErr;
          data = normalizeTask(retry[0]);
        } else {
          throw error;
        }
      } else {
        data = normalizeTask(inserted[0]);
      }
    } else {
      const result = await db.run(
        'INSERT INTO tasks (title, category, day_of_week, start_time, end_time, milestone_id, alarm_enabled, completed, actual_minutes_spent, date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [title, category, day_of_week, start_time, end_time, milestone_id || null, alarm_enabled !== undefined ? (alarm_enabled ? 1 : 0) : 1, completed ? 1 : 0, actual_minutes_spent || 0, date || null]
      );
      data = await db.get('SELECT * FROM tasks WHERE id = ?', [result.lastID]);
    }
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/tasks/:id', async (req, res) => {
  try {
    let data;
    if (USE_SUPABASE) {
      const allowed = ['title', 'category', 'day_of_week', 'start_time', 'end_time', 'milestone_id', 'alarm_enabled', 'completed', 'actual_minutes_spent', 'date'];
      const updates = {};
      allowed.forEach(f => {
        if (req.body[f] !== undefined) {
          updates[f] = (f === 'alarm_enabled' || f === 'completed') ? !!req.body[f] : req.body[f];
        }
      });
      if (Object.keys(updates).length === 0) return res.status(400).json({ error: 'No fields to update' });
      try {
        data = await db.update('tasks', req.params.id, updates);
      } catch (updateErr) {
        // If date column missing, retry without date field
        if (updateErr.message?.includes('date') && updates.date) {
          delete updates.date;
          data = await db.update('tasks', req.params.id, updates);
        } else {
          throw updateErr;
        }
      }
      if (data) data = normalizeTask(data);
    } else {
      const fields = [];
      const values = [];
      const allowed = ['title', 'category', 'day_of_week', 'start_time', 'end_time', 'milestone_id', 'alarm_enabled', 'completed', 'actual_minutes_spent', 'date'];
      allowed.forEach(f => {
        if (req.body[f] !== undefined) {
          fields.push(f + ' = ?');
          values.push((f === 'alarm_enabled' || f === 'completed') ? (req.body[f] ? 1 : 0) : req.body[f]);
        }
      });
      if (fields.length === 0) return res.status(400).json({ error: 'No fields to update' });
      values.push(req.params.id);
      await db.run('UPDATE tasks SET ' + fields.join(', ') + ' WHERE id = ?', values);
      data = await db.get('SELECT * FROM tasks WHERE id = ?', [req.params.id]);
    }
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/tasks/:id', async (req, res) => {
  try {
    if (USE_SUPABASE) {
      await db.remove('tasks', req.params.id);
    } else {
      await db.run('DELETE FROM tasks WHERE id = ?', [req.params.id]);
    }
    res.json({ message: 'Task deleted successfully', id: req.params.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// PROJECTS & MILESTONES CRUD
// ==========================================

app.get('/api/projects', async (req, res) => {
  try {
    let projects;
    if (USE_SUPABASE) {
      projects = await db.all('projects', 'created_at DESC');
      for (const p of projects) {
        p.milestones = await db.allWhere('milestones', 'project_id', p.id, 'created_at ASC');
      }
    } else {
      projects = await db.all('SELECT * FROM projects ORDER BY created_at DESC');
      for (const p of projects) {
        p.milestones = await db.all('SELECT * FROM milestones WHERE project_id = ? ORDER BY created_at ASC', [p.id]);
      }
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
    let data;
    if (USE_SUPABASE) {
      const { data: inserted, error } = await supabase.from('projects').insert({ title, description: description || '' }).select();
      if (error) throw error;
      data = inserted[0];
    } else {
      const result = await db.run('INSERT INTO projects (title, description) VALUES (?, ?)', [title, description || '']);
      data = await db.get('SELECT * FROM projects WHERE id = ?', [result.lastID]);
    }
    data.milestones = [];
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/projects/:id', async (req, res) => {
  try {
    if (USE_SUPABASE) {
      await db.removeWhere('milestones', 'project_id', req.params.id);
      await db.remove('projects', req.params.id);
    } else {
      await db.run('DELETE FROM milestones WHERE project_id = ?', [req.params.id]);
      await db.run('DELETE FROM projects WHERE id = ?', [req.params.id]);
    }
    res.json({ message: 'Project deleted', id: req.params.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/projects/:id/milestones', async (req, res) => {
  const { title, due_date } = req.body;
  if (!title) return res.status(400).json({ error: 'Milestone title is required' });
  try {
    let data;
    if (USE_SUPABASE) {
      const project = await db.get('projects', 'id', req.params.id);
      if (!project) return res.status(404).json({ error: 'Project not found' });
      const { data: inserted, error } = await supabase.from('milestones').insert({ project_id: req.params.id, title, due_date: due_date || null }).select();
      if (error) throw error;
      data = inserted[0];
    } else {
      const project = await db.get('SELECT id FROM projects WHERE id = ?', [req.params.id]);
      if (!project) return res.status(404).json({ error: 'Project not found' });
      const result = await db.run('INSERT INTO milestones (project_id, title, due_date) VALUES (?, ?, ?)', [req.params.id, title, due_date || null]);
      data = await db.get('SELECT * FROM milestones WHERE id = ?', [result.lastID]);
    }
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/milestones/:id', async (req, res) => {
  try {
    let data;
    if (USE_SUPABASE) {
      const allowed = ['title', 'due_date', 'completed'];
      const updates = {};
      allowed.forEach(f => {
        if (req.body[f] !== undefined) {
          updates[f] = f === 'completed' ? !!req.body[f] : req.body[f];
        }
      });
      if (Object.keys(updates).length === 0) return res.status(400).json({ error: 'No fields to update' });
      data = await db.update('milestones', req.params.id, updates);
    } else {
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
      await db.run('UPDATE milestones SET ' + fields.join(', ') + ' WHERE id = ?', values);
      data = await db.get('SELECT * FROM milestones WHERE id = ?', [req.params.id]);
    }
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/milestones/:id', async (req, res) => {
  try {
    if (USE_SUPABASE) {
      await db.remove('milestones', req.params.id);
    } else {
      await db.run('DELETE FROM milestones WHERE id = ?', [req.params.id]);
    }
    res.json({ message: 'Milestone deleted', id: req.params.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// REFLECTIONS CRUD
// ==========================================

app.get('/api/reflections', async (req, res) => {
  try {
    const data = USE_SUPABASE ? await db.all('reflections', 'date DESC') : await db.all('SELECT * FROM reflections ORDER BY date DESC');
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
    let data;
    if (USE_SUPABASE) {
      const existing = await db.get('reflections', 'date', date);
      if (existing) {
        data = await db.update('reflections', existing.id, {
          adherence_score, focus_score, energy_score,
          notes_success: notes_success || '', notes_struggles: notes_struggles || '', notes_improvements: notes_improvements || ''
        });
      } else {
        const { data: inserted, error } = await supabase.from('reflections').insert({
          date, adherence_score, focus_score, energy_score,
          notes_success: notes_success || '', notes_struggles: notes_struggles || '', notes_improvements: notes_improvements || ''
        }).select();
        if (error) throw error;
        data = inserted[0];
      }
    } else {
      const existing = await db.get('SELECT id FROM reflections WHERE date = ?', [date]);
      if (existing) {
        await db.run(
          'UPDATE reflections SET adherence_score = ?, focus_score = ?, energy_score = ?, notes_success = ?, notes_struggles = ?, notes_improvements = ? WHERE id = ?',
          [adherence_score, focus_score, energy_score, notes_success || '', notes_struggles || '', notes_improvements || '', existing.id]
        );
      } else {
        await db.run(
          'INSERT INTO reflections (date, adherence_score, focus_score, energy_score, notes_success, notes_struggles, notes_improvements) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [date, adherence_score, focus_score, energy_score, notes_success || '', notes_struggles || '', notes_improvements || '']
        );
      }
      data = await db.get('SELECT * FROM reflections WHERE date = ?', [date]);
    }
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
    let tasks, reflections;
    if (USE_SUPABASE) {
      tasks = await db.all('tasks');
      reflections = await db.all('reflections', 'date ASC');
    } else {
      tasks = await db.all('SELECT * FROM tasks');
      reflections = await db.all('SELECT * FROM reflections ORDER BY date ASC');
    }

    const categoryStats = {};
    let totalScheduledMinutes = 0;
    let totalActualMinutes = 0;
    let completedCount = 0;
    const totalCount = tasks.length;

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

    const overallTaskAdherence = totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;

    const focusTrend = reflections.map(r => ({ date: r.date, score: r.focus_score }));
    const energyTrend = reflections.map(r => ({ date: r.date, score: r.energy_score }));
    const adherenceTrend = reflections.map(r => ({ date: r.date, score: r.adherence_score }));

    const suggestions = [];

    if (adherenceTrend.length > 0) {
      const avgAdherence = adherenceTrend.reduce((acc, curr) => acc + curr.score, 0) / adherenceTrend.length;
      if (avgAdherence < 70) {
        suggestions.push({ type: 'warning', title: 'Schedule Overload Detected', text: `Your average daily plan adherence is only ${Math.round(avgAdherence)}%. You may be scheduling too many back-to-back blocks.` });
      }
    }

    Object.keys(categoryStats).forEach(cat => {
      const stats = categoryStats[cat];
      const completionRate = (stats.completedCount / stats.tasksCount) * 100;
      if (completionRate < 60 && stats.tasksCount >= 2) {
        suggestions.push({ type: 'danger', title: `Slipping in ${cat.toUpperCase()}`, text: `You have completed only ${Math.round(completionRate)}% of your scheduled "${cat}" tasks. Consider rescheduling them.` });
      }
    });

    if (reflections.length >= 3) {
      const lowEnergyDays = reflections.filter(r => r.energy_score <= 5);
      const highEnergyDays = reflections.filter(r => r.energy_score >= 8);
      const avgFocusLowEnergy = lowEnergyDays.length > 0 ? lowEnergyDays.reduce((acc, curr) => acc + curr.focus_score, 0) / lowEnergyDays.length : 0;
      const avgFocusHighEnergy = highEnergyDays.length > 0 ? highEnergyDays.reduce((acc, curr) => acc + curr.focus_score, 0) / highEnergyDays.length : 0;
      if (avgFocusHighEnergy - avgFocusLowEnergy > 2) {
        suggestions.push({ type: 'success', title: 'Energy Drives Focus', text: `On high energy days, your focus scores averaged ${Math.round(avgFocusHighEnergy * 10) / 10}, significantly higher than low energy days (${Math.round(avgFocusLowEnergy * 10) / 10}).` });
      }
    }

    if (suggestions.length === 0) {
      suggestions.push({ type: 'success', title: 'Maintaining Excellent Flow', text: 'Fantastic! Your planned schedules and completed reflections show high consistency.' });
    }

    res.json({ summary: { totalTasks: totalCount, completedTasks: completedCount, completionRate: overallTaskAdherence, scheduledMinutes: totalScheduledMinutes, actualMinutes: totalActualMinutes }, categoryStats, trends: { focusTrend, energyTrend, adherenceTrend }, suggestions });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// MIGRATE LOCAL DATA TO SUPABASE
// ==========================================

app.post('/api/migrate', async (req, res) => {
  if (!USE_SUPABASE) return res.status(400).json({ error: 'Supabase not configured' });
  try {
    const sqlite3 = require('sqlite3');
    const lite = new sqlite3.Database(path.join(__dirname, '..', 'tracker.db'), sqlite3.OPEN_READONLY);

    async function migrateTable(table, columns) {
      const rows = await new Promise((resolve, reject) => {
        lite.all(`SELECT * FROM ${table}`, (err, rows) => {
          if (err) reject(err); else resolve(rows);
        });
      });
      let count = 0;
      for (const row of rows) {
        const payload = {};
        columns.forEach(col => { payload[col] = row[col]; });
        if (payload.completed !== undefined) payload.completed = !!payload.completed;
        if (payload.alarm_enabled !== undefined) payload.alarm_enabled = !!payload.alarm_enabled;
        if (payload.milestone_id === null) payload.milestone_id = null;
        delete payload.id;
        const { error } = await supabase.from(table).insert(payload);
        if (error) {
          console.warn(`  ${table} row ${row.id}: ${error.message}`);
        } else {
          count++;
        }
      }
      return count;
    }

    const taskCols = ['title', 'category', 'day_of_week', 'start_time', 'end_time', 'milestone_id', 'alarm_enabled', 'actual_minutes_spent', 'completed', 'created_at'];
    const projectCols = ['title', 'description', 'status', 'created_at'];
    const milestoneCols = ['project_id', 'title', 'due_date', 'completed', 'created_at'];
    const reflectionCols = ['date', 'adherence_score', 'focus_score', 'energy_score', 'notes_success', 'notes_struggles', 'notes_improvements', 'created_at'];

    const tasksCount = await migrateTable('tasks', taskCols);
    const projectsCount = await migrateTable('projects', projectCols);
    const milestonesCount = await migrateTable('milestones', milestoneCols);
    const reflectionsCount = await migrateTable('reflections', reflectionCols);

    lite.close();
    res.json({ message: 'Migration complete', counts: { tasks: tasksCount, projects: projectsCount, milestones: milestonesCount, reflections: reflectionsCount } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// NORMALIZE TASK (Supabase booleans → 0/1 for frontend)
// ==========================================

function normalizeTask(t) {
  if (!t) return t;
  return { ...t, completed: t.completed ? 1 : 0, alarm_enabled: t.alarm_enabled ? 1 : 0 };
}

// ==========================================
// START SERVER
// ==========================================

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Aether API Server running on port ${PORT}`);
});
