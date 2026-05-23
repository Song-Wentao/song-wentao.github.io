/* ==============================================
   MEOWTUAL LOVE — index.js  (homepage)
   ============================================== */

let allCats = [];

document.addEventListener('DOMContentLoaded', () => {
  fetch('data/adoption.json')
    .then(r => r.json())
    .then(data => { allCats = data; buildPage(); })
    .catch(err => console.error('Failed to load cats:', err));
});

function buildPage() {
  const grid = document.getElementById('catsGrid');
  if (!grid) return;
  grid.innerHTML = '';

  allCats
    .filter(cat => cat.status === 'available')
    .slice(0, 4)
    .forEach(cat => {
      const card = document.createElement('div');
      card.className = 'cat-card';
      card.innerHTML = `
        <div class="cat-img">
          <img src="${cat.image}" alt="${cat.name}">
          <div class="status-badge status-available">Available</div>
        </div>
        <div class="cat-info">
          <div class="cat-row">
            <div class="cat-name">${cat.name}</div>
          </div>
          <div class="cat-row">
            <div class="cat-age">${cat.age}</div>
          </div>
          <div class="cat-gender">${cat.gender}</div>
          <div class="cat-personality">${cat.personality}</div>
        </div>`;
      grid.appendChild(card);
    });
}