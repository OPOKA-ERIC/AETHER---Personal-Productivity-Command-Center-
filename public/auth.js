const _supabase = window.supabase.createClient(
  'https://itrdghrsjztzlgtnrmds.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0cmRnaHJzanp0emxndG5ybWRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNjM5MDgsImV4cCI6MjA5NTYzOTkwOH0.KwrEYomDGu9CBHK3pymyayE_AyyQuklxhhXW6BP9yg8'
);

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

  const { data: { session } } = await _supabase.auth.getSession();

  if (session) {
    STATE.token = session.access_token;
    STATE.user = session.user;
    updateSidebarUser(session.user);
    document.getElementById('auth-overlay').classList.remove('active');
    bootApp();
  } else {
    document.getElementById('auth-overlay').classList.add('active');
  }

  _supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
      STATE.token = session.access_token;
      STATE.user = session.user;
      updateSidebarUser(session.user);
      document.getElementById('auth-overlay').classList.remove('active');
      bootApp();
    } else if (event === 'SIGNED_OUT') {
      STATE.token = null;
      STATE.user = null;
      location.reload();
    }
  });
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
  await _supabase.auth.signOut();
});
