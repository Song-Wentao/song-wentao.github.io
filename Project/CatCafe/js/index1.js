/* ==============================================
   MEOWTUAL LOVE — index.js  (homepage)
   ============================================== */

const cats = [
  {name:"Whiskers", age:"2 years",  gender:"Male",   personality:"Playful & Curious",     status:"available", emoji:"🐈",   color:"#E8D5C8", description:"Whiskers is an energetic and curious cat who loves to explore. He enjoys interactive toys and is always ready for playtime. Despite his playful nature, he's also a great cuddler when tired out!", weight:"4.5 kg", color_coat:"White & Black",  breed:"Domestic Shorthair", vaccinated:"Yes", neutered:"Yes",       goodWith:"Children, Other Cats"},
  {name:"Mochi",    age:"1 year",   gender:"Female", personality:"Gentle & Affectionate",  status:"available", emoji:"🐱",   color:"#D4EDE5", description:"Mochi is a sweet and gentle soul who loves nothing more than curling up in your lap. She's perfect for someone looking for a calm companion who will shower them with affection.", weight:"3.8 kg", color_coat:"Calico",         breed:"Mixed Breed",        vaccinated:"Yes", neutered:"Yes",       goodWith:"Everyone"},
  {name:"Oliver",   age:"4 years",  gender:"Male",   personality:"Calm & Loving",          status:"pending",   emoji:"🐈‍⬛", color:"#EDE5DF", description:"Oliver is a mature gentleman who knows what he wants — a peaceful home with lots of love. He's been through hard times and is looking for his forever family to retire with.", weight:"5.2 kg", color_coat:"Orange Tabby",   breed:"Domestic Shorthair", vaccinated:"Yes", neutered:"Yes",       goodWith:"Quiet Homes"},
  {name:"Luna",     age:"6 months", gender:"Female", personality:"Energetic & Playful",    status:"available", emoji:"😺",   color:"#E8D5F0", description:"Luna is a bundle of joy! This young kitten has endless energy and loves to chase anything that moves. She's looking for an active family that can keep up with her playful antics.", weight:"2.5 kg", color_coat:"Gray",           breed:"Russian Blue Mix",   vaccinated:"Yes", neutered:"Scheduled", goodWith:"Active Families, Kids"},
  {name:"Shadow",   age:"3 years",  gender:"Male",   personality:"Independent & Mysterious",status:"available", emoji:"🖤",   color:"#D4D0CC", description:"Shadow is a sleek black cat with a mysterious personality. He's independent but shows affection on his own terms. Perfect for someone who appreciates a cat with character.", weight:"4.8 kg", color_coat:"Black",          breed:"Bombay Mix",         vaccinated:"Yes", neutered:"Yes",       goodWith:"Adults, Experienced Cat Owners"},
  {name:"Bella",    age:"5 years",  gender:"Female", personality:"Sweet & Gentle",         status:"available", emoji:"🌸",   color:"#F5E0D5", description:"Bella is a graceful lady who has been through hard times but never lost her sweet nature. She's looking for a quiet home where she can spend her golden years being pampered.", weight:"3.5 kg", color_coat:"Cream & White",  breed:"Persian Mix",        vaccinated:"Yes", neutered:"Yes",       goodWith:"Seniors, Quiet Homes"},
  {name:"Pumpkin",  age:"6 months", gender:"Male",   personality:"Energetic & Playful",    status:"available", emoji:"🎃",   color:"#F5E5C8", description:"Pumpkin is a mischievous kitten full of boundless energy! He enjoys climbing, chasing feather toys, and pouncing on anything that moves.", weight:"2.3 kg", color_coat:"Orange",         breed:"Domestic Shorthair", vaccinated:"Yes", neutered:"No",        goodWith:"Children, Active Homes"},
  {name:"Snowball", age:"2 years",  gender:"Female", personality:"Friendly & Social",      status:"available", emoji:"⛄",   color:"#EAF0F8", description:"Snowball loves meeting new people and will happily greet anyone who enters the room. She enjoys being brushed and pampered like a queen.", weight:"3.9 kg", color_coat:"White",          breed:"Persian Mix",        vaccinated:"Yes", neutered:"Yes",       goodWith:"Everyone"}
];

function buildCats() {
  const grid = document.getElementById('catsGrid');
  if (!grid) return;
  /* Show first 4 available on homepage */
  cats.filter(c => c.status === 'available').slice(0, 4).forEach((cat, i) => {
    const idx  = cats.indexOf(cat);
    const card = document.createElement('div');
    card.className = 'cat-card';
    card.innerHTML = `
      <div class="cat-img" style="background:linear-gradient(135deg,${cat.color},${cat.color}dd);">
        <div style="font-size:4rem">${cat.emoji}</div>
        <div class="status-badge status-available">Available</div>
      </div>
      <div class="cat-info">
        <div class="cat-row">
          <div class="cat-name">${cat.name}</div>
          <div class="cat-age">${cat.age}</div>
        </div>
        <div class="cat-gender">${cat.gender}</div>
        <div class="cat-personality">${cat.personality}</div>
        <button class="cat-btn" onclick="showCat(${idx})">Meet ${cat.name} →</button>
      </div>`;
    grid.appendChild(card);
  });
}

function showCat(i) {
  const cat = cats[i];
  document.getElementById('modalContent').innerHTML = `
    <div class="modal-header">
      <button class="modal-close" onclick="closeModal()">✕</button>
      <h2>${cat.name}</h2>
      <p>${cat.age} · ${cat.gender} · ${cat.personality}</p>
    </div>
    <div class="modal-body">
      <div class="modal-section">
        <div class="modal-section-title">📸 Photos</div>
        <div class="modal-gallery">
          ${[0,1,2].map(() => `<div class="gallery-item" style="background:linear-gradient(135deg,${cat.color},${cat.color}cc)">${cat.emoji}</div>`).join('')}
        </div>
      </div>
      <div class="modal-section">
        <div class="modal-section-title">💛 About ${cat.name}</div>
        <p class="modal-desc">${cat.description}</p>
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
      <button class="modal-adopt-btn" onclick="alert('Thank you for your interest in adopting ${cat.name}! 🐱❤️\\n\\nOur adoption team will be in touch shortly.')">🏠 Adopt ${cat.name}</button>
    </div>`;
  document.getElementById('catModal').classList.add('open');
  document.body.style.overflow = 'hidden';
}

function closeModal(e) {
  if (!e || e.target === document.getElementById('catModal')) {
    document.getElementById('catModal').classList.remove('open');
    document.body.style.overflow = '';
  }
}

document.addEventListener('keydown', e => { if (e.key === 'Escape') closeModal(); });
document.addEventListener('DOMContentLoaded', buildCats);
