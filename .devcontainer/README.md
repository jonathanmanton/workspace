# iac-k8s-bootstrap devcontainer

A devcontainer that reproduces most of the toolchain from
[`lago-morph/iac-k8s-bootstrap`'s Dockerfile](https://github.com/lago-morph/iac-k8s-bootstrap/blob/main/docker/Dockerfile).

Design: a small set of **official devcontainer Features** for the heavyweight
pieces, and a single **`onCreate.sh`** that installs the rest as quiet,
direct binary downloads. We deliberately avoid third-party `devcontainers-extra`
Features (several don't exist or are flaky) and avoid Homebrew for the toolchain
(slow: it drags in portable-ruby, python, node and icu4c just as dependencies).

## Prebuilt image (fast, reliable startup)

`.github/workflows/devcontainer-prebuild.yml` builds this devcontainer on
GitHub's runners and pushes a fully-baked image to
`ghcr.io/jonathanmanton/iac-devcontainer:latest` on every push to `main` that
touches `.devcontainer/`. Because the install logic runs as **`onCreateCommand`**
(which the prebuild captures, unlike `postCreateCommand`), the published image
already contains everything.

- **Normal use:** `devcontainer.json` sets `build.cacheFrom` to that image, so
  `devpod up` reuses the prebuilt layers instead of rebuilding Features locally
  (fast, and avoids flaky GitHub release-asset downloads on your machine).
- **Any folder, no config:** `devpod up <dir> --devcontainer-image ghcr.io/jonathanmanton/iac-devcontainer:latest`
  starts straight from the image.

> The GHCR package must be **public** (or you must `docker login ghcr.io`) for
> the pull to work from your machine. Set it public once under the package
> settings on GitHub.

## What's installed

| Tool | How |
| --- | --- |
| Terraform | Feature `devcontainers/features/terraform` |
| AWS CLI v2 | Feature `devcontainers/features/aws-cli` |
| kubectl | Feature `devcontainers/features/kubectl-helm-minikube` |
| **Helm 4** | same Feature (`helm: latest` → 4.x; `minikube: none`) |
| Python | Feature `devcontainers/features/python` |
| Node.js + npm | Feature `devcontainers/features/node` |
| Docker-in-Docker | Feature `devcontainers/features/docker-in-docker` |
| jq, make, dnsutils (`dig`), groff, tmux | `onCreate.sh` — apt |
| zellij | `onCreate.sh` — official release tarball |
| starship | `onCreate.sh` — official release tarball |
| uv / uvx | `onCreate.sh` — official release tarball |
| yq | `onCreate.sh` — official release binary |
| argocd | `onCreate.sh` — official release binary |
| Bitwarden CLI (`bw`) | `onCreate.sh` — `npm install -g @bitwarden/cli` |
| jinja2-cli | `onCreate.sh` — `uv tool install jinja2-cli` |
| Homebrew (`brew`) | `onCreate.sh` — installed for later ad-hoc use; **not** used during bootstrap, and on PATH in all shells |

## Bitwarden auto-unlock

`onCreate.sh` wires `bw-login.sh` into `~/.bashrc`, so every interactive shell
prompts to unlock the vault for `jonathan@manton.com` and exports `BW_SESSION`
for the session (Ctrl-C to skip). Edit `BW_EMAIL` in `bw-login.sh` to change the
account.

## Notes

- **Helm 4** — `helm: latest` resolves to the latest stable (4.x). Pin to e.g.
  `"helm": "4.0.0"` if you need it fixed.
- The non-root user is `jonathan` (uid/gid 1000). A thin `Dockerfile` renames
  the base image's default `vscode` user, keeping the uid/gid so workspace file
  ownership is unchanged.
- `.gitattributes` + `.editorconfig` force LF endings on the shell scripts;
  CRLF (e.g. from a Windows checkout) breaks `bash` inside the container.
- Skipped as not relevant to a devcontainer: the Nerd Font (host terminal font)
  and the repo-cloning helper scripts.

## Usage

```bash
# DevPod
devpod up github.com/jonathanmanton/workspace      # from the repo
devpod up . --recreate                             # rebuild a local clone

# or the Dev Containers CLI
npm install -g @devcontainers/cli
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash -lc \
  'terraform version && aws --version && kubectl version --client && helm version && \
   zellij --version && starship --version && uv --version && yq --version && \
   argocd version --client && bw --version && jinja2 --version && tmux -V && docker --version'
```
