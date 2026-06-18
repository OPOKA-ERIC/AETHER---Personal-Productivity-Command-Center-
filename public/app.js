/* ==========================================================================
   AETHER - CUSTOM CLIENT APP ENGINE & DYNAMIC LOGIC
   ========================================================================== */

// App State Management
const STATE = {
  tasks: [],
  projects: [],
  reflections: [],
  activeView: 'dashboard',
  isAlarmMuted: false,
  activeTimer: null,
  coachingData: null,
  taskTimers: {},
  token: null,
  user: null
};

// Web Audio API Ambient Synthesizer
let audioCtx = null;
function playAlarmChime() {
  if (STATE.isAlarmMuted) return;
  
  try {
    // Initialize Audio Context on demand (user interaction safety)
    if (!audioCtx) {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    
    if (audioCtx.state === 'suspended') {
      audioCtx.resume();
    }

    const now = audioCtx.currentTime;
    
    // 1. Root fundamental oscillator (warm sine wave)
    const osc1 = audioCtx.createOscillator();
    const gain1 = audioCtx.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(440, now); // A4 Note
    osc1.frequency.exponentialRampToValueAtTime(880, now + 0.15); // Slide up to A5
    osc1.frequency.setValueAtTime(880, now + 0.15);
    
    // 2. Harmonics oscillator (gentle triangle for warmth)
    const osc2 = audioCtx.createOscillator();
    const gain2 = audioCtx.createGain();
    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(1320, now); // Fifth harmonic

    // Decay Envelope
    gain1.gain.setValueAtTime(0.3, now);
    gain1.gain.exponentialRampToValueAtTime(0.001, now + 1.8);
    
    gain2.gain.setValueAtTime(0.08, now);
    gain2.gain.exponentialRampToValueAtTime(0.001, now + 1.2);

    // Filter node to make sound silky and retro-modern
    const filter = audioCtx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(1200, now);
    filter.frequency.exponentialRampToValueAtTime(200, now + 1.5);

    // Connect nodes
    osc1.connect(gain1);
    osc2.connect(gain2);
    gain1.connect(filter);
    gain2.connect(filter);
    filter.connect(audioCtx.destination);

    // Trigger Playback
    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 1.8);
    osc2.stop(now + 1.8);

  } catch (err) {
    console.warn('Web Audio synthesis is blocked or unsupported:', err);
  }
}

function apiHeaders() {
  const h = { 'Content-Type': 'application/json' };
  if (STATE.token) h['Authorization'] = 'Bearer ' + STATE.token;
  return h;
}

function apiFetch(url, opts = {}) {
  return fetch(url, { ...opts, headers: { ...apiHeaders(), ...opts.headers } }).then(r => r.json());
}

const API = {
  fetchTasks: () => apiFetch('/api/tasks'),
  saveTask: (d) => apiFetch('/api/tasks', { method: 'POST', body: JSON.stringify(d) }),
  updateTask: (id, d) => apiFetch(`/api/tasks/${id}`, { method: 'PUT', body: JSON.stringify(d) }),
  deleteTask: (id) => apiFetch(`/api/tasks/${id}`, { method: 'DELETE' }),
  fetchProjects: () => apiFetch('/api/projects'),
  saveProject: (d) => apiFetch('/api/projects', { method: 'POST', body: JSON.stringify(d) }),
  deleteProject: (id) => apiFetch(`/api/projects/${id}`, { method: 'DELETE' }),
  saveMilestone: (pid, d) => apiFetch(`/api/projects/${pid}/milestones`, { method: 'POST', body: JSON.stringify(d) }),
  updateMilestone: (id, d) => apiFetch(`/api/milestones/${id}`, { method: 'PUT', body: JSON.stringify(d) }),
  deleteMilestone: (id) => apiFetch(`/api/milestones/${id}`, { method: 'DELETE' }),
  fetchReflections: () => apiFetch('/api/reflections'),
  saveReflection: (d) => apiFetch('/api/reflections', { method: 'POST', body: JSON.stringify(d) }),
  fetchAnalytics: () => apiFetch('/api/analytics')
};

// ==========================================
// NAVIGATION & SPA ROUTER
// ==========================================
function navigateToView(viewId) {
  STATE.activeView = viewId;

  // Close mobile sidebar on navigation
  document.querySelector('.sidebar')?.classList.remove('mobile-open');
  document.querySelector('.sidebar-overlay')?.classList.remove('active');
  
  // Update Navbar highlights
  document.querySelectorAll('.nav-item').forEach(item => {
    if (item.getAttribute('data-view') === viewId) {
      item.classList.add('active');
    } else {
      item.classList.remove('active');
    }
  });

  // Toggle View Panels
  document.querySelectorAll('.content-view').forEach(view => {
    if (view.id === `view-${viewId}`) {
      view.classList.add('active');
    } else {
      view.classList.remove('active');
    }
  });

  // Dynamic Page Header Metadata
  const titles = {
    dashboard: { title: 'Command Center', subtitle: 'Overview of your day, active timelines, and smart coach advice.' },
    planner: { title: 'Weekly Planner', subtitle: 'Block out your study time and schedule active audio alerts.' },
    projects: { title: 'Project Hub', subtitle: 'Organize long-term goals and map milestones into weekly plans.' },
    reflection: { title: 'Daily Reflection', subtitle: 'Commit subjective focus ratings and journal your daily progress.' },
    analytics: { title: 'Performance Analytics', subtitle: 'Intelligent habit coaching recommendations and adherence charts.' },
    reports: { title: 'Progress Reports', subtitle: 'Generate weekly, monthly, quarterly, and yearly productivity reports.' }
  };

  if (titles[viewId]) {
    document.getElementById('view-title').textContent = titles[viewId].title;
    document.getElementById('view-subtitle').textContent = titles[viewId].subtitle;
  }

  // Refresh Specific View Content
  refreshViewData(viewId);
}

// Coordinate view loading routines
async function refreshViewData(viewId) {
  try {
    if (viewId === 'dashboard') {
      STATE.tasks = await API.fetchTasks();
      STATE.coachingData = await API.fetchAnalytics();
      renderDashboard();
    } else if (viewId === 'planner') {
      STATE.tasks = await API.fetchTasks();
      STATE.projects = await API.fetchProjects();
      STATE.reflections = await API.fetchReflections();
      renderWeeklyPlanner();
      renderCalendar();
    } else if (viewId === 'projects') {
      STATE.projects = await API.fetchProjects();
      renderProjectHub();
    } else if (viewId === 'reflection') {
      STATE.reflections = await API.fetchReflections();
      renderReflectionLogs();
    } else if (viewId === 'analytics') {
      STATE.coachingData = await API.fetchAnalytics();
      renderAnalyticsPortal();
    }
  } catch (err) {
    console.error('Error refreshing view data:', err);
  }
}

