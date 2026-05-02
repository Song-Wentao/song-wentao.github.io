async function loadComponent(targetId, file) {
  const response = await fetch(`components/${file}`);
  const html = await response.text();
  document.getElementById(targetId).innerHTML = html;
}

async function init() {
  // Load all components first
  await loadComponent("navbar", "navbar.html");
  await loadComponent("login", "login.html"); 
  await loadComponent("footer", "footer.html");

  const header = document.querySelector("header");
  const navUl = document.querySelector('header .navigation ul');

  // Sticky header on scroll
  window.addEventListener("scroll", function() {
    header.classList.toggle("sticky", window.scrollY > 10);
    
    // Reset hamburger and close menu on scroll
    document.querySelector('header').classList.remove('menu-open');
  });

  // Hamburger toggle
  document.getElementById('hamburger').addEventListener('click', () => {
    document.querySelector('header').classList.toggle('menu-open');
  });

  // Login popup
  const wrapper = document.querySelector('.wrapper');
  const btnPopup = document.querySelector('.btnLogin-popup');
  const iconClose = document.querySelector('.icon-close');
  
  btnPopup.addEventListener('click',()=> {
    wrapper.classList.add('active-popup');
  });
  
  iconClose.addEventListener('click',()=> {
    wrapper.classList.remove('active-popup');
  });
}

init(); // run everything






