(async function () {
  /* ── Load data ── */
  const response = await fetch('update/research.json');
  const DATA = await response.json();

  /* ── Render projects ── */
  const listEl   = document.getElementById('proj-list');
  const detailEl = document.getElementById('proj-detail');

  DATA.projects.forEach((proj, i) => {
    // sidebar item
    const li = document.createElement('div');
    li.className = 'proj-list-item' + (i === 0 ? ' active' : '');
    li.dataset.id = proj.id;
    li.innerHTML = `<div class="proj-list-year">${proj.period}</div>
                    <div class="proj-list-name">${proj.title}</div>`;
    li.addEventListener('click', () => activateProject(proj.id));
    listEl.appendChild(li);

    // detail panel
    const statusLabel = proj.status === 'inprep'
      ? '<span class="proj-status">In preparation</span>'
      : proj.status === 'in press'
      ? '<span class="proj-status">In press</span>'
      : '';

    const bodyHTML = proj.body.map(p => `<p>${p}</p>`).join('');

    const imgsHTML = proj.images.map(img =>
      `<figure>
         <img src="${img.src}" alt="${proj.title}" onerror="this.parentElement.style.display='none'">
         ${img.caption ? `<figcaption>${img.caption}</figcaption>` : ''}
       </figure>`
    ).join('');

    const panel = document.createElement('div');
    panel.className = 'proj-panel' + (i === 0 ? ' active' : '');
    panel.dataset.id = proj.id;
    panel.innerHTML = `<h3>${proj.title}</h3>
                       ${statusLabel}
                       <div style="margin-top:20px">${bodyHTML}${imgsHTML}</div>`;
    detailEl.appendChild(panel);
  });

  function activateProject(id) {
    document.querySelectorAll('.proj-list-item').forEach(el =>
      el.classList.toggle('active', el.dataset.id === id));
    document.querySelectorAll('.proj-panel').forEach(el =>
      el.classList.toggle('active', el.dataset.id === id));
  }

  /* ── Render publications ── */
  const pubList = document.getElementById('pub-list');
  DATA.publications.forEach((pub, i) => {
    const li = document.createElement('li');
    li.className = 'pub-item';

    const badge = pub.status === 'inprep'
      ? '<span class="pub-badge inprep">In prep</span>'
      : pub.status === 'in press'
      ? '<span class="pub-badge">In press</span>'
      : '';

    const titleInner = pub.url
      ? `<a href="${pub.url}" target="_blank" rel="noopener">${pub.title}</a>`
      : pub.title;

    const meta = [pub.year, pub.journal, pub.vol].filter(Boolean).join(' · ');

    li.innerHTML = `
      <div class="pub-body">
        <div class="pub-title">${titleInner}${badge}</div>
        <div class="pub-authors">${pub.authors}</div>
        ${meta ? `<div class="pub-meta">${meta}</div>` : ''}
      </div>`;
    pubList.appendChild(li);
  });

  /* ── Scroll-reveal publications ── */
  const observer = new IntersectionObserver(entries => {
    entries.forEach((e, delay) => {
      if (e.isIntersecting) {
        setTimeout(() => e.target.classList.add('visible'), delay * 80);
        observer.unobserve(e.target);
      }
    });
  }, { threshold: 0.1 });
  document.querySelectorAll('.pub-item').forEach(el => observer.observe(el));
})();