const _supabase = window.supabase.createClient(
  'https://itrdghrsjztzlgtnrmds.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0cmRnaHJzanp0emxndG5ybWRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNjM5MDgsImV4cCI6MjA5NTYzOTkwOH0.KwrEYomDGu9CBHK3pymyayE_AyyQuklxhhXW6BP9yg8'
);

function togglePasswordVisibility(id) {
  const input = document.getElementById(id);
  const btn = input.parentElement.querySelector('.password-toggle i');
  if (input.type === 'password') {
    input.type = 'text';
    if (btn) { btn.className = 'fa-solid fa-eye-slash'; }
  } else {
    input.type = 'password';
    if (btn) { btn.className = 'fa-solid fa-eye'; }
  }
}

function showForm(name) {
  document.querySelectorAll('.auth-form').forEach(f => f.classList.remove('active'));
  document.querySelectorAll('.auth-tab').forEach(t => t.classList.remove('active'));
  const form = document.getElementById(name + '-form');
  if (form) form.classList.add('active');
  const tab = document.querySelector(`[data-tab="${name}"]`);
  if (tab) tab.classList.add('active');
}

function hideAuthErrors() {
  document.querySelectorAll('.auth-msg').forEach(el => {
    el.textContent = '';
    el.classList.add('hidden');
  });
}

function showAuthMsg(id, msg, type) {
  const el = document.getElementById(id);
  if (!el) return;
  el.textContent = msg;
  el.className = 'auth-msg ' + type;
  el.classList.remove('hidden');
}

async function initAuth() {
  const hash = window.location.hash.substring(1);
  const hashParams = new URLSearchParams(hash);
  if (hashParams.get('type') === 'recovery') {
    showForm('reset');
    document.getElementById('auth-overlay').classList.add('active');
    window.location.hash = '';
    return;
  }

  // If user logged out, show the auth overlay and wait
  if (localStorage.getItem('aether_logged_out')) {
    document.getElementById('auth-overlay').classList.add('active');
    return;
  }

  // Single-user mode (SQLite) — skip auth
  STATE.token = 'local-mode';
  STATE.user = { id: 1, email: 'local@aether.app', user_metadata: { display_name: 'You' } };
  updateSidebarUser(STATE.user);
  document.getElementById('auth-overlay').classList.remove('active');
  bootApp();
}

function updateSidebarUser(user) {
  const name = user.user_metadata?.display_name || user.email?.split('@')[0] || 'User';
  document.getElementById('sidebar-user-name').textContent = name;
  document.getElementById('sidebar-user-role').textContent = user.email || 'Signed In';
  const parts = name.split(' ').filter(Boolean);
  const initials = parts.length > 1 ? parts[0][0] + parts[1][0] : name.slice(0, 2);
  document.getElementById('sidebar-user-avatar').textContent = initials.toUpperCase();
}

document.addEventListener('click', (e) => {
  const tab = e.target.closest('.auth-tab');
  if (tab) { hideAuthErrors(); showForm(tab.dataset.tab); }
});

document.getElementById('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  hideAuthErrors();
  const { error } = await _supabase.auth.signInWithPassword({
    email: document.getElementById('login-email').value,
    password: document.getElementById('login-password').value
  });
  if (error) showAuthMsg('login-error', error.message, 'auth-error');
});

document.getElementById('register-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  hideAuthErrors();
  const password = document.getElementById('register-password').value;
  const confirm = document.getElementById('register-confirm').value;
  if (password !== confirm) {
    showAuthMsg('register-error', 'Passwords do not match', 'auth-error');
    return;
  }
  const { error } = await _supabase.auth.signUp({
    email: document.getElementById('register-email').value,
    password,
    options: { data: { display_name: document.getElementById('register-name').value } }
  });
  if (error) {
    showAuthMsg('register-error', error.message, 'auth-error');
  } else {
    showAuthMsg('register-error', 'Account created! If email confirmation is on, check your inbox.', 'auth-success');
  }
});

document.getElementById('forgot-password-btn').addEventListener('click', () => {
  hideAuthErrors();
  showForm('forgot');
});

document.getElementById('back-to-login-btn').addEventListener('click', () => {
  hideAuthErrors();
  showForm('login');
});

document.getElementById('forgot-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  hideAuthErrors();
  const { error } = await _supabase.auth.resetPasswordForEmail(
    document.getElementById('forgot-email').value,
    { redirectTo: window.location.origin }
  );
  if (error) {
    showAuthMsg('forgot-error', error.message, 'auth-error');
  } else {
    showAuthMsg('forgot-success', 'Reset link sent! Check your email.', 'auth-success');
    document.getElementById('forgot-email').value = '';
  }
});

document.getElementById('reset-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  hideAuthErrors();
  const password = document.getElementById('reset-password').value;
  const confirm = document.getElementById('reset-confirm').value;
  if (password !== confirm) {
    showAuthMsg('reset-error', 'Passwords do not match', 'auth-error');
    return;
  }
  const { error } = await _supabase.auth.updateUser({ password });
  if (error) {
    showAuthMsg('reset-error', error.message, 'auth-error');
  } else {
    showAuthMsg('reset-error', 'Password updated! Redirecting...', 'auth-success');
    setTimeout(() => location.reload(), 1500);
  }
});

document.getElementById('logout-btn').addEventListener('click', async () => {
  try {
    await _supabase.auth.signOut();
  } catch (err) {
    console.warn('Supabase signOut (non-fatal in local mode):', err);
  }
  STATE.token = null;
  STATE.user = null;
  localStorage.setItem('aether_logged_out', '1');
  location.reload();
});

document.getElementById('google-login-btn').addEventListener('click', async () => {
  const { error } = await _supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: window.location.origin }
  });
  if (error) showAuthMsg('login-error', error.message, 'auth-error');
});

document.getElementById('guest-login-btn').addEventListener('click', () => {
  localStorage.removeItem('aether_logged_out');
  STATE.token = 'local-mode';
  STATE.user = { id: 1, email: 'local@aether.app', user_metadata: { display_name: 'You' } };
  updateSidebarUser(STATE.user);
  document.getElementById('auth-overlay').classList.remove('active');
  bootApp();
});
