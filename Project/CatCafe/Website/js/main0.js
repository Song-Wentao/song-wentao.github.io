fetch("/data/cats.json")
  .then(response => response.json())
  .then(cats => {
    const container = document.getElementById("cat-list");
    if (!container) return;

    if (cats.length === 0) {
      catList.innerHTML = "<p>No cats available right now.</p>";
    }


    cats.forEach(cat => {
      const card = document.createElement("div");
      card.className = "cat-card";

      card.innerHTML = `
        <img src="${cat.image}" alt="${cat.name}">
        <h3>${cat.name}</h3>
        <p>${cat.age}</p>
        <p>${cat.description}</p>
      `;

      container.appendChild(card);
    });
  });

  
fetch("/data/blog.json")
  .then(response => response.json())
  .then(stories => {
    const container = document.getElementById("stories-list");
    if (!container) return;

    // Clear existing content
    container.innerHTML = "";

    // Bonus: no stories
    if (stories.length === 0) {
      container.innerHTML = "<p>No stories available yet.</p>";
      return;
    }

    stories.forEach(story => {
      const article = document.createElement("article");
      article.className = "story";

      // Title & date
      let html = `
        <h2>${story.title}</h2>
        <p class="date">Posted on ${story.date}</p>
      `;

      // Media (image / video)
      if (story.type === "image") {
        html += `<img src="${story.media}" alt="${story.title}">`;
      } else if (story.type === "video") {
        html += `
          <video controls>
            <source src="${story.media}" type="video/mp4">
          </video>
        `;
      }

      // Paragraphs
      story.content.forEach(paragraph => {
        html += `<p>${paragraph}</p>`;
      });

      article.innerHTML = html;
      container.appendChild(article);
    });
  })
  .catch(error => {
    console.error("Error loading stories:", error);
  });
