/* ==============================================
   MEOWTUAL LOVE — components.js
   Loads navbar + footer, nav behaviour
   ============================================== */

function loadComponent(id, file, cb) {
  fetch('components/' + file)
    .then(r => { if (!r.ok) throw new Error(file + ' ' + r.status); return r.text(); })
    .then(html => {
      const el = document.getElementById(id);
      if (el) { el.innerHTML = html; if (cb) cb(); }
    })
    .catch(e => console.warn('[loadComponent]', e));
}

/* Hamburger toggle – called from navbar.html onclick */
function navToggle() {
  const links  = document.getElementById('navLinks');
  const burger = document.getElementById('hamburger');
  links  && links.classList.toggle('open');
  burger && burger.classList.toggle('open');
}

function initNav() {
  /* Close mobile menu on link click */
  const links  = document.getElementById('navLinks');
  const burger = document.getElementById('hamburger');
  links && links.querySelectorAll('a').forEach(a =>
    a.addEventListener('click', () => {
      links.classList.remove('open');
      burger && burger.classList.remove('open');
    })
  );

  /* Highlight current page */
  const page = location.pathname.split('/').pop() || 'index.html';
  links && links.querySelectorAll('a').forEach(a => {
    if (a.getAttribute('href') === page) a.classList.add('active');
  });
}

/* Scroll → nav shadow */
window.addEventListener('scroll', () => {
  const nav = document.getElementById('mainNav');
  if (nav) nav.classList.toggle('scrolled', window.scrollY > 50);
});

/* Boot */
document.addEventListener('DOMContentLoaded', () => {
  loadComponent('navbar', 'navbar.html', initNav);
  loadComponent('footer', 'footer.html');
});
