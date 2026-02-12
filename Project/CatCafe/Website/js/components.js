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


function loadComponent(targetId, file) {
    fetch(`/Project/CatCafe/Website/components/${file}`)
        .then(response => response.text())
        .then(html => {
            document.getElementById(targetId).innerHTML = html;
        });
}
