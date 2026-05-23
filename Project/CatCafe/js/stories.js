/* ==============================================
   MEOWTUAL LOVE — stories.js
   Loads stories from JSON, renders featured +
   grid, opens full story reader modal
   ============================================== */

/* Full story bodies — keyed by story id */
const STORY_BODIES = {
  1: `<p>It was a bitter January night when our volunteers first spotted Oliver huddled beneath a dumpster near downtown Tampa. Thin, matted, and shaking, he hissed weakly as they approached — not out of aggression, but out of fear. He had clearly been alone for a long time.</p>
      <p>After a careful trap-and-transport, Oliver arrived at Meowtual Love and was examined by our veterinary partner. He was severely underweight, had a respiratory infection, and a small wound on his left ear. But his eyes — warm amber, watchful — held something that told us he hadn't given up.</p>
      <p>Recovery took eight weeks. Oliver spent the first two hiding behind his litter tray, eating only when no one was watching. Then one morning, a volunteer named Maria sat quietly on the floor beside his enclosure and read aloud. Within the hour, Oliver crept forward and rested his head on her knee.</p>
      <p>From that moment, his transformation was gradual but undeniable. He began greeting volunteers at the door. He discovered the window perch. He learned that laps were safe. By the time the Chen family walked into the cafe on a rainy Saturday, Oliver was stretched out like he owned the place — which, in every way that mattered, he did.</p>
      <p>The Chens had been looking for a calm companion for their ten-year-old daughter Lily, who has been navigating anxiety. Within minutes, Oliver had settled onto Lily's lap and begun his slow, steady purr. Three weeks later, the adoption was finalised. Oliver now sleeps at the foot of Lily's bed every night — and according to her parents, her nightmares have nearly stopped.</p>`,

  2: `<p>Tampa is home to thousands of community cats — cats that live outdoors, often in loose colonies near restaurants, parks, and residential areas. For years, the instinctive response was to remove them. Meowtual Love takes a different approach: Trap-Neuter-Vaccinate-Return, or TNVR.</p>
      <p>The principle is straightforward. Outdoor cats are humanely trapped, taken to a partner veterinary clinic to be sterilised and vaccinated, then returned to their territory. A small notch is made in the ear tip under anaesthesia — a universal marker that identifies the cat as altered.</p>
      <p>Since launching our TNVR programme in 2023, we have processed over 500 cats across 14 identified colonies in the Tampa Bay area. The results are measurable: colony sizes have stabilised, kitten litters have dropped by an estimated 70%, and the overall health of community cat populations has improved dramatically.</p>
      <p>Critically, TNVR is also humane. Sterilised cats continue to live where they are comfortable and familiar. They keep territories stable, which prevents new unaltered cats from moving in and breeding. It is not a perfect solution — no solution to a complex urban ecology problem ever is — but the data consistently shows it outperforms lethal control in both cost and long-term effectiveness.</p>
      <p>Our TNVR team currently runs two trapping nights per week, coordinated by volunteer trapper coordinators and supported entirely by donations and cafe revenue. If you would like to report a colony, volunteer as a trapper, or sponsor a surgery, please visit our contact page.</p>`,

  3: `<p>Sarah didn't set out to become a foster carer. She came to Meowtual Love two years ago to adopt a single cat — a black-and-white kitten named Inky — and left with a form that asked if she'd considered fostering. "I thought, how hard could it be?" she laughs now. "Famous last words."</p>
      <p>Fostering at Meowtual Love means taking in cats who aren't yet ready for adoption — whether because they're recovering from illness, adjusting to indoor life after living rough, or simply too young to be away from round-the-clock care. Foster carers provide a home environment, socialisation, and love while permanent placements are arranged.</p>
      <p>In two years, Sarah has fostered 23 cats. She remembers each one. There was Pretzel, who arrived feral and spent six weeks under the bed before venturing out to eat from Sarah's hand. There was a litter of four kittens — Biscuit, Gravy, Toast, and Jam — who required bottle-feeding every three hours for the first fortnight. There was Winston, a 12-year-old tom with kidney disease who needed daily fluids and lived out his last six peaceful months on Sarah's sofa.</p>
      <p>"The hardest part is the goodbye," she admits. "But then I see a photo of them in their new home, and I know that place on my sofa is free for the next one who needs it." She pauses. "Also, Inky has opinions about the fosters. He's mostly fine with kittens. Less fine with other adults. We're working on it."</p>
      <p>If you are interested in fostering, we provide all food, litter, and veterinary care. What you provide is your home, your time, and your heart. Training and full support from our team is included.</p>`,

  4: `<p>Mochi had been with us for fourteen months. That is a long time in a cat cafe — long enough that the staff had started to worry, gently, whether she was one of the ones who would stay. She was shy in the way that can be mistaken for aloofness: she didn't come to strangers, she took her time, she chose her moments.</p>
      <p>The Reinhardts — retired teachers Margaret and David — came in on a quiet Tuesday afternoon in December. They weren't sure they wanted a cat. They'd lost their previous cat, a tabby named Ptolemy, eight months earlier, and the house had felt different since.</p>
      <p>Mochi was asleep in her favourite basket by the window when they arrived. She didn't stir when the door opened. She didn't move when other cats investigated the newcomers. But twenty minutes later, as Margaret sat quietly in a chair nearby reading the adoption information leaflet, Mochi got up, walked across the room, and stepped onto her lap.</p>
      <p>Margaret described it afterwards as the cat choosing her, not the other way around. "She looked up at me," she said, "and I just thought — oh. There you are."</p>
      <p>The adoption was approved the following week. Mochi moved in on a Saturday, explored every room by Sunday morning, and was found sleeping on Ptolemy's old blanket by Sunday afternoon. David sent us a photo. We may have cried, just a little.</p>`,

  5: `<p>Every morning at 6:45am, a small team of Meowtual Love volunteers spreads across six designated feeding stations in the Greater Tampa area. They carry insulated tote bags with measured portions, fresh water in refillable containers, and a notebook to record which cats appeared, their condition, and any new faces in the colony.</p>
      <p>The community feeding programme is unglamorous, routine, and absolutely essential. For community cats — those who live outdoors and are not suitable for indoor rehoming — consistent feeding means the difference between marginal health and genuine wellbeing. It also makes TNVR work more effective: cats who associate a location with food are easier to trap humanely.</p>
      <p>The programme currently supports approximately 85 community cats across our active colonies. Each feeding station is monitored by a dedicated volunteer who knows the individual cats by name, tracks changes in their condition, and alerts the veterinary team when any cat shows signs of illness or injury.</p>
      <p>Running the programme costs roughly $600 per month in food and supplies, funded entirely by donations and a portion of cafe revenue. We are currently looking for additional feeding volunteers for the Seminole Heights and Ybor City routes. Commitment is one morning per week; full training and equipment provided.</p>
      <p>To volunteer or donate specifically to the community feeding programme, please use the contact form and select "Community Cats" as your subject.</p>`,

  6: `<p>On Saturday the 13th of December, Meowtual Love opened its doors at 9am for our annual Holiday Adoption Event — and by 5pm, fifteen cats had found their forever homes.</p>
      <p>The event had been in planning for six weeks. The cafe was decorated, the adoption fee was reduced to $50 for all cats over one year old, and we partnered with three local businesses to offer gift packages for new adopters: a starter supply kit from Whisker & Co, a vet consultation voucher from Bay Area Animal Hospital, and a handmade blanket from volunteer crafter Rosa.</p>
      <p>Doors opened to a queue. Families, couples, individuals — people who had been thinking about adoption for months and had decided the holidays were the right time. By midday, eight cats had been matched. By 3pm, thirteen. The last two — a bonded pair of grey brothers named Sage and Basil — were matched at 4:47pm, thirteen minutes before closing.</p>
      <p>Staff and volunteers stayed late to process the final paperwork. There were tears. There was a lot of laughter. Someone brought a cake. The cats who were adopted went home with name tags, welcome packs, and people who had chosen them deliberately and with care.</p>
      <p>We are already planning next year's event. If you would like to be notified when tickets are released, or if you are interested in volunteering or sponsoring, please sign up via our contact page.</p>`,
};

