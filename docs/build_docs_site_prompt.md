# Prompt: Build a Markdown Docs Site for Neocities

Build a static documentation site that renders markdown files from a `docs/` folder. It will be hosted on Neocities (static hosting only — no server, no build step, no Node.js).

---

## What it needs to do

- Read `.md` files from the `docs/` folder and render them as HTML in the browser
- Show a sidebar with links to every doc
- Render markdown using **Marked.js** (load from CDN — no install)
- Support syntax highlighting in code blocks using **Highlight.js** (CDN)
- The whole thing should be a **single `index.html` file** — no build step, no framework
- Navigating to a doc should update the URL hash (e.g. `#health_component`) so links are shareable
- The active doc should be highlighted in the sidebar
- The sidebar should have a title at the top: **"Oddside Docs"**

---

## File structure

The markdown files are in a `docs/` folder alongside `index.html`:

```
docs/
  README.md                  ← shown by default on load
  health_component.md
  energy_component.md
  dice_roller_component.md
  enemy_class.md
  boss_enemy_class.md
  grid_mover_component.md
  enemy_movement_patterns.md
  level_state_system.md
  items_and_abilities.md
  map_system.md
index.html
```

The list of docs and their sidebar labels should be defined as a JS array at the top of the script so it's easy to add new files later.

---

## Style

This page is part of an existing website called **Sluggerpunk Arcade**. It must match the site's CRT terminal aesthetic exactly. The relevant files are `style.css`, `nav.js`, and `theme.js` — read them before writing any code.

Key things to match:
- Use the existing `style.css` (linked as `style.css?v=4`) — do not write new base styles, extend it only where needed
- Wrap the page in `.crt-shell > .screen` exactly like every other page on the site
- Include `<script src="theme.js"></script>` in `<head>` and `<nav id="site-nav"></nav><script src="nav.js"></script>` for the nav
- Add a `docs` entry to `nav.js` pointing to `docs.html` so it appears in the nav on every page
- Use CSS variables from the theme (`--phosphor`, `--phosphor-dim`, `--phosphor-muted`, `--bg`, etc.) for all colors — no hardcoded hex values
- Font is `Share Tech Mono` (already loaded by style.css)
- The sidebar should feel like a file tree in a terminal — bracket-style links like `[ health_component ]`, active item highlighted with `--phosphor`
- Code blocks should use the phosphor color on dark background, matching the site's existing card style
- The page title in the topbar should read `ODDSIDE DOCS<span class="cursor"></span>`
- Output as a single file named `docs.html` placed alongside the other `.html` files in the site root

---

## Constraints

- **No build step** — must work by just opening `index.html` in a browser or uploading to Neocities as-is
- **No npm, no bundler, no backend**
- CDN libraries only (Marked.js, Highlight.js)
- Must work with `fetch()` — so it needs to be served over HTTP, not opened as a local file (Neocities handles this)
- `README.md` should load by default if no hash is present in the URL
