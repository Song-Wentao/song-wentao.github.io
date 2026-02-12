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