/* Badge class lookup */
const BADGE_MAP = {
  adoption:  'badge-adoption',
  foster:    'badge-foster',
  events:    'badge-events',
  '':        'badge-community',
};

/* Emoji lookup for fallback display */
const EMOJI_MAP = {
  adoption:  '🏠',
  foster:    '💕',
  events:    '🎄',
  '':        '✂️',
};

/* ============================================================
   LOAD + RENDER
   ============================================================ */
document.addEventListener('DOMContentLoaded', () => {
  fetch('data/stories.json')
    .then(r => r.json())
    .then(renderAll)
    .catch(() => renderAll(FALLBACK_STORIES));
});

function renderAll(stories) {
  const featured = stories.find(s => s.featured);
  const rest     = stories.filter(s => !s.featured);

  if (featured) renderFeatured(featured);
  rest.forEach(s => renderCard(s));
}

/* ---- FEATURED ---- */
function renderFeatured(s) {
  const el = document.getElementById('featuredStory');
  if (!el) return;
  const badge  = BADGE_MAP[s.categoryClass] || 'badge-community';

  el.innerHTML = `
    <div class="featured-img"><span><img src="${s.image}"></span></div>
    <div class="featured-content">
      <div class="featured-badge">&#x2728; Featured Story</div>
      <h2>${s.title}</h2>
        <div class="story-meta">
          <span>&#x1F4C5; ${s.date}</span>
          <span>&#x2764;&#xFE0F; ${s.category}</span>
        </div>
      <p> ${s.excerpt} </p>
      <button class="btn-primary" onclick="openStoryModal(${s.idx})">Read Full Story &#x2192;</button>
    </div>
    `;
}

