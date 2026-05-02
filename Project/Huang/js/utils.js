// js/utils.js  — shared utilities loaded on every page

// ── Navbar HTML ───────────────────────────────────────────────
function injectNavbar(activePage) {
  const pages = [
    { id: 'about',        label: 'About',        href: 'index.html' },
    { id: 'projects',     label: 'Projects',     href: 'projects.html' },
    { id: 'publications', label: 'Publications', href: 'publication.html' }
    /*
    { id: 'people',       label: 'People',       href: 'people.html' },      
    { id: 'opportunities',label: 'Opportunities',href: 'opportunities.html' }
    */ 
  ];

  const links = pages.map(p => `
    <li>
      <a href="${p.href}" class="nav-link${activePage === p.id ? ' active' : ''}">${p.label}</a>
    </li>`).join('');

  const navHTML = `
    <nav id="navbar">
      <div class="nav-inner">
        <a class="nav-logo" href="index.html">
          <span class="logo-icon">♥</span>
          <span class="logo-text">Shuli Huang · Cardiac physiologist</span>
        </a>
        <ul class="nav-links">${links}</ul>
        <button class="hamburger" id="hamburger" aria-label="Toggle menu">
          <span></span><span></span><span></span>
        </button>
      </div>
    </nav>`;

  document.body.insertAdjacentHTML('afterbegin', navHTML);

  // Hamburger toggle
  document.getElementById('hamburger').addEventListener('click', () => {
    document.getElementById('navbar').classList.toggle('menu-open');
  });

  // Scroll shadow
  window.addEventListener('scroll', () => {
    document.getElementById('navbar').classList.toggle('scrolled', window.scrollY > 20);
  }, { passive: true });
}

// ── Footer HTML ───────────────────────────────────────────────
function injectFooter() {
  const footerHTML = `
    <footer>
      <div class="footer-inner">
        <div class="footer-brand">
          <span class="logo-icon">♥</span>
          <span class="logo-name">Shuli Huang · Cardiac physiologist</span>
        </div>
        <nav class="footer-links">
          <a href="index.html">About</a>
          <a href="projects.html">Projects</a>
          <a href="publication.html">Publications</a>
<!--
          <a href="people.html">People</a>
          <a href="opportunities.html">Opportunities</a>
-->
          </nav>
        <div class="footer-copy">
          College of Medicine Molecular Pharmacology & Physiology<br>
          University of South Florida
        </div>
      </div>
    </footer>`;
  document.body.insertAdjacentHTML('beforeend', footerHTML);
}

// ── DOM helpers ───────────────────────────────────────────────
function el(tag, className) {
  const e = document.createElement(tag);
  if (className) e.className = className;
  return e;
}

function initials(name) {
  return name.replace(/^Dr\.\s*/, '')
    .split(' ').filter(Boolean)
    .slice(0, 2).map(w => w[0]).join('').toUpperCase();
}

// Stagger animation helper
function staggerIn(elements, baseDelay = 0, step = 0.07) {
  elements.forEach((el, i) => {
    el.style.animationDelay = `${baseDelay + i * step}s`;
    el.classList.add('anim-slide-up');
  });
}
