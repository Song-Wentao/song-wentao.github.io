/* ==============================================
   MEOWTUAL LOVE — stories.js
   Loads stories from JSON, renders featured +
   grid, opens full story reader modal
   ============================================== */

/* Badge class lookup */
const BADGE_MAP = {
  adoption:  'badge-adoption',
  foster:    'badge-foster',
  events:    'badge-events',
  '':        'badge-community',
};

/* All stories — populated on load */
let allStories = [];
let nonFeaturedStories = [];
const PAGE_SIZE = 4;
let currentPage = 0;

/* ============================================================
   LOAD + RENDER
   ============================================================ */
document.addEventListener('DOMContentLoaded', () => {
  fetch('data/stories.json')
    .then(r => r.json())
    .then(data => {
      allStories = data;
      renderAll(data);
    })
    .catch(err => {
      console.error('Failed to load stories:', err);
    });
});

function renderAll(stories) {
  const featured    = stories.find(s => s.featured);
  nonFeaturedStories = stories.filter(s => !s.featured);

  if (featured) renderFeatured(featured);

  loadMoreStories();

  const btn = document.querySelector('.btn-outline-coral');
  if (btn) btn.addEventListener('click', loadMoreStories);
}

function loadMoreStories() {
  const start = currentPage * PAGE_SIZE;
  const slice = nonFeaturedStories.slice(start, start + PAGE_SIZE);

  slice.forEach(s => renderCard(s));
  currentPage++;

  const btn = document.querySelector('.btn-outline-coral');
  if (btn) {
    const allLoaded = currentPage * PAGE_SIZE >= nonFeaturedStories.length;
    btn.style.display = allLoaded ? 'none' : '';
  }
}

/* ---- FEATURED ---- */
function renderFeatured(s) {
  const el = document.getElementById('featuredStory');
  if (!el) return;

  el.innerHTML = `
    <div class="featured-img"><span><img src="${s.image}" alt="${s.title}"></span></div>
    <div class="featured-content">
      <div class="featured-badge">&#x2728; Featured Story</div>
      <h2>${s.title}</h2>
      <div class="story-meta">
        <span>&#x1F4C5; ${s.date}</span>
        <span>&#x2764;&#xFE0F; ${s.category}</span>
      </div>
      <p>${s.excerpt}</p>
      <button class="btn-primary" onclick="openStoryModal(${s.id})">Read Full Story &#x2192;</button>
    </div>
  `;
}

/* ---- STORY CARDS ---- */
function renderCard(s) {
  const grid = document.getElementById('storiesGrid');
  if (!grid) return;

  const card = document.createElement('div');
  card.className = 'story-card';
  card.innerHTML = `
    <div class="story-img">
      <img src="${s.image}" alt="${s.title}">
      <div class="story-cat-badge badge">${s.category}</div>
    </div>
    <div class="story-content">
      <div class="story-date">&#x1F4C5; ${s.date}</div>
      <div class="story-title">${s.title}</div>
      <div class="story-excerpt">${s.excerpt}</div>
      <button class="story-link" onclick="openStoryModal(${s.id})">Read More &#x2192;</button>
    </div>
  `;
  grid.appendChild(card);
}

/* ============================================================
   STORY READER MODAL
   ============================================================ */
function openStoryModal(id) {
  const s = allStories.find(x => x.id === id);
  if (!s) return;

  const body = s.body || '<p>' + s.excerpt + '</p>';

  document.getElementById('storyModalBox').innerHTML = `
    <div class="modal-header" style="background:linear-gradient(135deg,var(--charcoal),#4A3530)">
      <button class="modal-close" onclick="closeStoryModal()">&#x2715;</button>
      <h2>${s.title}</h2>
      <p>&#x1F4C5;&ensp;${s.date}</p>
    </div>
    <div class="story-hero-img"><span><img src="${s.image}" alt="${s.title}"></span></div>
    <div class="modal-body">
      <div class="story-modal-meta">
        <span class="story-cat-badge badge" style="position:static">${s.category}</span>
        <span class="story-modal-date">Published ${s.date}</span>
      </div>
      <div class="story-modal-body">${body}</div>
    </div>
  `;

  document.getElementById('storyModal').classList.add('open');
  document.body.style.overflow = 'hidden';
}

function closeStoryModal(e) {
  if (!e || e.target === document.getElementById('storyModal')) {
    document.getElementById('storyModal').classList.remove('open');
    document.body.style.overflow = '';
  }
}

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') closeStoryModal();
});
