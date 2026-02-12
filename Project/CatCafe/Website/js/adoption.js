// ===== PAGINATION VARIABLES =====
let currentPage = 1;
const catsPerPage = 8; // Number of cats to show per page

// Adoption Page with Pagination
fetch("/Project/CatCafe/Website/data/adoption.json")
    .then(response => response.json())
    .then(cats => {
        window.catsData = cats;
        loadCatCards();
        setupPagination();
    })
    .catch(error => {
        console.error('Error loading cats:', error);
    });

function loadCatCards() {
    const grid = document.getElementById("catsGrid");
    if (!grid) return; // Only run on adoption page
    
    // Clear existing cards
    grid.innerHTML = '';
    
    // Calculate pagination
    const startIndex = (currentPage - 1) * catsPerPage;
    const endIndex = startIndex + catsPerPage;
    const catsToShow = catsData.slice(startIndex, endIndex);
    
    // Render cats for current page
    catsToShow.forEach((cat, index) => {
        const actualIndex = startIndex + index; // Get the actual index in the full array
        const card = document.createElement("div");
        card.className = "adoption-cat-card";
        card.innerHTML = `
            <div class="adoption-cat-image">
                <div class="availability-badge ${cat.status}">
                    ${cat.status === "available" ? "Available" : "Pending"}
                </div>
                <img src="${cat.image}" alt="${cat.name}">
            </div>
            <div class="adoption-cat-info">
                <div class="adoption-cat-header">
                    <h3 class="adoption-cat-name">${cat.name}</h3>
                    <span class="adoption-cat-age">${cat.age}</span>
                </div>
                <p class="adoption-cat-gender">${cat.gender}</p>
                <p class="adoption-cat-personality">${cat.personality}</p>
                <button class="adoption-meet-btn ${cat.buttonStyle}" 
                        onclick="showCatProfile(${actualIndex})"
                        ${cat.status === 'pending' ? 'disabled' : ''}>
                    ${cat.buttonText} →
                </button>
            </div>
        `;
        grid.appendChild(card);
    });
    
    updatePaginationControls();
}

function setupPagination() {
    const prevBtn = document.getElementById('prevPage');
    const nextBtn = document.getElementById('nextPage');
    
    if (!prevBtn || !nextBtn) return; // Only run on adoption page
    
    prevBtn.addEventListener('click', () => {
        if (currentPage > 1) {
            currentPage--;
            loadCatCards();
            scrollToTop();
        }
    });
    
    nextBtn.addEventListener('click', () => {
        const totalPages = Math.ceil(catsData.length / catsPerPage);
        if (currentPage < totalPages) {
            currentPage++;
            loadCatCards();
            scrollToTop();
        }
    });
}

function updatePaginationControls() {
    const totalPages = Math.ceil(catsData.length / catsPerPage);
    const prevBtn = document.getElementById('prevPage');
    const nextBtn = document.getElementById('nextPage');
    const pageInfo = document.getElementById('pageInfo');
    const dotsContainer = document.getElementById('paginationDots');
    
    if (!prevBtn || !nextBtn || !pageInfo || !dotsContainer) return;
    
    // Update page info text
    pageInfo.textContent = `Page ${currentPage} of ${totalPages}`;
    
    // Enable/disable buttons
    prevBtn.disabled = currentPage === 1;
    nextBtn.disabled = currentPage === totalPages;
    
    // Generate page dots
    dotsContainer.innerHTML = '';
    for (let i = 1; i <= totalPages; i++) {
        const dot = document.createElement('span');
        dot.className = 'page-dot' + (i === currentPage ? ' active' : '');
        dot.addEventListener('click', () => {
            currentPage = i;
            loadCatCards();
            scrollToTop();
        });
        dotsContainer.appendChild(dot);
    }
}

