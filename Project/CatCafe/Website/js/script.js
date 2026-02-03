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
            const grid = document.getElementById("HomeCatsGrid");
    
            cats
            .filter(cat => cat.status === "available") // only available cats
            .slice(0, 3)                               // max 3
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
                <button class="adoption-meet-btn ${cat.buttonStyle}">
                ${cat.buttonText} →
                </button>
                </div>
                `;
        
                grid.appendChild(card);
            });
        });


        // Adoption Cat update
        fetch("/Project/CatCafe/Website/data/adoption.json")
          .then(response => response.json())
          .then(cats => {
            const grid = document.getElementById("catsGrid");
    
            cats.forEach(cat => {
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
                      <button class="adoption-meet-btn ${cat.buttonStyle}">
                      ${cat.buttonText} →
                      </button>
                      </div>
                      `;
      
                grid.appendChild(card);
            });
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