// ==========================================
// RENDER: DASHBOARD VIEW
// ==========================================
function renderDashboard() {
  const todayName = getCurrentDayOfWeek();
  document.getElementById('today-day-badge').textContent = todayName;

  // 1. Render Hero statistics
  if (STATE.coachingData && STATE.coachingData.summary) {
    document.getElementById('hero-completion-rate').textContent = `${STATE.coachingData.summary.completionRate}%`;
    const hours = Math.round((STATE.coachingData.summary.actualMinutes / 60) * 10) / 10;
    document.getElementById('hero-minutes-spent').textContent = `${hours}h`;
  }

  // 2. Render Today's timeline slots
  const todayTasks = STATE.tasks.filter(t => t.day_of_week === todayName)
                                 .sort((a, b) => a.start_time.localeCompare(b.start_time));
  
  const listContainer = document.getElementById('today-timeline-list');
  const emptyState = document.getElementById('dashboard-empty-schedule');

  listContainer.innerHTML = '';
  
  if (todayTasks.length === 0) {
    emptyState.classList.remove('hidden');
  } else {
    emptyState.classList.add('hidden');

    todayTasks.forEach(task => {
      const activeClass = isTaskCurrentlyActive(task) ? 'active' : '';
      const completedClass = task.completed ? 'completed' : '';
      const timer = STATE.taskTimers[task.id];
      const isRunning = timer && !timer.paused;
      const isPaused = timer && timer.paused;
      const elapsedMins = task.actual_minutes_spent || 0;

      const itemHTML = `
        <div class="timeline-item ${activeClass} ${completedClass}" id="tl-item-${task.id}">
          <div class="timeline-time">${task.start_time}</div>
          <div class="timeline-track"><div class="timeline-node"></div></div>
          <div class="timeline-card cat-${task.category} ${completedClass}" data-task-id="${task.id}" onclick="openEditTaskModal(this.dataset.taskId)">
            <div class="timeline-card-left">
              <span class="timeline-card-title">${task.title}</span>
              <div class="timeline-card-meta">
                <span class="timeline-category-tag">${task.category}</span>
                <span><i class="fa-regular fa-clock"></i> ${task.start_time} – ${task.end_time}</span>
                <span class="task-elapsed-display" id="elapsed-${task.id}">
                  <i class="fa-solid fa-stopwatch"></i>
                  <span id="elapsed-text-${task.id}">${formatElapsed(elapsedMins * 60)}</span>
                </span>
              </div>
            </div>
            ${task.completed ? `
              <div class="task-done-badge"><i class="fa-solid fa-circle-check"></i> Done</div>
            ` : `
              <div class="task-timer-controls" onclick="event.stopPropagation()">
                ${!isRunning && !isPaused ? `
                  <button class="ttc-btn ttc-start" data-task-id="${task.id}" onclick="taskTimerStart(this.dataset.taskId)" title="Start">
                    <i class="fa-solid fa-play"></i>
                  </button>
                ` : ''}
                ${isRunning ? `
                  <button class="ttc-btn ttc-pause" data-task-id="${task.id}" onclick="taskTimerPause(this.dataset.taskId)" title="Pause">
                    <i class="fa-solid fa-pause"></i>
                  </button>
                ` : ''}
                ${isPaused ? `
                  <button class="ttc-btn ttc-resume" data-task-id="${task.id}" onclick="taskTimerResume(this.dataset.taskId)" title="Resume">
                    <i class="fa-solid fa-play"></i> <span style="font-size:0.65rem;">Resume</span>
                  </button>
                ` : ''}
                <button class="ttc-btn ttc-done" data-task-id="${task.id}" data-completed="${task.completed}" onclick="taskTimerDone(this.dataset.taskId)" title="Mark Done">
                  <i class="fa-solid fa-check"></i>
                </button>
              </div>
            `}
          </div>
        </div>
      `;
      listContainer.insertAdjacentHTML('beforeend', itemHTML);
    });
  }

  // 3. Render Smart Habits Coach suggestions
  renderCoachInsights();
}

function renderCoachInsights() {
  const coachContainer = document.getElementById('coach-insight-container');
  if (!coachContainer) return;
  coachContainer.innerHTML = '';

  if (STATE.coachingData && STATE.coachingData.suggestions && STATE.coachingData.suggestions.length > 0) {
    STATE.coachingData.suggestions.slice(0, 2).forEach(tip => {
      const cardType = tip.type;
      const icon = cardType === 'success' ? 'fa-circle-check' : cardType === 'warning' ? 'fa-triangle-exclamation' : 'fa-circle-exclamation';
      coachContainer.insertAdjacentHTML('beforeend', `
        <div class="coach-tip ${cardType}">
          <div class="tip-icon"><i class="fa-solid ${icon}"></i></div>
          <div class="tip-content"><h4>${tip.title}</h4><p>${tip.text}</p></div>
        </div>`);
    });
  } else {
    coachContainer.innerHTML = `
      <div class="coach-tip success">
        <div class="tip-icon"><i class="fa-solid fa-circle-check"></i></div>
        <div class="tip-content"><h4>Doing Amazing!</h4><p>You have hit all scheduled goals. Seal the plan on Sunday to carry this velocity forward.</p></div>
      </div>`;
  }
}

// ==========================================
// RENDER: WEEKLY PLANNER VIEW
// ==========================================
function getWeekOfMonth(date) {
  const firstDay = new Date(date.getFullYear(), date.getMonth(), 1).getDay();
  return Math.ceil((date.getDate() + firstDay) / 7);
}

function renderWeeklyPlanner() {
  // Week banner
  const now = new Date();
  const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  const weekNum = getWeekOfMonth(now);
  document.getElementById('week-label').textContent = `Week ${weekNum} of ${months[now.getMonth()]} ${now.getFullYear()}`;

  // Calculate Mon-Sun dates of the current week
  const day = now.getDay(); // 0=Sun
  const diffToMon = (day === 0) ? -6 : 1 - day;
  const monday = new Date(now); monday.setDate(now.getDate() + diffToMon);
  const sunday = new Date(monday); sunday.setDate(monday.getDate() + 6);
  const fmt = (d) => `${d.getDate()} ${months[d.getMonth()].slice(0,3)}`;
  document.getElementById('week-dates').textContent = `${fmt(monday)} – ${fmt(sunday)}`;

  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  days.forEach(day => {
    const list = document.getElementById(`list-${day}`);
    list.innerHTML = '';
    
    const dayTasks = STATE.tasks.filter(t => t.day_of_week === day)
                                 .sort((a, b) => a.start_time.localeCompare(b.start_time));
    
    // Update count indicator badge
    const header = list.parentElement.querySelector('.day-task-count');
    header.textContent = dayTasks.length;

    dayTasks.forEach(task => {
      const completedClass = task.completed ? 'completed' : '';
      
      const taskHTML = `
        <div class="planner-time-block cat-${task.category} ${completedClass}" data-task-id="${task.id}" onclick="openEditTaskModal(this.dataset.taskId)">
          <div class="block-title" title="${task.title}">${task.title}</div>
          <div class="block-time">${task.start_time} - ${task.end_time}</div>
          <div class="block-meta">
            <span class="block-cat">${task.category}</span>
            <div class="block-icons">
              ${task.alarm_enabled ? '<i class="fa-solid fa-bell"></i>' : ''}
              ${task.milestone_id ? '<i class="fa-solid fa-diagram-project"></i>' : ''}
              ${task.completed ? '<i class="fa-solid fa-circle-check text-emerald"></i>' : ''}
            </div>
          </div>
        </div>
      `;
      list.insertAdjacentHTML('beforeend', taskHTML);
    });
  });
}

