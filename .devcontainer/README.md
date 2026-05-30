# iac-k8s-bootstrap devcontainer

A devcontainer that reproduces most of the toolchain from
[`lago-morph/iac-k8s-bootstrap`'s Dockerfile](https://github.com/lago-morph/iac-k8s-bootstrap/blob/main/docker/Dockerfile).

Design: a small set of **official devcontainer Features** for the heavyweight
pieces, and a single **`postCreate.sh`** that installs the rest as quiet,
direct binary downloads. We deliberately avoid third-party `devcontainers-extra`
Features (several don't exist or are flaky) and avoid Homebrew (slow: it drags
in portable-ruby, python, node and icu4c just as dependencies).

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
| jq, make, dnsutils (`dig`), groff, tmux | `postCreate.sh` — apt |
| zellij | `postCreate.sh` — official release tarball |
| starship | `postCreate.sh` — official release tarball |
| uv / uvx | `postCreate.sh` — official release tarball |
| yq | `postCreate.sh` — official release binary |
| argocd | `postCreate.sh` — official release binary |
| Bitwarden CLI (`bw`) | `postCreate.sh` — `npm install -g @bitwarden/cli` |
| jinja2-cli | `postCreate.sh` — `uv tool install jinja2-cli` |

## Bitwarden auto-unlock

`postCreate.sh` wires `bw-login.sh` into `~/.bashrc`, so every interactive shell
prompts to unlock the vault for `jonathan@manton.com` and exports `BW_SESSION`
for the session (Ctrl-C to skip). Edit `BW_EMAIL` in `bw-login.sh` to change the
account.

## Notes

- **Helm 4** — `helm: latest` resolves to the latest stable (4.x). Pin to e.g.
  `"helm": "4.0.0"` if you need it fixed.
- The non-root user is `vscode`.
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
