# ai-playground.xyz

HTML/JS projects vibe-coded with local LLMs, served at https://ai-playground.xyz/.

## Add a project

1. Put the static files in `www/<slug>/`, with an `index.html` at its root.
2. Add it to `www/projects.json`:
   `{ "slug": "<slug>", "title": "My project", "description": "One line." }`
3. Push to `main`. GitHub Actions deploys `www/` to the server.

Use relative asset paths (`./app.js`, not `/app.js`): each project lives under
`/<slug>/`. Projects share one origin, so they also share `localStorage`, cookies
and IndexedDB; prefix storage keys with the slug. Never commit API keys: everything
in `www/` is public.

## Preview locally

    python3 -m http.server -d www 8000