// ==========================================
// HISTORY CALENDAR
// ==========================================
let calendarDate = new Date();

function renderCalendar() {
  const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  const year = calendarDate.getFullYear();
  const month = calendarDate.getMonth();

  document.getElementById('cal-month-label').textContent = `${months[month]} ${year}`;

  const firstDay = new Date(year, month, 1).getDay(); // 0=Sun
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const today = new Date();

  // Build a map of dates that have reflections
  const reflectionDates = new Set(STATE.reflections.map(r => r.date));

  // Build a map of dates that have tasks (by created_at date)
  const taskDates = new Set(
    STATE.tasks
      .filter(t => t.created_at)
      .map(t => t.created_at.slice(0, 10))
  );

  const grid = document.getElementById('calendar-grid');
  grid.innerHTML = '';

  // Day headers Mon-Sun
  ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].forEach(d => {
    const h = document.createElement('div');
    h.className = 'cal-header-cell';
    h.textContent = d;
    grid.appendChild(h);
  });

  // Offset: convert Sun=0 to Mon=0 offset
  const offset = (firstDay === 0) ? 6 : firstDay - 1;
  for (let i = 0; i < offset; i++) {
    const blank = document.createElement('div');
    blank.className = 'cal-cell cal-blank';
    grid.appendChild(blank);
  }

  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = `${year}-${String(month+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
    const cell = document.createElement('div');
    cell.className = 'cal-cell';

    const isToday = (d === today.getDate() && month === today.getMonth() && year === today.getFullYear());
    if (isToday) cell.classList.add('cal-today');

    const hasReflection = reflectionDates.has(dateStr);
    const hasTasks = taskDates.has(dateStr);

    cell.innerHTML = `
      <span class="cal-day-num">${d}</span>
      <div class="cal-dot-row">
        ${hasReflection ? '<span class="cal-dot dot-reflection" title="Reflection logged"></span>' : ''}
        ${hasTasks ? '<span class="cal-dot dot-tasks" title="Tasks created"></span>' : ''}
      </div>
    `;

    if (hasReflection || hasTasks) {
      cell.classList.add('cal-has-data');
      cell.addEventListener('click', () => openDayDetail(dateStr));
    }

    grid.appendChild(cell);
  }
}

function openDayDetail(dateStr) {
  const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  const [y, m, d] = dateStr.split('-');
  document.getElementById('day-detail-title').textContent =
    `${months[parseInt(m)-1]} ${parseInt(d)}, ${y}`;

  // Reflection banner
  const ref = STATE.reflections.find(r => r.date === dateStr);
  const refBanner = document.getElementById('day-detail-reflection');
  if (ref) {
    refBanner.classList.remove('hidden');
    refBanner.innerHTML = `
      <div class="day-ref-scores">
        <div class="day-ref-score"><span class="text-muted">Adherence</span><strong class="text-emerald">${ref.adherence_score}%</strong></div>
        <div class="day-ref-score"><span class="text-muted">Focus</span><strong class="text-purple">${ref.focus_score}/10</strong></div>
        <div class="day-ref-score"><span class="text-muted">Energy</span><strong class="text-cyan">${ref.energy_score}/10</strong></div>
      </div>
      <div class="day-ref-notes">
        <div><label><i class="fa-solid fa-trophy text-emerald"></i> Wins</label><p>${ref.notes_success || '—'}</p></div>
        <div><label><i class="fa-solid fa-triangle-exclamation text-rose"></i> Struggles</label><p>${ref.notes_struggles || '—'}</p></div>
        <div><label><i class="fa-solid fa-lightbulb text-purple"></i> Improvements</label><p>${ref.notes_improvements || '—'}</p></div>
      </div>
    `;
  } else {
    refBanner.classList.add('hidden');
  }

  // Tasks for the day-of-week matching this date
  const dayOfWeek = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][new Date(dateStr + 'T12:00:00').getDay()];
  const dayTasks = STATE.tasks.filter(t => t.day_of_week === dayOfWeek);
  const tasksContainer = document.getElementById('day-detail-tasks');

  if (dayTasks.length === 0 && !ref) {
    tasksContainer.innerHTML = `<p class="text-muted text-center" style="padding: 2rem 0;">No tasks or reflection found for this date.</p>`;
  } else if (dayTasks.length === 0) {
    tasksContainer.innerHTML = `<p class="text-muted" style="margin-top:1rem;">No scheduled blocks for ${dayOfWeek}.</p>`;
  } else {
    tasksContainer.innerHTML = `
      <h4 style="margin: 1.25rem 0 0.75rem; font-size:0.9rem; color: var(--text-muted); text-transform:uppercase; letter-spacing:0.05em;">${dayOfWeek} Schedule</h4>
      <div class="day-detail-task-list">
        ${dayTasks.sort((a,b) => a.start_time.localeCompare(b.start_time)).map(t => `
          <div class="day-detail-task-row ${t.completed ? 'completed' : ''}">
            <span class="ddt-time">${t.start_time} – ${t.end_time}</span>
            <span class="ddt-cat cat-dot-${t.category}"></span>
            <span class="ddt-title ${t.completed ? 'strikethrough' : ''}">${t.title}</span>
            <span class="ddt-badge">${t.category}</span>
            ${t.completed ? '<i class="fa-solid fa-circle-check text-emerald"></i>' : '<i class="fa-regular fa-circle text-muted"></i>'}
          </div>`).join('')}
      </div>
    `;
  }

  openModal('day-detail-modal');
}

// ==========================================
// RENDER: PROJECT HUB VIEW
// ==========================================
function renderProjectHub() {
  const container = document.getElementById('projects-list-container');
  container.innerHTML = '';

  if (STATE.projects.length === 0) {
    container.innerHTML = `
      <div class="grid-card text-center py-5 flex-center flex-direction-column w-100" style="grid-column: 1 / -1; min-height: 250px;">
        <i class="fa-solid fa-diagram-project fa-3x text-muted mb-3"></i>
        <h3>No active long-term projects</h3>
        <p class="text-muted mt-2 mb-4">Break your learning goals into distinct progress milestones.</p>
        <button class="btn btn-primary" onclick="openModal('project-modal')">Create Your First Project</button>
      </div>
    `;
    return;
  }

  STATE.projects.forEach(p => {
    // Calculate progress percentage
    const total = p.milestones.length;
    const completed = p.milestones.filter(m => m.completed).length;
    const percent = total > 0 ? Math.round((completed / total) * 100) : 0;

    let milestonesHTML = '';
    p.milestones.forEach(m => {
      const checkClass = m.completed ? 'fa-regular fa-square-check' : 'fa-regular fa-square';
      const itemCompletedClass = m.completed ? 'completed' : '';
      
      milestonesHTML += `
        <div class="milestone-item ${itemCompletedClass}">
          <i class="${checkClass} milestone-check" data-milestone-id="${m.id}" data-completed="${m.completed}" onclick="toggleMilestoneCompletion(this.dataset.milestoneId, this.dataset.completed == 'true')"></i>
          <span class="milestone-text">${m.title}</span>
          ${m.due_date ? `<span class="milestone-due">${m.due_date}</span>` : ''}
          <button class="milestone-delete" data-milestone-id="${m.id}" onclick="deleteMilestone(this.dataset.milestoneId)" title="Delete Milestone"><i class="fa-regular fa-trash-can"></i></button>
        </div>
      `;
    });

    const cardHTML = `
      <div class="project-card">
        <div class="project-card-header">
          <div class="project-card-title">
            <h3>${p.title}</h3>
            <span class="badge badge-indigo">${p.status || 'active'}</span>
          </div>
          <button class="project-delete-btn" data-project-id="${p.id}" onclick="deleteProject(this.dataset.projectId)" title="Delete Project"><i class="fa-regular fa-trash-can"></i></button>
        </div>
        
        <p class="project-desc">${p.description || 'No objectives stated.'}</p>
        
        <!-- Project Progress Bar -->
        <div class="project-progress-container">
          <div class="progress-bar-label">
            <span>Milestones Achieved</span>
            <span>${percent}% (${completed}/${total})</span>
          </div>
          <div class="progress-bar-track">
            <div class="progress-bar-fill" style="width: ${percent}%;"></div>
          </div>
        </div>

        <!-- Milestones list -->
        <div class="project-milestones-sublist">
          ${milestonesHTML}
          <button class="add-milestone-btn-inline" data-project-id="${p.id}" onclick="openAddMilestoneModal(this.dataset.projectId)">
            <i class="fa-solid fa-plus-circle"></i> Add Milestone Target
          </button>
        </div>
      </div>
    `;
    container.insertAdjacentHTML('beforeend', cardHTML);
  });
}

// ==========================================
// RENDER: DAILY REFLECTION HISTORY LOGS
// ==========================================
function renderReflectionLogs() {
  const tbody = document.getElementById('reflections-table-body');
  tbody.innerHTML = '';

  // Pre-fill today's date picker if empty
  const picker = document.getElementById('reflection-date');
  if (!picker.value) {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    picker.value = `${yyyy}-${mm}-${dd}`;
  }

  if (STATE.reflections.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-muted">No daily logs recorded yet. Reflect tonight!</td></tr>`;
    return;
  }

  STATE.reflections.forEach(ref => {
    const row = `
      <tr onclick="viewReflection('${ref.date}')" style="cursor: pointer;" class="hover-row">
        <td style="font-weight: 600; color: var(--text-bright);">${ref.date}</td>
        <td>
          <div class="flex-center" style="gap:0.4rem; justify-content: flex-start;">
            <div class="progress-bar-track" style="width: 50px; height: 4px;">
              <div class="progress-bar-fill" style="width: ${ref.adherence_score}%; height:100%; background: var(--grad-purple)"></div>
            </div>
            <span>${ref.adherence_score}%</span>
          </div>
        </td>
        <td><i class="fa-solid fa-brain text-purple"></i> ${ref.focus_score}/10</td>
        <td><i class="fa-solid fa-bolt text-rose"></i> ${ref.energy_score}/10</td>
        <td style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="${ref.notes_success}">${ref.notes_success}</td>
        <td style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="${ref.notes_struggles}">${ref.notes_struggles}</td>
      </tr>
    `;
    tbody.insertAdjacentHTML('beforeend', row);
  });
}

