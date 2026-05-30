# iac-k8s-bootstrap devcontainer

A minimal devcontainer that reproduces most of the toolchain from
[`lago-morph/iac-k8s-bootstrap`'s Dockerfile](https://github.com/lago-morph/iac-k8s-bootstrap/blob/main/docker/Dockerfile)
using devcontainer **Features** instead of hand-written `RUN` steps.

## How the Dockerfile maps to `devcontainer.json`

| Dockerfile | devcontainer equivalent |
| --- | --- |
| `FROM ubuntu:24.04` + base utils (`curl`, `wget`, `git`, `vim`, `unzip`, `gnupg`, `less`, `bash-completion`, `sudo`, …) + non-root user | `image: mcr.microsoft.com/devcontainers/base:ubuntu-24.04` (ships these + a `vscode` sudo user) |
| Terraform | `features: terraform` |
| AWS CLI v2 | `features: aws-cli` |
| kubectl | `features: kubectl-helm-minikube` (`version: latest`) |
| Helm | `features: kubectl-helm-minikube` (`helm: latest` → **Helm 4**) |
| eksctl | `features: devcontainers-extra/eksctl` |
| ArgoCD CLI | `features: devcontainers-extra/argocd` |
| yq | `features: devcontainers-extra/yq` |
| Starship prompt | `features: devcontainers-extra/starship` |
| pipx + jinja2-cli | `features: python` + `devcontainers-extra/pipx-package` |
| `jq`, `make`, `bind9-dnsutils`, `groff`, `tmux` | `postCreateCommand` apt install |

## Extra tooling (beyond the Dockerfile)

| Tool | devcontainer equivalent |
| --- | --- |
| uv / uvx | `features: devcontainers-extra/uv` |
| Node.js + npm | `features: node` |
| Docker-in-Docker | `features: docker-in-docker` |
| Homebrew (Linuxbrew) | `features: devcontainers-extra/homebrew-package` |
| tmux | `postCreateCommand` apt install |

## Notes / differences

- **Helm 4** — `helm: latest` resolves to the latest stable, which is Helm 4.x.
  Pin to a specific version (e.g. `"helm": "4.0.0"`) if you need it fixed.
- The non-root user is `vscode` rather than the Dockerfile's `ubuntu` user.
- Skipped as not relevant to a devcontainer: the Liberation Mono Nerd Font
  (host-side terminal font) and the repo-cloning helper scripts.
- `minikube` is set to `none`; it isn't in the Dockerfile.

## Usage

Open the repo in VS Code and run **Dev Containers: Reopen in Container**, or
build with the CLI:

```bash
npm install -g @devcontainers/cli
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash -lc \
  'terraform version && aws --version && kubectl version --client && helm version && eksctl version && argocd version --client && yq --version && jinja2 --version && uv --version && uvx --version && npm --version && tmux -V && docker --version && brew --version'
```
