/* ==============================================
   MEOWTUAL LOVE — adoption.js
   Loads cats from JSON, paginated grid,
   cat profile modal → adoption application modal
   ============================================== */

const PER_PAGE = 8;
let page = 1;
let allCats = [];

/* ---- LOAD ---- */
document.addEventListener('DOMContentLoaded', () => {
  fetch('data/adoption.json')
    .then(r => r.json())
    .then(data => { allCats = data; buildPage(); setupPaginationBtns(); })
    .catch(err => console.error('Failed to load cats:', err));
});

/* ---- BUILD GRID ---- */
function buildPage() {
  const grid = document.getElementById('catsGrid');
  if (!grid) return;
  grid.innerHTML = '';
  const start = (page - 1) * PER_PAGE;
  allCats.slice(start, start + PER_PAGE).forEach((cat, local) => {
    const i       = start + local;
    const pending = cat.status === 'pending';
    const card = document.createElement('div');
    card.className = 'cat-card';
    card.innerHTML = `
      <div class="cat-img">
        <img src="${cat.image}" alt="${cat.name}">
        <div class="status-badge ${pending ? 'status-pending' : 'status-available'}">
          ${pending ? 'Pending' : 'Available'}
        </div>
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
        <button class="cat-btn" onclick="showCatProfile(${i})" ${pending ? 'disabled' : ''}>
          ${pending ? 'Adoption Pending' : 'Meet ' + cat.name + ' \u2192'}
        </button>
      </div>`;
    grid.appendChild(card);
  });
  updatePagination();
}

