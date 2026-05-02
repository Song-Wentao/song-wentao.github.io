# Chen Lab Website

A multi-page static website for the Chen Lab (Cardiac Physiology & Electrophysiology).

## File Structure

```
lab-site/
├── index.html            ← About / Home page
├── people.html           ← PI, current members, alumni
├── publication.html      ← Publications (filterable by year)
├── projects.html         ← Research projects
├── opportunities.html    ← Join us / open positions
│
├── css/
│   ├── style.css         ← Global styles, variables, shared components
│   ├── navbar.css        ← Navbar styles (shared across all pages)
│   └── animations.css    ← Animation utility class
│
├── data/
│   └── lab.js            ← ★ ALL CONTENT LIVES HERE — edit to update the site
│
├── img/
│   ├── README.md         ← Photo naming guide
│   └── (place photos here)
│
├── js/
│   └── utils.js          ← Shared JS: injectNavbar(), injectFooter(), helpers
│
└── components/           ← Reserved for future reusable HTML snippets
```

## How to Update Content

**Every piece of text, every name, every publication** is stored in `data/lab.js`.
Open that file and edit the relevant section — no HTML knowledge required.

| What you want to change      | Where in lab.js              |
|------------------------------|------------------------------|
| Lab name, email, address     | Top of file (identity block) |
| Hero tagline & mission       | `tagline`, `mission`         |
| News items                   | `news` array                 |
| PI info                      | `pi` object                  |
| Current members              | `members` array              |
| Alumni                       | `alumni` array               |
| Publications                 | `publications` array         |
| Research projects            | `projects` array             |
| Open positions               | `positions` array            |
| Lab values                   | `values` array               |

## Adding a Photo

1. Put the photo in `img/` (e.g. `img/pi.jpg`)
2. In `data/lab.js`, set the `photo` field to `"img/pi.jpg"`
3. Refresh the page — done.

## Running Locally

Open any `.html` file directly in a browser, or use a simple server:

```bash
# Python 3
python -m http.server 8000
# then open http://localhost:8000
```

No build step, no dependencies, no frameworks.