// ==========================================
// RENDER: PERFORMANCE ANALYTICS PORTAL
// ==========================================
function renderAnalyticsPortal() {
  if (!STATE.coachingData) return;

  const data = STATE.coachingData;

  // 1. Populate KPI Header Banner
  const completed = data.summary.completedTasks;
  const total = data.summary.totalTasks;
  const timeSpentHours = Math.floor(data.summary.actualMinutes / 60);
  const timeSpentMins = data.summary.actualMinutes % 60;

  document.getElementById('analytics-total-tasks').textContent = `${completed} / ${total}`;
  document.getElementById('analytics-completion-rate').textContent = `${data.summary.completionRate}%`;
  document.getElementById('analytics-time-spent').textContent = `${timeSpentHours}h ${timeSpentMins}m`;

  // 2. Render Category Progress bars
  const categoryContainer = document.getElementById('category-distribution-container');
  categoryContainer.innerHTML = '';

  const stats = data.categoryStats;
  const categories = Object.keys(stats);

  if (categories.length === 0) {
    categoryContainer.innerHTML = `<p class="text-muted text-center py-4">No categories active in your planner schedules.</p>`;
  } else {
    // Find maximum scheduled hours to make bar lengths relative
    let maxMinutes = 0;
    categories.forEach(cat => {
      if (stats[cat].scheduled > maxMinutes) maxMinutes = stats[cat].scheduled;
    });

    categories.forEach(cat => {
      const item = stats[cat];
      const schedHr = Math.round((item.scheduled / 60) * 10) / 10;
      const actHr = Math.round((item.actual / 60) * 10) / 10;
      const widthPercent = maxMinutes > 0 ? (item.scheduled / maxMinutes) * 100 : 0;

      const barHTML = `
        <div class="category-progress-item">
          <div class="category-progress-meta">
            <span class="category-progress-name">${cat}</span>
            <span class="category-progress-time">${actHr}h done / ${schedHr}h scheduled</span>
          </div>
          <div class="category-progress-track">
            <div class="category-progress-fill cat-${cat}" style="width: ${widthPercent}%;"></div>
          </div>
        </div>
      `;
      categoryContainer.insertAdjacentHTML('beforeend', barHTML);
    });
  }

  // 3. Render dynamic Vector canvas line charts
  drawCanvasTrends(data.trends);
}

