
// ==========================================
// ADVANCED FEATURES (REPORTS, TIMER, VIEW REFLECTION)
// ==========================================

STATE.activeTimers = {};

async function toggleTaskTimer(taskId) {
  const task = STATE.tasks.find(t => t.id === taskId);
  if (!task) return;

  if (STATE.activeTimers[taskId]) {
    // STOP TIMER
    const startTime = STATE.activeTimers[taskId];
    const durationMs = Date.now() - startTime;
    const durationMinutes = Math.round(durationMs / 60000);
    
    delete STATE.activeTimers[taskId];
    
    // Add to actual minutes spent
    const newMinutes = (task.actual_minutes_spent || 0) + durationMinutes;
    task.actual_minutes_spent = newMinutes;
    
    try {
      await API.updateTask(taskId, { actual_minutes_spent: newMinutes });
      refreshViewData('dashboard'); // re-render
    } catch (e) {
      console.error(e);
    }
  } else {
    // START TIMER
    STATE.activeTimers[taskId] = Date.now();
    refreshViewData('dashboard');
  }
}

function viewReflection(dateStr) {
  const ref = STATE.reflections.find(r => r.date === dateStr);
  if (!ref) return;
  
  document.getElementById('vr-date').textContent = `Reflection: ${ref.date}`;
  document.getElementById('vr-adherence').textContent = `${ref.adherence_score}%`;
  document.getElementById('vr-focus').textContent = `${ref.focus_score} / 10`;
  document.getElementById('vr-energy').textContent = `${ref.energy_score} / 10`;
  
  document.getElementById('vr-success').textContent = ref.notes_success || 'None recorded.';
  document.getElementById('vr-struggles').textContent = ref.notes_struggles || 'None recorded.';
  document.getElementById('vr-improvements').textContent = ref.notes_improvements || 'None recorded.';
  
  openModal('view-reflection-modal');
}

function downloadReportPDF() {
  const container = document.getElementById('report-container');
  const type = document.getElementById('report-type').value;
  const reportHTML = container.innerHTML;

  const printWindow = window.open('', '_blank', 'width=900,height=700');
  printWindow.document.write(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Aether Report - ${type}</title>
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Segoe UI', sans-serif; background: #07050f; color: #f3f1f8; padding: 40px; }
        h1, h2, h3, h4 { font-family: 'Segoe UI', sans-serif; color: #ffffff; }
        h2 { font-size: 1.8rem; margin-bottom: 4px; }
        p { color: #9c97b8; font-size: 0.9rem; }
        .grid-card, [class*="glow-card"] {
          background: rgba(22,17,43,0.9);
          border: 1px solid rgba(255,255,255,0.1);
          border-radius: 12px;
          padding: 20px;
          margin-bottom: 16px;
        }
        h3.text-emerald { color: #10b981; }
        h3.text-cyan { color: #06b6d4; }
        h1[style*="3rem"] { color: #ffffff; }
        div[style*="grid"] { display: block; }
        div[style*="grid"] > * { margin-bottom: 16px; }
        button { display: none !important; }
        @media print {
          body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
        }
      </style>
    </head>
    <body>${reportHTML}</body>
    </html>
  `);
  printWindow.document.close();
  printWindow.focus();
  setTimeout(() => {
    printWindow.print();
    printWindow.close();
  }, 400);
}

function generateReport() {
  const type = document.getElementById('report-type').value;
  const container = document.getElementById('report-container');
  
  if (!STATE.coachingData) {
    container.innerHTML = `<p class="text-danger text-center">No data available to generate report. Please log some tasks and reflections.</p>`;
    return;
  }
  
  const { summary, categoryStats } = STATE.coachingData;
  
  let timeFrameText = "This Week";
  if (type === 'monthly') timeFrameText = "This Month";
  if (type === 'quarterly') timeFrameText = "This Quarter";
  if (type === 'yearly') timeFrameText = "This Year";
  
  // Create a nice looking report (for now using the available data)
  let catHtml = '';
  Object.keys(categoryStats).forEach(cat => {
    catHtml += `
      <div style="background: rgba(255,255,255,0.05); padding: 15px; border-radius: 8px; margin-bottom: 10px;">
        <h4 style="margin:0 0 5px 0; color: var(--accent-purple); text-transform: uppercase;">${cat}</h4>
        <div style="display: flex; justify-content: space-between;">
          <span>Scheduled: ${Math.round((categoryStats[cat].scheduled / 60)*10)/10} hrs</span>
          <span>Actual: ${Math.round((categoryStats[cat].actual / 60)*10)/10} hrs</span>
          <span>Completed: ${categoryStats[cat].completedCount} / ${categoryStats[cat].tasksCount} tasks</span>
        </div>
      </div>
    `;
  });
  
  container.innerHTML = `
    <div style="display: flex; justify-content: space-between; align-items: flex-end; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 20px; margin-bottom: 20px;">
      <div>
        <h2 style="margin:0;">Productivity Report</h2>
        <p class="text-muted" style="margin: 5px 0 0 0;">Timeframe: ${timeFrameText}</p>
      </div>
      <button class="btn btn-outline btn-sm" onclick="downloadReportPDF()"><i class="fa-solid fa-file-arrow-down"></i> Download PDF</button>
    </div>
    
    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 30px;">
      <div class="grid-card glow-card">
        <h3 class="text-emerald">Plan Adherence</h3>
        <h1 style="font-size: 3rem; margin: 10px 0;">${summary.completionRate}%</h1>
        <p class="text-muted">${summary.completedTasks} of ${summary.totalTasks} tasks finished.</p>
      </div>
      <div class="grid-card glow-card">
        <h3 class="text-cyan">Total Productive Time</h3>
        <h1 style="font-size: 3rem; margin: 10px 0;">${Math.floor(summary.actualMinutes / 60)}h ${summary.actualMinutes % 60}m</h1>
        <p class="text-muted">You logged ${Math.floor(summary.actualMinutes / 60)}h ${summary.actualMinutes % 60}m of tracked work.</p>
      </div>
    </div>
    
    <h3>Category Performance</h3>
    ${catHtml}
  `;
}
