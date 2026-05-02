function chevron(open) {
  return `<svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"
    style="transition:transform 0.2s;transform:rotate(${open ? 180 : 0}deg)">
    <path d="M2 4l4 4 4-4"/>
  </svg>`;
}

function buildCard(c, ci) {
  const card = document.createElement('div');
  card.className = 'course-card';

  card.innerHTML = `
    <div class="card-top">
      <div class="course-name">${c.name}</div>
    </div>


    <div class="card-footer">
      <button class="toggle-btn" id="btn-${ci}">${chevron(false)} Show (${c.lectures.length})</button>
    </div>

    <div class="lectures-list hidden" id="lec-${ci}">
      ${c.lectures.map((l, i) => `
        <div class="lec-row">
          <span class="lec-title">${l.title}</span>
          <a class="lec-dl" href="${l.slides}" target="_blank">Go to</a>
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
    btn.innerHTML = `${chevron(open)} ${open ? 'Hide' : 'Show'} (${lectureCount})`;
  });
}

function buildCards(courses) {
  const container = document.getElementById('cards');
  courses.forEach((c, ci) => {
    container.appendChild(buildCard(c, ci));
    attachToggle(ci, c.lectures.length);
  });
}

fetch('files.json')
  .then(res => res.json())
  .then(buildCards)
  .catch(err => {
    document.getElementById('cards').innerHTML =
      `<p class="error-msg">Failed to load courses.json: ${err.message}</p>`;
  });