// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Add scroll effect to navigation
let lastScroll = 0;
window.addEventListener('scroll', () => {
    const nav = document.querySelector('nav');
    const currentScroll = window.pageYOffset;
    
    if (currentScroll > 100) {
        nav.style.boxShadow = '0 4px 20px rgba(0,0,0,0.15)';
    } else {
        nav.style.boxShadow = '0 2px 10px rgba(0,0,0,0.1)';
    }
    
    lastScroll = currentScroll;
});

// Heart icon toggle
document.querySelectorAll('.heart-icon').forEach(heart => {
    heart.addEventListener('click', function() {
        if (this.textContent === '♡') {
            this.textContent = '❤️';
            this.style.color = '#E89B8C';
        } else {
            this.textContent = '♡';
            this.style.color = 'black';
        }
    });
});

// Chat bubble interaction
const chatBubble = document.querySelector('.chat-bubble');
if (chatBubble) {
    chatBubble.addEventListener('click', () => {
        alert('Thanks for your interest! Visit us at 123 Whisker Lane to meet our cats! 🐱');
    });
}



// Home Cat update
fetch("/Project/CatCafe/Website/data/adoption.json")
    .then(response => response.json())
    .then(cats => {
        window.catsData = cats;
        homeCatUpdate();
    })
    .catch(error => {
        console.error('Error loading cats:', error);
    });

function homeCatUpdate() {
    const grid = document.getElementById("HomeCatsGrid");

    catsData
    .filter(cat => cat.status === "available") // only available cats
    .slice(0, 5)                               // max 4
    .forEach(cat => {
        const card = document.createElement("div");
        card.className = "adoption-cat-card";

        card.innerHTML = `
        <div class="adoption-cat-image">
            <div class="availability-badge ${cat.status}">
            Available
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
        </div>
        `;

        grid.appendChild(card);
    });
}



// Adoption Page
fetch("/Project/CatCafe/Website/data/adoption.json")
    .then(response => response.json())
    .then(cats => {
        window.catsData = cats;
        loadCatCards();
    })
    .catch(error => {
        console.error('Error loading cats:', error);
    });

function loadCatCards() {
    const grid = document.getElementById("catsGrid");
    
    catsData.forEach((cat, index) => {
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
                        onclick="showCatProfile(${index})"
                        ${cat.status === 'pending' ? 'disabled' : ''}>
                    ${cat.buttonText} →
                </button>
            </div>
        `;
        grid.appendChild(card);
    });
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
                <h3>💝 About ${cat.name}</h3>
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


















// Stories update
fetch("/Project/CatCafe/Website/data/stories.json")
    .then(res => res.json())
    .then(stories => {

    const featuredContainer = document.getElementById("featuredStory");
    const grid = document.getElementById("storiesGrid");

    // 1️⃣ Find featured story
    const featuredStory = stories.find(story => story.featured);

    if (featuredStory) {
        featuredContainer.innerHTML = `
        <div class="featured-story-image">
            <img src="${featuredStory.image}" style="width:100%; height:100%; border-radius:20px;">
        </div>

        <div class="featured-story-content">
            <div class="story-badge">Featured Story</div>
            <h2>${featuredStory.title}</h2>
            <div class="story-meta">
            <span>📅 ${featuredStory.date}</span>
            <span>❤️ ${featuredStory.category}</span>
            </div>
            <p>${featuredStory.excerpt}</p>
            <button class="btn btn-primary">Read Full Story →</button>
        </div>
        `;
    }

    // 2️⃣ Render non-featured stories
    stories
    .filter(story => !story.featured)
    .forEach(story => {
        const card = document.createElement("div");
        card.className = "story-card";

        card.innerHTML = `
        <div class="story-card-image">
        <div class="story-category ${story.categoryClass}">
        ${story.category}
        </div>
        <img src="${story.image}" style="width:100%; height:100%;">
        </div>
    
        <div class="story-card-content">
        <div class="story-date">📅 ${story.date}</div>
        <h3>${story.title}</h3>
        <p>${story.excerpt}</p>
        <a href="#" class="story-read-more">Read More →</a>
        </div>
        `;

        grid.appendChild(card);
    });
});



// Donation amount selection
document.addEventListener('DOMContentLoaded', function() {
    const donationBtns = document.querySelectorAll('.donation-btn');
    donationBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            donationBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
        });
    });

    const frequencyBtns = document.querySelectorAll('.frequency-btn');
    frequencyBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            frequencyBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
        });
    });
});