/* ---- STORY CARDS ---- */
function renderCard(s) {
  const grid  = document.getElementById('storiesGrid');
  if (!grid) return;
  const badge = BADGE_MAP[s.categoryClass] || 'badge-community';

  const card = document.createElement('div');
  card.className = 'story-card';
  card.innerHTML = `
    <div class="story-img">
      <img src="${s.image}">
      <div class="story-cat-badge badge">${s.category}</div>
    </div>
    <div class="story-content">
      <div class="story-date">&#x1F4C5; ${s.date}</div>
      <div class="story-title">${s.title}</div>
      <div class="story-excerpt">${s.excerpt}</div>
      <button class="story-link" onclick="openStoryModal(${s.idx})">Read More &#x2192;</button>
    </div>
    `;
  grid.appendChild(card);
}

/* ============================================================
   STORY READER MODAL
   ============================================================ */
let allStories = [];

/* Keep a reference so modal can look up by id */
document.addEventListener('DOMContentLoaded', () => {
  fetch('data/stories.json')
    .then(r => r.json())
    .then(data => { allStories = data; })
    .catch(() => { allStories = FALLBACK_STORIES; });
});

function openStoryModal(id) {
  const s     = allStories.find(x => x.id === id) || allStories[0];
  if (!s) return;
  const badge = BADGE_MAP[s.categoryClass] || 'badge-community';
  const emoji = EMOJI_MAP[s.categoryClass] || '📖';
  const body  = STORY_BODIES[id] || '<p>' + s.excerpt + '</p>';

  document.getElementById('storyModalBox').innerHTML = `
    <div class="modal-header" style="background:linear-gradient(135deg,var(--charcoal),#4A3530)">
      <button class="modal-close" onclick="closeStoryModal()">&#x2715;</button>
      <h2>${s.title}</h2>
      <p>&#x1F4C5;&ensp;${s.date}</p>
    </div>
    <div class="story-hero-img"><span><img src="${s.image}"></span></div>
    <div class="modal-body">
      <div class="story-modal-meta">
        <span class="story-cat-badge badge" style="position:static"> ${s.category} </span>
        <span class="story-modal-date">Published ${s.date}</span>
      </div>
      <div class="story-modal-body">${s.body} </div>
    </div>
    `;

  document.getElementById('storyModal').classList.add('open');
  document.body.style.overflow = 'hidden';
}

function closeStoryModal(e) {
  if (!e || e.target === document.getElementById('storyModal')) {
    document.getElementById('storyModal').classList.remove('open');
    document.body.style.overflow = '';
  }
}

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') closeStoryModal();
});