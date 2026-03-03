const API_BASE = window.location.hostname === "localhost"
    ? "http://localhost:5000"
    : "";  // same-origin when served via nginx proxy

let allBooks = [];
let allAuthors = [];

// ── Tab switching ──────────────────────────────────────────────────────────
function showTab(tab) {
    document.querySelectorAll(".tab-section").forEach(s => s.classList.remove("active"));
    document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));
    document.getElementById(`tab-${tab}`).classList.add("active");
    document.getElementById(`nav-${tab}`).classList.add("active");
}

// ── Fetch helpers ──────────────────────────────────────────────────────────
async function fetchJSON(path) {
    const res = await fetch(`${API_BASE}${path}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
}

// ── Books ──────────────────────────────────────────────────────────────────
function renderBooks(books) {
    const grid = document.getElementById("books-grid");
    if (!books.length) {
        grid.innerHTML = `<div class="empty-msg">No books match your search.</div>`;
        return;
    }
    grid.innerHTML = books.map(b => `
    <div class="book-card">
      <div class="book-title">${esc(b.title)}</div>
      <div class="book-author">by ${esc(b.author)}</div>
      <div class="book-meta">
        ${b.genre ? `<span class="chip">${esc(b.genre)}</span>` : ""}
        ${b.published_year ? `<span class="chip">${b.published_year}</span>` : ""}
        ${b.isbn ? `<span class="chip">ISBN: ${esc(b.isbn)}</span>` : ""}
      </div>
      ${b.description ? `<div class="book-desc">${esc(b.description)}</div>` : ""}
    </div>
  `).join("");
}

function filterBooks() {
    const q = document.getElementById("books-search").value.toLowerCase();
    const filtered = allBooks.filter(b =>
        b.title.toLowerCase().includes(q) ||
        b.author.toLowerCase().includes(q) ||
        (b.genre || "").toLowerCase().includes(q)
    );
    renderBooks(filtered);
}

async function loadBooks() {
    const grid = document.getElementById("books-grid");
    try {
        allBooks = await fetchJSON("/api/books");
        document.getElementById("books-count").textContent = allBooks.length;
        renderBooks(allBooks);
    } catch (err) {
        grid.innerHTML = `<div class="error-msg">Failed to load books: ${esc(err.message)}</div>`;
    }
}

// ── Authors ────────────────────────────────────────────────────────────────
function renderAuthors(authors) {
    const grid = document.getElementById("authors-grid");
    if (!authors.length) {
        grid.innerHTML = `<div class="empty-msg">No authors match your search.</div>`;
        return;
    }
    grid.innerHTML = authors.map(a => `
    <div class="author-card">
      <div class="author-avatar">${esc(a.name[0])}</div>
      <div class="author-name">${esc(a.name)}</div>
      <div class="author-extra">
        ${[a.nationality, a.born_year ? `b. ${a.born_year}` : ""].filter(Boolean).join(" · ")}
      </div>
      <div class="book-count-badge">📖 ${a.book_count} book${a.book_count !== 1 ? "s" : ""}</div>
      ${a.bio ? `<div class="author-bio">${esc(a.bio)}</div>` : ""}
    </div>
  `).join("");
}

function filterAuthors() {
    const q = document.getElementById("authors-search").value.toLowerCase();
    const filtered = allAuthors.filter(a =>
        a.name.toLowerCase().includes(q) ||
        (a.nationality || "").toLowerCase().includes(q)
    );
    renderAuthors(filtered);
}

async function loadAuthors() {
    const grid = document.getElementById("authors-grid");
    try {
        allAuthors = await fetchJSON("/api/authors");
        document.getElementById("authors-count").textContent = allAuthors.length;
        renderAuthors(allAuthors);
    } catch (err) {
        grid.innerHTML = `<div class="error-msg">Failed to load authors: ${esc(err.message)}</div>`;
    }
}

// ── Utility ────────────────────────────────────────────────────────────────
function esc(str) {
    if (str == null) return "";
    return String(str)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");
}

// ── Init ───────────────────────────────────────────────────────────────────
loadBooks();
loadAuthors();
