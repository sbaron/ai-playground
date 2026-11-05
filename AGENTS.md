# ai-playground.xyz

Monorepo of static projects. Whatever is in `www/` on `main` is what is live.

| Path | Purpose |
| --- | --- |
| `www/` | Site root, synced to the server with `rsync --delete`. |
| `www/<slug>/` | One project each. See README for how to add one. |
| `www/projects.json` | Project list rendered by the landing page. |
| `ai-playground.nginx` | Server config. Not deployed automatically. |
| `.github/workflows/deploy.yml` | Deploys `www/` on push to `main`. |

## Server

- nbg1 hosts other production sites. Run `nginx -t` before every reload, and
  never edit their vhosts.
- `deploy` is shared with those sites. This repo has its own key, restricted to
  `rrsync /var/www/ai-playground`. Never use it elsewhere.
- Repository secrets: `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS`.
- nginx config change: copy `ai-playground.nginx` to
  `/etc/nginx/sites-available/ai-playground`, `nginx -t`, then reload.
- Do not use `add_header` inside a `location`: it drops the server-level headers.
