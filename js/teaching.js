function chevron(open) {
  return `<svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"
    style="transition:transform 0.2s;transform:rotate(${open ? 180 : 0}deg)">
    <path d="M2 4l4 4 4-4"/>
  </svg>`;
}

function buildCard(c, ci) {
  const card = document.createElement('div');
  card.className = 'course-card';

  const bookEl = c.bookUrl
    ? `<img class="book-img" src="${c.bookUrl}" alt="${c.name} textbook"
         onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
       <div class="book-placeholder" style="display:none;background:${c.bookBg};"></div>`
    : `<div class="book-placeholder" style="background:${c.bookBg};"></div>`;

  card.innerHTML = `
    <div class="card-top">
      <div class="course-code" style="color:${c.codecolor};">${c.code}</div>
      <div class="course-name">${c.name}</div>
    </div>

    <div class="intro-row">
      <div class="book-cover">${bookEl}</div>
      <div class="intro-col">
        <div class="intro-text">${c.intro}</div>
        <a class="syllabus-link" href="${c.syllabus}" target="_blank"> Syllabus</a>
      </div>
    </div>

    <div class="card-footer">
      <button class="toggle-btn" id="btn-${ci}">${chevron(false)} Lecture slides (${c.lectures.length})</button>
    </div>

    <div class="lectures-list hidden" id="lec-${ci}">
      ${c.lectures.map((l, i) => `
        <div class="lec-row">
          <span class="lec-num">${String(i + 1).padStart(2, '0')}</span>
          <span class="lec-title">${l.title}</span>
          <a class="lec-dl" href="${l.slides}" target="_blank">slides</a>
        </div>`).join('')}
    </div>`;

  return card;
}

function attachToggle(ci, lectureCount) {
  const btn = document.getElementById(`btn-${ci}`);
  const list = document.getElementById(`lec-${ci}`);
  let open = false;
  btn.addEventListener('click', () => {
    open = !open;
    list.classList.toggle('hidden', !open);
    btn.innerHTML = `${chevron(open)} ${open ? 'Hide' : 'Lecture slides'} (${lectureCount})`;
  });
}

function buildCards(courses) {
  const container = document.getElementById('cards');
  courses.forEach((c, ci) => {
    container.appendChild(buildCard(c, ci));
    attachToggle(ci, c.lectures.length);
  });
}

fetch('update/teaching.json')
  .then(res => res.json())
  .then(buildCards)
  .catch(err => {
    document.getElementById('cards').innerHTML =
      `<p class="error-msg">Failed to load courses.json: ${err.message}</p>`;
  });