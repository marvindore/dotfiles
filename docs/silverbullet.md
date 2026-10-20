# SilverBullet

Generic config is in the public repo `https://github.com/marvindore/silverbullet-config`. Private data is not in that repo. This page tells you how each host gets the config, and where the private data goes.

## Reference: private data

| Item | Home server | Work Mac |
|---|---|---|
| `SB_USER` (`user:password`) | Portainer stack variable. Required. | Not set. The port is local only. |
| `SPACE_PATH` | Portainer stack variable | Written by chezmoi from `silverbulletSpacePath` |
| `BIND` | Portainer stack variable | Written by chezmoi. Value: `127.0.0.1:3010`. |
| `CA_BUNDLE` | Not used | Written by chezmoi. Value: `~/docker/silverbullet/ca-certificates.pem`. |
| `CONFIG_REPO_URL` | Do not set. The default is the public repo. | Do not set. |
| `Home.md`, private tag colors, private plugs in `CONFIG.md` | The space | The space |

## Explanation: how the work Mac gets the config

The work Mac has no manual steps. The script `.chezmoiscripts/run_after_start-silverbullet.sh.tmpl` runs on every `chezmoi apply`. It always syncs the repo and writes `.env`. It deploys only when something changed. It does these steps:

0. It uses the Docker that already runs, for example Docker Desktop. It starts colima only when no Docker daemon answers. Colima does not need to be installed if Docker already runs.
1. It clones the public repo to `~/docker/silverbullet-config`, or, if the clone exists, fetches and resets it to the remote. This is a deploy-only clone, so local edits there are lost. A failed update only gives a warning.
2. It exports the macOS certificates to `~/docker/silverbullet/ca-certificates.pem`, if the file does not exist.
3. It writes `deploy/.env` from the chezmoi data. The values are not secret, so no `.env` is committed or typed by hand.
4. It decides if a deploy is needed. It deploys when one of these is true: the commit SHA of the repo changed (a force push counts), the `.env` content changed, the container is not running, the last image pull is 7 or more days old, or you set `SB_FORCE=1`. If none is true, it prints "up to date" and stops.
5. When it deploys, it pulls the images, runs the init container, and runs `docker compose up -d` with the work override, in the project `silverbullet`. The init container copies `Library/Local` from the public repo into the space.
6. After a successful deploy, it saves the SHA, the `.env` hash, and the pull time in `~/docker/silverbullet/.deploy-state`. A failed deploy saves nothing, so the next apply tries again.

To force a deploy, run `SB_FORCE=1 chezmoi apply`. To see the decision without a deploy, run the rendered script with `SB_DRY_RUN=1`.

The first run also removes the legacy stack. The legacy stack is the `docker-compose.yml` and `init-config.sh` that older versions of the script wrote to `~/docker/silverbullet`. The script stops that stack, then deletes those two files.

Do not put variables in `.bashrc` or `.zshrc`. Docker Compose reads `.env`, not your shell rc files. A shell variable also overrides `.env` without a warning.

## How-to: set up a new work Mac

1. Run `chezmoi init`. Select the profile `work`. Enter the space path when asked.
2. Run `chezmoi apply`.
3. Open `http://127.0.0.1:3010`.
4. Run `System: Reload` in SilverBullet.

## How-to: update the work Mac after you change the public repo

1. Push the change to the public repo.
2. Run `chezmoi apply`. The script sees the new commit, pulls the images, and copies the pages again.
3. Run `System: Reload` in SilverBullet. Space Lua and style changes need a reload.

## How-to: set up the home server

1. In Portainer, click Stacks, then Add stack. Set the build method to Repository.
2. Enter `https://github.com/marvindore/silverbullet-config.git`. Set the compose path to `deploy/docker-compose.yml`.
3. Under Environment variables, add:
   - `SB_USER`: `youruser:yourpassword`
   - `SPACE_PATH`: the server path of your space, for example `/srv/silverbullet/space`
   - `BIND`: `0.0.0.0:3000`, or the address your reverse proxy uses
4. Deploy the stack.
5. Run `System: Reload` in SilverBullet.

To update the server after you change the public repo, redeploy the stack in Portainer. You can also turn on the GitOps update setting. Check once that a redeploy runs the init container again. If it does not, redeploy with the Re-pull image and redeploy option.

Keep a copy of the three variable values in your password manager. A rebuilt server needs them again.

## How-to: add private pages

Put private pages in the space, outside `Library/Local`. The init container overwrites `Library/Local` each time it runs.

1. Create `Home.md`. Link to `[[Library/Local/Dashboard]]`. Add your private queries, project names, and internal URLs.
2. Add private tag colors to a page such as `Private/Tags.md`. Use a `space-style` block:

   ```space-style
   .sb-hashtag[data-tag-name="project"] {
     background: #7c3aed;
     color: white;
   }
   ```
3. Keep `CONFIG.md` in the space. Add private plugs there. The init container never changes `CONFIG.md`.

## Reference: update rules

- The init container copies `Library/Local` from the public repo each time it runs. It overwrites local edits in that folder.
- Do not put secrets or internal names in the public repo.
- To change a generic page, edit the public repo. Then update the host as described above.
