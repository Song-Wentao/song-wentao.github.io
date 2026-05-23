/* ==============================================
   MEOWTUAL LOVE — cafe.js
   ============================================== */

const MENU = [
  {emoji:'☕', name:'Purr-fect Latte',    cat:'Coffee', price:'$5.50'},
  {emoji:'🍵', name:'Meow-cha Matcha',    cat:'Tea',    price:'$6.00'},
  {emoji:'☕', name:'Kitty Cappuccino',   cat:'Coffee', price:'$5.00'},
  {emoji:'🍪', name:'Catnip Cookies',     cat:'Treats', price:'$3.50'},
  {emoji:'🧇', name:'Whisker Waffles',    cat:'Food',   price:'$8.00'},
  {emoji:'🍽️',name:'Paw-stry Platter',   cat:'Treats', price:'$12.00'},
  {emoji:'🥐', name:'Tabby Toast',        cat:'Food',   price:'$7.50'},
  {emoji:'🍫', name:'Choco-cat Brownie',  cat:'Treats', price:'$4.00'},
];

document.addEventListener('DOMContentLoaded', () => {
  const grid = document.getElementById('menuGrid');
  if (!grid) return;
  MENU.forEach(item => {
    const el = document.createElement('div');
    el.className = 'menu-item';
    el.innerHTML = `
      <div class="menu-item-left">
        <div class="menu-emoji-wrap">${item.emoji}</div>
        <div>
          <div class="menu-item-name">${item.name}</div>
          <div class="menu-item-cat">${item.cat}</div>
        </div>
      </div>
      <div class="menu-price">${item.price}</div>`;
    grid.appendChild(el);
  });
});