function scrollToTop() {
    const adoptionSection = document.getElementById('adoption-page');
    if (adoptionSection) {
        adoptionSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}



// Function to show cat profile modal
function showCatProfile(catIndex) {
    const cat = catsData[catIndex];
    if (!cat) return;

    // Create profile modal HTML
    const profileHTML = `
        <div class="profile-header">
            <h2>${cat.name}</h2>
            <p>${cat.age} • ${cat.gender} • ${cat.personality}</p>
        </div>
        <div class="profile-body">
            <!-- Photo Gallery Section -->
            <div class="profile-section">
                <h3>📸 Photo Gallery</h3>
                <div class="media-gallery">
                    ${cat.photos && cat.photos.length > 0 
                        ? cat.photos.map(photo => `
                            <div class="media-item">
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
                <div class="profile-section">
                    <h3>🎥 Videos</h3>
                    <div class="media-gallery">
                        ${cat.videos.map(video => `
                            <div class="media-item">
                                <video src="${video}" controls></video>
                            </div>
                        `).join('')}
                    </div>
                </div>
            ` : ''}

            <!-- About Section -->
            <div class="profile-section">
                <h3>💛 About ${cat.name}</h3>
                <p class="profile-description">
                    ${cat.description || `${cat.name} is a ${cat.personality.toLowerCase()} ${cat.gender.toLowerCase()} cat who is ${cat.age} old. This wonderful companion is looking for a loving forever home!`}
                </p>
            </div>

            <!-- Details Section -->
            <div class="profile-section">
                <h3>📋 Details</h3>
                <div class="info-grid">
                    <div class="info-item">
                        <div class="info-label">Age</div>
                        <div class="info-value">${cat.age}</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Gender</div>
                        <div class="info-value">${cat.gender}</div>
                    </div>
                    ${cat.weight ? `
                        <div class="info-item">
                            <div class="info-label">Weight</div>
                            <div class="info-value">${cat.weight}</div>
                        </div>
                    ` : ''}
                    ${cat.color ? `
                        <div class="info-item">
                            <div class="info-label">Color</div>
                            <div class="info-value">${cat.color}</div>
                        </div>
                    ` : ''}
                    ${cat.breed ? `
                        <div class="info-item">
                            <div class="info-label">Breed</div>
                            <div class="info-value">${cat.breed}</div>
                        </div>
                    ` : ''}
                    ${cat.vaccinated ? `
                        <div class="info-item">
                            <div class="info-label">Vaccinated</div>
                            <div class="info-value">${cat.vaccinated}</div>
                        </div>
                    ` : ''}
                    ${cat.neutered ? `
                        <div class="info-item">
                            <div class="info-label">Neutered/Spayed</div>
                            <div class="info-value">${cat.neutered}</div>
                        </div>
                    ` : ''}
                    ${cat.goodWith ? `
                        <div class="info-item">
                            <div class="info-label">Good With</div>
                            <div class="info-value">${cat.goodWith}</div>
                        </div>
                    ` : ''}
                </div>
            </div>

            <!-- Adopt Button -->
            <button class="adopt-btn" onclick="adoptCat('${cat.name}', ${catIndex})">
                🏠 Adopt ${cat.name}
            </button>
        </div>
    `;

    // Insert into modal and show
    document.getElementById('profileContent').innerHTML = profileHTML;
    document.getElementById('profileModal').style.display = 'block';
    document.body.style.overflow = 'hidden';
}

// Function to close profile modal
function closeCatProfile() {
    document.getElementById('profileModal').style.display = 'none';
    document.body.style.overflow = 'auto';
}

// Function to handle adoption
function adoptCat(catName, catIndex) {
    alert(`Thank you for your interest in adopting ${catName}! 🐱❤️\n\nOur adoption team will contact you shortly to discuss the next steps.`);
    
    // You can customize this:
    // window.location.href = `/adoption-form.html?cat=${catName}&id=${catIndex}`;
    // window.location.href = `mailto:adoptions@meowtual-love.com?subject=Adoption Inquiry for ${catName}`;
}

// Close modal when clicking outside
window.onclick = function(event) {
    const modal = document.getElementById('profileModal');
    if (event.target === modal) {
        closeCatProfile();
    }
};

// Close modal with Escape key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        const modal = document.getElementById('profileModal');
        if (modal.style.display === 'block') {
            closeCatProfile();
        }
    }
});

// Load cats when page loads
document.addEventListener('DOMContentLoaded', function() {
    loadCatCards();
});