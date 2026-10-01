/*-----blog-----*/
(function () {
  const DATA_URL = "update/blog.json";

  const tocList = document.getElementById("tocList");
  const articleContent = document.getElementById("articleContent");
  const prevBtn = document.getElementById("prevBtn");
  const nextBtn = document.getElementById("nextBtn");

  let articles = [];
  let currentIndex = -1;

  // ---------- tiny built-in markdown parser (no external dependency) ----------
  function escapeHtml(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  function inlineMd(text) {
    // code spans first so their contents aren't touched by other rules
    text = text.replace(/`([^`]+)`/g, (_, code) => `<code>${escapeHtml(code)}</code>`);
    // images
    text = text.replace(/!\[([^\]]*)\]\(([^)\s]+)(?:\s+"([^"]*)")?\)/g,
      (_, alt, src, title) => `<img src="${src}" alt="${alt}"${title ? ` title="${title}"` : ""}>`);
    // links
    text = text.replace(/\[([^\]]+)\]\(([^)\s]+)(?:\s+"([^"]*)")?\)/g,
      (_, label, href, title) => `<a href="${href}"${title ? ` title="${title}"` : ""} target="_blank" rel="noopener">${label}</a>`);
    // bold + italic
    text = text.replace(/\*\*\*(.+?)\*\*\*/g, "<strong><em>$1</em></strong>");
    text = text.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>");
    text = text.replace(/(^|[^*])\*(?!\*)([^*]+?)\*(?!\*)/g, "$1<em>$2</em>");
    return text;
  }

  function renderMarkdown(md) {
    const lines = md.replace(/\r\n/g, "\n").split("\n");
    let html = "";
    let i = 0;
    let inCodeBlock = false;
    let codeBuffer = [];
    let listType = null; // "ul" | "ol" | null
    let inBlockquote = false;

    function closeList() {
      if (listType) {
        html += listType === "ul" ? "</ul>" : "</ol>";
        listType = null;
      }
    }
    function closeBlockquote() {
      if (inBlockquote) {
        html += "</blockquote>";
        inBlockquote = false;
      }
    }

    while (i < lines.length) {
      const line = lines[i];

      // fenced code blocks
      if (/^```/.test(line)) {
        if (!inCodeBlock) {
          closeList();
          closeBlockquote();
          inCodeBlock = true;
          codeBuffer = [];
        } else {
          html += `<pre><code>${escapeHtml(codeBuffer.join("\n"))}</code></pre>`;
          inCodeBlock = false;
        }
        i++;
        continue;
      }
      if (inCodeBlock) {
        codeBuffer.push(line);
        i++;
        continue;
      }

      // blank line
      if (/^\s*$/.test(line)) {
        closeList();
        closeBlockquote();
        i++;
        continue;
      }

      // horizontal rule
      if (/^\s*(-{3,}|\*{3,}|_{3,})\s*$/.test(line)) {
        closeList();
        closeBlockquote();
        html += "<hr>";
        i++;
        continue;
      }

      // headings
      const heading = line.match(/^(#{1,6})\s+(.*)$/);
      if (heading) {
        closeList();
        closeBlockquote();
        const level = heading[1].length;
        html += `<h${level}>${inlineMd(heading[2])}</h${level}>`;
        i++;
        continue;
      }

      // blockquote
      const quote = line.match(/^>\s?(.*)$/);
      if (quote) {
        closeList();
        if (!inBlockquote) {
          html += "<blockquote>";
          inBlockquote = true;
        }
        html += `<p>${inlineMd(quote[1])}</p>`;
        i++;
        continue;
      }
      closeBlockquote();

      // unordered list
      const ul = line.match(/^\s*[-*+]\s+(.*)$/);
      if (ul) {
        if (listType !== "ul") {
          closeList();
          html += "<ul>";
          listType = "ul";
        }
        html += `<li>${inlineMd(ul[1])}</li>`;
        i++;
        continue;
      }

      // ordered list
      const ol = line.match(/^\s*\d+\.\s+(.*)$/);
      if (ol) {
        if (listType !== "ol") {
          closeList();
          html += "<ol>";
          listType = "ol";
        }
        html += `<li>${inlineMd(ol[1])}</li>`;
        i++;
        continue;
      }

      closeList();

      // paragraph (collect consecutive plain lines)
      let para = [line];
      i++;
      while (
        i < lines.length &&
        !/^\s*$/.test(lines[i]) &&
        !/^```/.test(lines[i]) &&
        !/^(#{1,6})\s+/.test(lines[i]) &&
        !/^>\s?/.test(lines[i]) &&
        !/^\s*[-*+]\s+/.test(lines[i]) &&
        !/^\s*\d+\.\s+/.test(lines[i]) &&
        !/^\s*(-{3,}|\*{3,}|_{3,})\s*$/.test(lines[i])
      ) {
        para.push(lines[i]);
        i++;
      }
      html += `<p>${inlineMd(para.join(" "))}</p>`;
    }

    closeList();
    closeBlockquote();
    if (inCodeBlock) {
      html += `<pre><code>${escapeHtml(codeBuffer.join("\n"))}</code></pre>`;
    }
    return html;
  }

  function formatDate(iso) {
    const d = new Date(iso + "T00:00:00");
    if (isNaN(d)) return iso;
    return d.toLocaleDateString(undefined, {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  function renderToc() {
    tocList.innerHTML = "";
    articles.forEach((a, i) => {
      const li = document.createElement("li");
      const btn = document.createElement("button");
      btn.className = "toc-item";
      btn.setAttribute("data-index", i);
      btn.innerHTML = `
        <span class="toc-date">${formatDate(a.date)} · ${a.category || ""}</span>
        <span class="toc-title">${a.title}</span>
        <span class="toc-excerpt">${a.excerpt || ""}</span>
      `;
      btn.addEventListener("click", () => loadArticle(i, true));
      li.appendChild(btn);
      tocList.appendChild(li);
    });
  }

  function setActiveToc(index) {
    const items = tocList.querySelectorAll(".toc-item");
    items.forEach((item) => item.classList.remove("active"));
    const active = tocList.querySelector(`.toc-item[data-index="${index}"]`);
    if (active) active.classList.add("active");
  }

  function updateNavButtons() {
    const prev = articles[currentIndex - 1];
    const next = articles[currentIndex + 1];

    prevBtn.disabled = !prev;
    nextBtn.disabled = !next;

    prevBtn.innerHTML = prev
      ? `<span class="nav-label">← Previous</span><span class="nav-title">${prev.title}</span>`
      : `<span class="nav-label">← Previous</span>`;

    nextBtn.innerHTML = next
      ? `<span class="nav-label">Next →</span><span class="nav-title">${next.title}</span>`
      : `<span class="nav-label">Next →</span>`;
  }

  async function loadArticle(index, updateHash) {
    const meta = articles[index];
    if (!meta) return;
    currentIndex = index;
    setActiveToc(index);
    updateNavButtons();

    if (updateHash) {
      history.replaceState(null, "", "#" + meta.id);
    }

    articleContent.innerHTML = `<p class="article-loading">Loading…</p>`;

    try {
      const res = await fetch(meta.file);
      if (!res.ok) throw new Error("Could not load article file");
      const mdText = await res.text();
      const html = renderMarkdown(mdText);

      articleContent.innerHTML = `
        ${meta.cover ? `<img class="article-cover" src="${meta.cover}" alt="${meta.title}">` : ""}
        <span class="article-eyebrow">${meta.category || ""}</span>
        <h2 class="article-title">${meta.title}</h2>
        <span class="article-date">${formatDate(meta.date)}</span>
        <div class="article-body">${html}</div>
      `;
    } catch (err) {
      articleContent.innerHTML = `<p class="article-error">This article couldn't be loaded. (${err.message})</p>`;
    }

    // scroll article panel into view on mobile when picking from the list
    if (window.innerWidth <= 1185) {
      document.getElementById("articleView").scrollIntoView({ behavior: "smooth", block: "start" });
    }
  }

  function indexFromHash() {
    const id = location.hash.replace("#", "");
    if (!id) return 0;
    const i = articles.findIndex((a) => a.id === id);
    return i === -1 ? 0 : i;
  }

  prevBtn.addEventListener("click", () => {
    if (currentIndex > 0) loadArticle(currentIndex - 1, true);
  });
  nextBtn.addEventListener("click", () => {
    if (currentIndex < articles.length - 1) loadArticle(currentIndex + 1, true);
  });

  window.addEventListener("hashchange", () => {
    const i = indexFromHash();
    if (i !== currentIndex) loadArticle(i, false);
  });

  async function init() {
    try {
      const res = await fetch(DATA_URL);
      articles = await res.json();
    } catch (err) {
      articleContent.innerHTML = `<p class="article-error">Couldn't load the article list (${err.message}).</p>`;
      return;
    }
    renderToc();
    loadArticle(indexFromHash(), false);
  }

  init();
})();
