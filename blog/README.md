# Blog subpage

A self-contained blog page for your site: left third is a list of entries, right two-thirds is the article. Clicking an entry swaps the article on the right; each article ends with Previous / Next buttons.

## Files

```
blog/
├── blog.html          the page itself
├── css/
│   ├── global.css     your existing site stylesheet (copied in as-is)
│   └── blog.css        blog-specific layout and styling, built on your existing tokens
├── js/
│   └── blog.js         loads articles.json, renders the list, loads markdown, handles nav
├── data/
│   └── articles.json   the list of posts (order = reading order for prev/next)
└── articles/
    ├── welcome-to-the-blog.md
    ├── field-notes-on-tide-pools.md
    └── reading-list-spring.md
```

## How to add a new post

1. Write the post as a markdown file in `articles/`, e.g. `articles/my-new-post.md`. Use standard markdown — headings (`##`), images (`![alt](path)`), links, blockquotes, lists. A "## References" heading at the bottom works well for citations/sources.
2. Add one entry to `data/articles.json`:

```json
{
  "id": "my-new-post",
  "title": "My new post",
  "date": "2026-04-01",
  "category": "Notes",
  "excerpt": "One sentence teaser shown in the list on the left.",
  "cover": "img/blog/my-new-post-cover.jpg",
  "file": "articles/my-new-post.md"
}
```

- `id` — used in the URL (`blog.html#my-new-post`) and must be unique.
- `cover` — optional. Leave as `""` to skip the header image.
- The **order of entries in `articles.json` is the reading order** used for Previous/Next — put newest last or first, whichever direction you want "Next" to move.

No build step. Save the files and refresh.

## Photos

Drop images in `img/blog/` (or wherever you like) and reference them either as the `cover` field in `articles.json`, or inline in the markdown body with `![alt text](img/blog/photo.jpg)`.

## Integrating into your existing site

- I copied your `global.css` into `blog/css/` so the fonts, colors, and `:root` variables match. If your real site already links `global.css` from a shared location, just point `blog.html`'s `<link>` at that path instead of the local copy, and delete the copy here.
- Add a nav link to `blog.html` from your existing header/nav include.
- `blog.css` reuses your existing tokens (`--main-color`, `--text-color`, `--cap-color`, `--h3-font`, `--p-font`, etc.) and the same glass-panel look as your `teaching.css` cards, so it should sit visually consistent with the rest of the site without further tweaking.

## One important note on hosting

`blog.js` uses `fetch()` to load `articles.json` and the `.md` files. Browsers block `fetch` on `file://` pages for security reasons, so this needs to be served over `http(s)://` — any static host (GitHub Pages, Netlify, your existing server) works fine. For local testing, run a tiny local server from the `blog/` folder, e.g.:

```
python3 -m http.server 8000
```

then open `http://localhost:8000/blog.html`.
