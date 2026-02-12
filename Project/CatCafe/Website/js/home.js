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