/* ---- PAGINATION ---- */
function setupPaginationBtns() {
  document.getElementById('prevPage')?.addEventListener('click', () => {
    if (page > 1) { page--; buildPage(); scrollToGrid(); }
  });
  document.getElementById('nextPage')?.addEventListener('click', () => {
    if (page < Math.ceil(allCats.length / PER_PAGE)) { page++; buildPage(); scrollToGrid(); }
  });
}
function updatePagination() {
  const total = Math.ceil(allCats.length / PER_PAGE);
  document.getElementById('pageInfo').textContent = 'Page ' + page + ' of ' + total;
  document.getElementById('prevPage').disabled    = page === 1;
  document.getElementById('nextPage').disabled    = page === total;
  const dots = document.getElementById('paginationDots');
  dots.innerHTML = '';
  for (let i = 1; i <= total; i++) {
    const d = document.createElement('button');
    d.className = 'page-dot' + (i === page ? ' active' : '');
    d.onclick = () => { page = i; buildPage(); scrollToGrid(); };
    dots.appendChild(d);
  }
}
function scrollToGrid() {
  document.querySelector('.adoption-grid-section')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

/* ---- CAT PROFILE MODAL ---- */
function showCatProfile(i) {
  const cat   = allCats[i];

  document.getElementById('modalContent').innerHTML = `
    <div class="modal-header">
      <button class="modal-close" onclick="closeCatModal()">&#x2715;</button>
      <h2>${cat.name}</h2>
      <p>${cat.age} • ${cat.gender} • ${cat.personality}</p>
    </div>
    <div class="modal-body">
      <div class="modal-section">
        <div class="modal-section-title">📸 Photos</div>
        <div class="modal-gallery">
          ${cat.photos && cat.photos.length > 0 
                        ? cat.photos.map(photo => `
                            <div class="gallery-item">
                                <img src="${photo}" alt="${cat.name}" loading="lazy">
                            </div>
                        `).join('')
                        : `
                            <div class="media-item">
                                <img src="${cat.image}" alt="${cat.name}" loading="lazy">
                            </div>
                        `
          }
        </div>
      </div>

      ${cat.videos && cat.videos.length > 0 ? `
      <div class="modal-section">
        <div class="modal-section-title">🎥 Videos</div>
        <div class="modal-gallery">
          ${cat.videos.map(video => `
                            <div class="gallery-item">
                              <video src="${video}" controls></video>
                            </div>
                        `).join('')
          }
        </div>
      </div>
      ` : ''
      }

      <div class="modal-section">
        <div class="modal-section-title">💛 About ${cat.name}</div>
        <p class="modal-desc"> ${cat.description || cat.name + ' is a wonderful cat looking for a loving forever home!'} </p>
      </div>

      <div class="modal-section">
        <div class="modal-section-title">📋 Details</div>
        <div class="modal-details">
          <div class="detail-item"><div class="detail-label">Age</div><div class="detail-value">${cat.age}</div></div>
          <div class="detail-item"><div class="detail-label">Gender</div><div class="detail-value">${cat.gender}</div></div>
          <div class="detail-item"><div class="detail-label">Weight</div><div class="detail-value">${cat.weight}</div></div>
          <div class="detail-item"><div class="detail-label">Coat</div><div class="detail-value">${cat.color_coat}</div></div>
          <div class="detail-item"><div class="detail-label">Breed</div><div class="detail-value">${cat.breed}</div></div>
          <div class="detail-item"><div class="detail-label">Vaccinated</div><div class="detail-value">${cat.vaccinated}</div></div>
          <div class="detail-item"><div class="detail-label">Neutered</div><div class="detail-value">${cat.neutered}</div></div>
          <div class="detail-item"><div class="detail-label">Good With</div><div class="detail-value">${cat.goodWith}</div></div>
        </div>
      </div>

      <div class="modal-section">
        <button class="form-submit" onclick="openAdoptForm('${cat.name.replace(/'/g, "\\'")}')">🏠 Adopt ${cat.name}</button>
      </div>
  `;

  document.getElementById('catModal').classList.add('open');
  document.body.style.overflow = 'hidden';
}

function closeCatModal() {
  document.getElementById('catModal').classList.remove('open');
  document.body.style.overflow = '';
}
document.getElementById('catModal')?.addEventListener('click', e => {
  if (e.target === document.getElementById('catModal')) closeCatModal();
});

/* ---- ADOPTION APPLICATION MODAL ---- */
function openAdoptForm(catName) {
  closeCatModal();

  document.getElementById('adoptModalContent').innerHTML = `
    <div class="modal-header">
      <button class="modal-close" onclick="closeAdoptModal()">&#x2715;</button>
      <h2>Adopt ${catName}</h2>
      <p>Tell us a bit about yourself</p>
    </div>
    <div class="modal-body">
      <div class="adopt-form-note">
        Fill in your details and our adoption team will contact you within 1–2 business days to arrange a meet-and-greet with ${catName}.
      </div>
      <div id="adoptForm">
        <div class="form-row">
          <div class="form-group">
            <label>First Name *</label>
            <input type="text" class="form-input" id="adoptFirst" placeholder="Jane">
          </div>
          <div class="form-group">
            <label>Last Name *</label>
            <input type="text" class="form-input" id="adoptLast" placeholder="Doe">
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>Email Address *</label>
            <input type="email" class="form-input" id="adoptEmail" placeholder="jane@example.com">
          </div>
          <div class="form-group">
            <label>Phone Number *</label>
            <input type="tel" class="form-input" id="adoptPhone" placeholder="(555) 123-4567">
          </div>
        </div>
        <div class="form-group">
          <label>Home Address</label>
          <input type="text" class="form-input" id="adoptAddress" placeholder="123 Main Street, Tampa, FL">
        </div>
        <div class="form-row">
          <div class="form-group">
          <label>Housing Type *</label>
          <select class="form-input form-select" id="adoptHousing">
            <option value="" disabled selected>Select type…</option>
            <option>House (owned)</option>
            <option>House (rented)</option>
            <option>Apartment (owned)</option>
            <option>Apartment (rented)</option>
            <option>Condo</option>
            <option>Other</option>
          </select>
        </div>
        <div class="form-group">
          <label>Other Pets at Home?</label>
          <select class="form-input form-select" id="adoptPets">
            <option value="" disabled selected>Select…</option>
            <option>No other pets</option>
            <option>Dog(s)</option>
            <option>Cat(s)</option>
            <option>Both dogs & cats</option>
            <option>Other</option>
          </select>
        </div>
      </div>
      <div class="form-group">
        <label>Why do you want to adopt ${catName}?</label>
        <textarea class="form-textarea" id="adoptReason" rows="4" placeholder="Tell us why you\'d be a great match…"></textarea>
      </div>
      <div class="form-group">
        <label>Cat ownership experience</label>
        <select class="form-input form-select" id="adoptExp">
          <option value="" disabled selected>Select…</option>
          <option>Yes, currently own cats</option>
          <option>Yes, owned cats before</option>
          <option>No, first time cat owner</option>
        </select>
      </div>
      <button class="form-submit" onclick="submitAdoptForm('${catName.replace(/'/g, "\\'")}')">Submit Application &#x2192;</button>
    </div>
    <div class="adopt-submitted" id="adoptSuccess">
      <div class="success-icon">&#x1F43E;</div>
      <h3>Application Submitted!</h3>
      <p>Thank you for applying to adopt <strong>${catName}</strong>.<br>Our team will reach out within 1–2 business days. We're so excited for you!</p>
    </div>
  </div>
  `;

  document.getElementById('adoptModal').classList.add('open');
  document.body.style.overflow = 'hidden';
}

function submitAdoptForm(catName) {
  const first   = document.getElementById('adoptFirst')?.value.trim();
  const last    = document.getElementById('adoptLast')?.value.trim();
  const email   = document.getElementById('adoptEmail')?.value.trim();
  const phone   = document.getElementById('adoptPhone')?.value.trim();
  const housing = document.getElementById('adoptHousing')?.value;

  if (!first || !last || !email || !phone || !housing) {
    alert('Please fill in all required fields (marked with *).');
    return;
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    alert('Please enter a valid email address.');
    return;
  }
  document.getElementById('adoptForm').style.display    = 'none';
  document.getElementById('adoptSuccess').style.display = 'block';
}

function closeAdoptModal(e) {
  if (!e || e.target === document.getElementById('adoptModal')) {
    document.getElementById('adoptModal').classList.remove('open');
    document.body.style.overflow = '';
  }
}

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') { closeCatModal(); closeAdoptModal(); }
});