// Draw custom high-fidelity analytics chart using pure HTML5 Canvas API
function drawCanvasTrends(trends) {
  const canvas = document.getElementById('trendsChart');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  
  // Set dimensions for high-DPI crispness
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);

  const width = rect.width;
  const height = rect.height;

  // Clear Canvas
  ctx.clearRect(0, 0, width, height);

  // Setup Margins
  const paddingLeft = 40;
  const paddingRight = 20;
  const paddingTop = 30;
  const paddingBottom = 40;
  const chartWidth = width - paddingLeft - paddingRight;
  const chartHeight = height - paddingTop - paddingBottom;

  // Grab data records (max 7 points for visual spacing)
  const records = trends.adherenceTrend.slice(-7); 
  const totalPoints = records.length;

  if (totalPoints < 2) {
    // Draw placeholder empty state
    ctx.font = '500 13px Outfit';
    ctx.fillStyle = '#9c97b8';
    ctx.textAlign = 'center';
    ctx.fillText('Log at least 2 daily reflections to view performance charts.', width / 2, height / 2);
    return;
  }

  // Draw Gridlines & Y-Axis Scale
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
  ctx.lineWidth = 1;
  ctx.font = '400 10px monospace';
  ctx.fillStyle = '#9c97b8';
  ctx.textAlign = 'right';

  const yLines = 5; // 0, 25, 50, 75, 100
  for (let i = 0; i <= yLines; i++) {
    const yVal = Math.round((100 / yLines) * i);
    const yPos = paddingTop + chartHeight - (chartHeight * (yVal / 100));

    // Gridline
    ctx.beginPath();
    ctx.moveTo(paddingLeft, yPos);
    ctx.lineTo(width - paddingRight, yPos);
    ctx.stroke();

    // Label
    ctx.fillText(`${yVal}%`, paddingLeft - 8, yPos + 3);
  }

  // Draw X-Axis Dates
  ctx.textAlign = 'center';
  const xSpacing = chartWidth / (totalPoints - 1);
  
  records.forEach((rec, idx) => {
    const xPos = paddingLeft + (idx * xSpacing);
    // Simple short date e.g. "May 28"
    const [year, month, day] = rec.date.split('-');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const shortDate = `${months[parseInt(month) - 1]} ${day}`;

    ctx.fillText(shortDate, xPos, height - paddingBottom + 18);
  });

  // HELPER ROUTINE: Draw elegant glowing line path
  function drawMetricLine(dataArray, color, gradientColor, scaleVal = 1) {
    ctx.beginPath();
    ctx.lineWidth = 3;
    ctx.strokeStyle = color;
    
    // Draw line
    dataArray.forEach((val, idx) => {
      const rawVal = val.score;
      // convert 1-10 scores to percentage weights if necessary
      const scorePercent = scaleVal === 10 ? (rawVal * 10) : rawVal;
      
      const x = paddingLeft + (idx * xSpacing);
      const y = paddingTop + chartHeight - (chartHeight * (scorePercent / 100));

      if (idx === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();

    // Create glowing area under line
    const areaGlow = ctx.createLinearGradient(0, paddingTop, 0, height - paddingBottom);
    areaGlow.addColorStop(0, gradientColor);
    areaGlow.addColorStop(1, 'rgba(7, 5, 15, 0)');
    
    ctx.lineTo(paddingLeft + ((totalPoints - 1) * xSpacing), height - paddingBottom);
    ctx.lineTo(paddingLeft, height - paddingBottom);
    ctx.closePath();
    ctx.fillStyle = areaGlow;
    ctx.fill();

    // Add glowing coordinate dots
    dataArray.forEach((val, idx) => {
      const rawVal = val.score;
      const scorePercent = scaleVal === 10 ? (rawVal * 10) : rawVal;
      const x = paddingLeft + (idx * xSpacing);
      const y = paddingTop + chartHeight - (chartHeight * (scorePercent / 100));

      ctx.beginPath();
      ctx.arc(x, y, 4, 0, 2 * Math.PI);
      ctx.fillStyle = color;
      ctx.fill();
      ctx.strokeStyle = '#07050e';
      ctx.lineWidth = 1.5;
      ctx.stroke();
    });
  }

  // Plot Focus scores (Scale 1-10) -> convert to purple glow
  const focusData = trends.focusTrend.slice(-7);
  drawMetricLine(focusData, '#8b5cf6', 'rgba(139, 92, 246, 0.15)', 10);

  // Plot Energy scores (Scale 1-10) -> convert to cyan glow
  const energyData = trends.energyTrend.slice(-7);
  drawMetricLine(energyData, '#06b6d4', 'rgba(6, 182, 212, 0.15)', 10);

  // Plot Adherence rates (Scale 0-100%) -> convert to white/emerald glow
  const adherenceData = trends.adherenceTrend.slice(-7);
  drawMetricLine(adherenceData, '#10b981', 'rgba(16, 185, 129, 0.1)', 1);

  // Draw Legend markers on top right
  ctx.font = '500 10px Outfit';
  ctx.textAlign = 'left';

  const legendItems = [
    { name: 'Plan Adherence', color: '#10b981' },
    { name: 'Focus Rating', color: '#8b5cf6' },
    { name: 'Energy Level', color: '#06b6d4' }
  ];

  legendItems.forEach((item, idx) => {
    const x = paddingLeft + 10 + (idx * 115);
    const y = paddingTop - 12;

    ctx.fillStyle = item.color;
    ctx.beginPath();
    ctx.arc(x, y - 3, 4, 0, 2 * Math.PI);
    ctx.fill();

    ctx.fillStyle = '#f3f1f8';
    ctx.fillText(item.name, x + 8, y);
  });
}

// ==========================================
// ACTIVE TIMER & ALARM ENGINE
// ==========================================
let lastCheckedHourMin = '';

function startGlobalSystemTick() {
  setInterval(() => {
    // 1. Update Top Clock Display
    const now = new Date();
    const timeString = now.toTimeString().split(' ')[0];
    document.getElementById('current-time').textContent = timeString;

    // 2. Perform schedule scanning every minute
    const currentHourMin = timeString.slice(0, 5); // HH:MM
    if (currentHourMin !== lastCheckedHourMin) {
      lastCheckedHourMin = currentHourMin;
      scanScheduleForAlarms(currentHourMin);
    }
  }, 1000);
}

// Scan schedule and matching alarm alerts
function scanScheduleForAlarms(currentHHMM) {
  const currentDay = getCurrentDayOfWeek();

  STATE.tasks.forEach(task => {
    if (task.day_of_week === currentDay && task.alarm_enabled && !task.completed) {
      // Start of Timeblock check
      if (task.start_time === currentHHMM) {
        triggerActiveAlarm(task, 'Focus Block Started', `${task.title} starts now!`);
        startFocusCountdown(task);
      }
      
      // End of Timeblock check
      if (task.end_time === currentHHMM) {
        triggerActiveAlarm(task, 'Focus Block Concluded', `${task.title} is now finished. Commit actual minutes spent!`);
        clearFocusCountdown();
      }
    }
  });
}

// Trigger persistent visible and audible alarm
function triggerActiveAlarm(task, titleText, bodyText) {
  // Play native chimes
  playAlarmChime();

  // Slide open toast modal
  const toast = document.getElementById('alarm-toast');
  document.getElementById('toast-title').textContent = titleText;
  document.getElementById('toast-body').textContent = bodyText;
  toast.classList.remove('hidden');

  // Dismiss event
  document.getElementById('dismiss-toast-btn').onclick = () => {
    toast.classList.add('hidden');
  };
}

// Trigger floating timer pill countdown
function startFocusCountdown(task) {
  clearFocusCountdown();

  const pill = document.getElementById('focus-timer-pill');
  const label = document.getElementById('focus-task-title');
  const timerText = document.getElementById('focus-countdown');
  const completeBtn = document.getElementById('complete-timer-btn');

  label.textContent = task.title;
  pill.classList.remove('hidden');

  // Parse target end time
  const [eh, em] = task.end_time.split(':').map(Number);
  
  function updateTimer() {
    const now = new Date();
    const end = new Date();
    end.setHours(eh, em, 0, 0);

    let diffMs = end - now;
    if (diffMs < 0) {
      // crossover midnight
      end.setDate(end.getDate() + 1);
      diffMs = end - now;
    }

    if (diffMs <= 0) {
      clearFocusCountdown();
      return;
    }

    const totalSecs = Math.floor(diffMs / 1000);
    const mins = String(Math.floor(totalSecs / 60)).padStart(2, '0');
    const secs = String(totalSecs % 60).padStart(2, '0');
    timerText.textContent = `${mins}:${secs}`;
  }

  updateTimer();
  const intervalId = setInterval(updateTimer, 1000);

  STATE.activeTimer = {
    taskId: task.id,
    intervalId
  };

  completeBtn.onclick = async () => {
    await toggleTaskCompletion(task.id, 0);
    clearFocusCountdown();
  };
}

function clearFocusCountdown() {
  if (STATE.activeTimer) {
    clearInterval(STATE.activeTimer.intervalId);
    STATE.activeTimer = null;
  }
  document.getElementById('focus-timer-pill').classList.add('hidden');
}

// ==========================================
// TASK TIMER ENGINE (Start / Pause / Resume / Done)
// ==========================================
let taskTickInterval = null;

function formatElapsed(totalSeconds) {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  if (h > 0) return `${h}h ${String(m).padStart(2,'0')}m`;
  return `${String(m).padStart(2,'0')}m ${String(s).padStart(2,'0')}s`;
}

function getTaskElapsedSeconds(taskId) {
  const timer = STATE.taskTimers[taskId];
  if (!timer) return 0;
  let ms = timer.accumulatedMs;
  if (!timer.paused && timer.startedAt) ms += Date.now() - timer.startedAt;
  return Math.floor(ms / 1000);
}

function startTaskTickLoop() {
  if (taskTickInterval) return;
  taskTickInterval = setInterval(() => {
    Object.keys(STATE.taskTimers).forEach(taskId => {
      const timer = STATE.taskTimers[taskId];
      if (!timer.paused) {
        const el = document.getElementById(`elapsed-text-${taskId}`);
        if (el) el.textContent = formatElapsed(getTaskElapsedSeconds(taskId));
        // pulse the elapsed display
        const display = document.getElementById(`elapsed-${taskId}`);
        if (display) display.classList.add('elapsed-running');
      }
    });
  }, 1000);
}

function taskTimerStart(taskId) {
  STATE.taskTimers[taskId] = { startedAt: Date.now(), accumulatedMs: 0, paused: false };
  startTaskTickLoop();
  renderDashboard();
}

function taskTimerPause(taskId) {
  const timer = STATE.taskTimers[taskId];
  if (!timer || timer.paused) return;
  timer.accumulatedMs += Date.now() - timer.startedAt;
  timer.paused = true;
  renderDashboard();
}

function taskTimerResume(taskId) {
  const timer = STATE.taskTimers[taskId];
  if (!timer || !timer.paused) return;
  timer.startedAt = Date.now();
  timer.paused = false;
  startTaskTickLoop();
  renderDashboard();
}

async function taskTimerDone(taskId) {
  const task = STATE.tasks.find(t => t.id === taskId);
  if (!task) return;

  // Calculate elapsed minutes from timer if running, else use existing
  let elapsedMins = task.actual_minutes_spent || 0;
  if (STATE.taskTimers[taskId]) {
    const secs = getTaskElapsedSeconds(taskId);
    elapsedMins = Math.max(1, Math.round(secs / 60));
    delete STATE.taskTimers[taskId];
  }

  // If no active timers remain, stop the tick loop
  if (Object.keys(STATE.taskTimers).length === 0 && taskTickInterval) {
    clearInterval(taskTickInterval);
    taskTickInterval = null;
  }

  await API.updateTask(taskId, { completed: true, actual_minutes_spent: elapsedMins });

  // Completion chime
  if (!STATE.isAlarmMuted) {
    try {
      if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const n = audioCtx.currentTime;
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(600, n);
      osc.frequency.exponentialRampToValueAtTime(1200, n + 0.15);
      gain.gain.setValueAtTime(0.1, n);
      gain.gain.exponentialRampToValueAtTime(0.001, n + 0.4);
      osc.connect(gain); gain.connect(audioCtx.destination);
      osc.start(); osc.stop(n + 0.4);
    } catch(e) {}
  }

  refreshViewData(STATE.activeView);
}

// ==========================================
// TASKS CRUD OPERATIONS
// ==========================================
async function toggleTaskCompletion(id, currentlyCompleted) {
  const newStatus = currentlyCompleted ? false : true;
  const task = STATE.tasks.find(t => t.id === id);
  if (!task) return;

  let actualMins = task.actual_minutes_spent;
  if (newStatus && !actualMins) {
    const [sh, sm] = task.start_time.split(':').map(Number);
    const [eh, em] = task.end_time.split(':').map(Number);
    let diff = (eh * 60 + em) - (sh * 60 + sm);
    if (diff < 0) diff += 24 * 60;
    actualMins = diff;
  }

  await API.updateTask(id, { completed: newStatus, actual_minutes_spent: actualMins });
  
  if (newStatus && !STATE.isAlarmMuted) {
    try {
      if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const n = audioCtx.currentTime;
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(600, n);
      osc.frequency.exponentialRampToValueAtTime(1200, n + 0.15);
      gain.gain.setValueAtTime(0.1, n);
      gain.gain.exponentialRampToValueAtTime(0.001, n + 0.25);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start();
      osc.stop(n + 0.25);
    } catch(e) {}
  }

  refreshViewData(STATE.activeView);
}

// Open Edit Task Dialog Modal
function openEditTaskModal(id) {
  const task = STATE.tasks.find(t => t.id === id);
  if (!task) return;

  document.getElementById('task-modal-title').textContent = 'Modify Time Block';
  document.getElementById('task-id').value = task.id;
  document.getElementById('task-title').value = task.title;
  document.getElementById('task-category').value = task.category;
  document.getElementById('task-day').value = task.day_of_week;
  document.getElementById('task-start').value = task.start_time;
  document.getElementById('task-end').value = task.end_time;
  document.getElementById('task-alarm').checked = !!task.alarm_enabled;
  document.getElementById('task-completed').checked = !!task.completed;
  document.getElementById('task-actual-time').value = task.actual_minutes_spent || '';

  // Show milestone link dropdown list
  populateMilestoneDropdown(task.milestone_id);

  // Show delete button and complete row during editing
  document.getElementById('delete-task-btn').classList.remove('hidden');
  document.getElementById('task-complete-row').classList.remove('hidden');

  openModal('task-modal');
}

// Populate project milestone linked selections
function populateMilestoneDropdown(selectedId = null) {
  const select = document.getElementById('task-milestone');
  select.innerHTML = '<option value="">None</option>';
  
  STATE.projects.forEach(p => {
    p.milestones.forEach(m => {
      const selectedAttr = m.id === selectedId ? 'selected' : '';
      const option = `<option value="${m.id}" ${selectedAttr}>${p.title} &rarr; ${m.title}</option>`;
      select.insertAdjacentHTML('beforeend', option);
    });
  });
}

// ==========================================
// UTILITY DATE METHODS
// ==========================================
function getCurrentDayOfWeek() {
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return days[new Date().getDay()];
}

function isTaskCurrentlyActive(task) {
  const now = new Date();
  const currentDay = getCurrentDayOfWeek();
  if (task.day_of_week !== currentDay) return false;

  const [sh, sm] = task.start_time.split(':').map(Number);
  const [eh, em] = task.end_time.split(':').map(Number);
  
  const start = new Date();
  start.setHours(sh, sm, 0, 0);

  const end = new Date();
  end.setHours(eh, em, 0, 0);
  if (end < start) end.setDate(end.getDate() + 1);

  return now >= start && now <= end;
}

function openModal(id) {
  document.getElementById(id).classList.add('active');
}

function closeModal(id) {
  document.getElementById(id).classList.remove('active');
}

function nextWizardStep(stepNum) {
  document.querySelectorAll('.wizard-step').forEach(step => step.classList.remove('active'));
  document.getElementById(`wizard-step-${stepNum}`).classList.add('active');
}

async function deleteProject(id) {
  if (confirm('Deleting a project cascades and deletes all related milestones! Proceed?')) {
    try {
      await API.deleteProject(id);
      refreshViewData(STATE.activeView);
    } catch (err) {
      alert('Error deleting project: ' + err.message);
    }
  }
}

function openAddMilestoneModal(projectId) {
  document.getElementById('milestone-form').reset();
  document.getElementById('milestone-project-id').value = projectId;
  openModal('milestone-modal');
}

async function toggleMilestoneCompletion(id, currentlyCompleted) {
  try {
    await API.updateMilestone(id, { completed: !currentlyCompleted });
    refreshViewData(STATE.activeView);
  } catch (err) {
    console.error('Error toggling milestone:', err);
  }
}

async function deleteMilestone(id) {
  if (confirm('Are you sure you want to delete this milestone?')) {
    try {
      await API.deleteMilestone(id);
      refreshViewData(STATE.activeView);
    } catch (err) {
      alert('Error deleting milestone: ' + err.message);
    }
  }
}

async function toggleWizardMilestone(element, milestoneId) {
  const cb = element.querySelector('input[type="checkbox"]');
  cb.checked = !cb.checked;
  await API.updateMilestone(milestoneId, { completed: cb.checked });
}

function setupSliderChangeEvents() {
  const adherence = document.getElementById('score-adherence');
  const focus = document.getElementById('score-focus');
  const energy = document.getElementById('score-energy');

  adherence.addEventListener('input', (e) => {
    document.getElementById('val-adherence').textContent = `${e.target.value}%`;
  });

  const focusTexts = { 10:'Laser focused, in the zone!', 20:'Very poor, constantly distracted.', 30:'Below average attention span.', 40:'Frequent scrolling and daydreaming.', 50:'Completed basic works but drifted.', 60:'Reasonable attention blocks.', 70:'Good productivity chunks.', 80:'Highly concentrated study sessions.', 90:'Superb momentum, minimal breaks.' };
  focus.addEventListener('input', (e) => {
    document.getElementById('val-focus').textContent = Math.round(e.target.value / 10);
    document.getElementById('desc-focus').textContent = focusTexts[e.target.value] || 'Consistent focused states.';
  });

  const energyTexts = { 10:'Peak physical and mental drive.', 20:'Totally exhausted, heavy fatigue.', 30:'Drowsy and sluggish.', 40:'Low stamina, forcing work.', 50:'Moderate energy levels.', 60:'Neutral baseline drive.', 70:'Good energy, clear head.', 80:'Highly energetic and motivated.', 90:'Phenomenal stamina, vibrant focus.' };
  energy.addEventListener('input', (e) => {
    document.getElementById('val-energy').textContent = Math.round(e.target.value / 10);
    document.getElementById('desc-energy').textContent = energyTexts[e.target.value] || 'Excellent energy base.';
  });
}

// Initialize Application Engine on Page Load
window.addEventListener('DOMContentLoaded', () => {

  // SPA routing
  window.addEventListener('hashchange', () => {
    if (STATE.token) navigateToView(window.location.hash.slice(1) || 'dashboard');
  });

  document.querySelectorAll('.nav-menu a').forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      window.location.hash = link.getAttribute('data-view');
    });
  });

  setupSliderChangeEvents();
  startGlobalSystemTick();

  // Poll coach insights every 30 seconds for real-time updates
  setInterval(async () => {
    if (STATE.activeView === 'dashboard') {
      STATE.coachingData = await API.fetchAnalytics();
      renderCoachInsights();
    }
  }, 30000);

  // Task form
  document.getElementById('task-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('task-id').value;
    const data = {
      title: document.getElementById('task-title').value,
      category: document.getElementById('task-category').value,
      day_of_week: document.getElementById('task-day').value,
      start_time: document.getElementById('task-start').value,
      end_time: document.getElementById('task-end').value,
      milestone_id: document.getElementById('task-milestone').value || null,
      completed: document.getElementById('task-completed').checked,
      alarm_enabled: document.getElementById('task-alarm').checked,
      actual_minutes_spent: parseInt(document.getElementById('task-actual-time').value) || 0
    };
    try {
      if (id) await API.updateTask(id, data);
      else await API.saveTask(data);
      closeModal('task-modal');
      refreshViewData(STATE.activeView);
    } catch (err) {
      alert('Error saving task: ' + err.message);
    }
  });

  document.getElementById('delete-task-btn').addEventListener('click', async () => {
    const id = document.getElementById('task-id').value;
    if (!id) return;
    if (confirm('Are you sure you want to delete this scheduled block?')) {
      try {
        await API.deleteTask(id);
        closeModal('task-modal');
        refreshViewData(STATE.activeView);
      } catch (err) {
        alert('Error deleting task: ' + err.message);
      }
    }
  });

  document.getElementById('add-task-btn').addEventListener('click', () => {
    document.getElementById('task-modal-title').textContent = 'Schedule Time Block';
    document.getElementById('task-form').reset();
    document.getElementById('task-id').value = '';
    document.getElementById('task-day').value = 'Monday';
    document.getElementById('task-alarm').checked = true;
    document.getElementById('delete-task-btn').classList.add('hidden');
    document.getElementById('task-complete-row').classList.add('hidden');
    populateMilestoneDropdown();
    openModal('task-modal');
  });

  document.getElementById('quick-add-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
      await API.saveTask({
        title: document.getElementById('quick-task-title').value,
        category: document.getElementById('quick-task-category').value || 'urgent',
        day_of_week: document.getElementById('quick-task-day').value,
        start_time: document.getElementById('quick-task-start').value,
        end_time: document.getElementById('quick-task-end').value,
        milestone_id: document.getElementById('quick-task-milestone').value || null,
        alarm_enabled: document.getElementById('quick-task-alarm').checked
      });
      document.getElementById('quick-task-title').value = '';
      document.getElementById('quick-task-category').value = '';
      refreshViewData(STATE.activeView);
    } catch (err) {
      alert('Error injecting task: ' + err.message);
    }
  });

  // Populate quick-add milestone dropdown whenever dashboard loads
  const origRefresh = refreshViewData;
  // patch: populate quick milestone on dashboard load after projects fetched
  async function populateQuickMilestone() {
    if (!STATE.projects.length) STATE.projects = await API.fetchProjects();
    const sel = document.getElementById('quick-task-milestone');
    sel.innerHTML = '<option value="">No milestone</option>';
    STATE.projects.forEach(p => p.milestones && p.milestones.forEach(m => {
      sel.insertAdjacentHTML('beforeend', `<option value="${m.id}">${p.title} → ${m.title}</option>`);
    }));
  }
  document.getElementById('quick-task-title').addEventListener('focus', populateQuickMilestone);

  // Project form
  document.getElementById('new-project-btn').addEventListener('click', () => {
    document.getElementById('project-form').reset();
    openModal('project-modal');
  });

  document.getElementById('project-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
      await API.saveProject({
        title: document.getElementById('project-title').value,
        description: document.getElementById('project-desc').value
      });
      closeModal('project-modal');
      refreshViewData(STATE.activeView);
    } catch (err) {
      alert('Error creating project: ' + err.message);
    }
  });

  // Milestone form
  document.getElementById('milestone-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
      await API.saveMilestone(document.getElementById('milestone-project-id').value, {
        title: document.getElementById('milestone-title').value,
        due_date: document.getElementById('milestone-due').value
      });
      closeModal('milestone-modal');
      refreshViewData(STATE.activeView);
    } catch (err) {
      alert('Error adding milestone: ' + err.message);
    }
  });

  // Reflection save
  document.getElementById('save-reflection-btn').addEventListener('click', async () => {
    const date = document.getElementById('reflection-date').value;
    const adherence_score = parseInt(document.getElementById('score-adherence').value);
    const focus_score = Math.round(parseInt(document.getElementById('score-focus').value) / 10);
    const energy_score = Math.round(parseInt(document.getElementById('score-energy').value) / 10);
    const notes_success = document.getElementById('notes-success').value;
    const notes_struggles = document.getElementById('notes-struggles').value;
    const notes_improvements = document.getElementById('notes-improvements').value;

    if (!notes_success || !notes_struggles || !notes_improvements) {
      alert('Please fill out all three reflection journal questions.');
      return;
    }

    try {
      await API.saveReflection({ date, adherence_score, focus_score, energy_score, notes_success, notes_struggles, notes_improvements });
      document.getElementById('notes-success').value = '';
      document.getElementById('notes-struggles').value = '';
      document.getElementById('notes-improvements').value = '';

      if (!STATE.isAlarmMuted) {
        if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const n = audioCtx.currentTime;
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(523.25, n);
        osc.frequency.setValueAtTime(659.25, n + 0.1);
        osc.frequency.setValueAtTime(783.99, n + 0.2);
        osc.frequency.setValueAtTime(1046.50, n + 0.3);
        gain.gain.setValueAtTime(0.08, n);
        gain.gain.exponentialRampToValueAtTime(0.001, n + 0.8);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start();
        osc.stop(n + 0.8);
      }
      refreshViewData(STATE.activeView);
      alert('Journal reflection saved successfully!');
    } catch (err) {
      alert('Error saving reflection: ' + err.message);
    }
  });

  // Sunday ritual wizard
  document.getElementById('sunday-ritual-btn').addEventListener('click', async () => {
    try {
      const analytics = await API.fetchAnalytics();
      STATE.projects = await API.fetchProjects();
      const rate = analytics.summary.completionRate;
      document.getElementById('wizard-completion-rate').textContent = `${rate}%`;
      document.getElementById('wizard-completion-ring').textContent = `${rate}%`;
      document.getElementById('wizard-hours').textContent = `${Math.round((analytics.summary.scheduledMinutes / 60) * 10) / 10}h`;

      const checklist = document.getElementById('wizard-milestones-list');
      checklist.innerHTML = '';
      let milestonesFound = false;
      STATE.projects.forEach(p => {
        p.milestones.forEach(m => {
          if (!m.completed) {
            milestonesFound = true;
            checklist.insertAdjacentHTML('beforeend', `
              <div class="wizard-check-item" data-milestone-id="${m.id}" onclick="toggleWizardMilestone(this, this.dataset.milestoneId)">
                <input type="checkbox" id="wiz-milestone-${m.id}" onclick="event.stopPropagation()">
                <div><strong>${p.title}</strong><p class="text-muted" style="font-size:0.8rem">${m.title}</p></div>
              </div>`);
          }
        });
      });
      if (!milestonesFound) checklist.innerHTML = `<p class="text-muted text-center py-4">No pending milestones. Excellent work!</p>`;
      nextWizardStep(1);
      openModal('sunday-ritual-modal');
    } catch (err) {
      alert('Error fetching Sunday planner metrics: ' + err.message);
    }
  });

  document.getElementById('complete-wizard-btn').addEventListener('click', async () => {
    try {
      for (let task of STATE.tasks) {
        await API.updateTask(task.id, { completed: false, actual_minutes_spent: 0 });
      }
      closeModal('sunday-ritual-modal');
      refreshViewData(STATE.activeView);
      alert('Ritual Complete! Planner cleared for a fresh week.');
    } catch (err) {
      alert('Error sealing planner: ' + err.message);
    }
  });

  // Calendar nav
  document.getElementById('cal-prev').addEventListener('click', () => {
    calendarDate.setMonth(calendarDate.getMonth() - 1);
    renderCalendar();
  });
  document.getElementById('cal-next').addEventListener('click', () => {
    calendarDate.setMonth(calendarDate.getMonth() + 1);
    renderCalendar();
  });

  // Modal overlay close
  document.querySelectorAll('.modal-overlay').forEach(overlay => {
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) closeModal(overlay.id);
    });
  });

  // Alarm mute toggle
  document.getElementById('alarm-volume-toggle').addEventListener('click', function() {
    STATE.isAlarmMuted = !STATE.isAlarmMuted;
    this.classList.toggle('muted', STATE.isAlarmMuted);
    this.title = STATE.isAlarmMuted ? 'Unmute Alarms' : 'Mute Alarms';
    if (!STATE.isAlarmMuted) playAlarmChime();
  });

  // Auth gate — boot app only after session verified
  initAuth();
});

// Called by auth.js after successful authentication
function bootApp() {
  navigateToView(window.location.hash.slice(1) || 'dashboard');
}
