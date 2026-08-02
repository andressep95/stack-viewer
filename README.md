# stack-viewer

App piloto del stack `k3s-infra` + `k3s-gitops` + Argo CD — una página
que muestra en qué ambiente/namespace/pod está corriendo, leyendo esos
datos de `global-config` (vía `envFrom`) y de la Downward API. Sirve
para confirmar que el pipeline completo (commit → imagen → Argo CD →
pod) funciona, y como plantilla de partida para el repo de una app
nueva — este repo está marcado como **template** en GitHub.

Corriendo en vivo, con HTTPS real (Let's Encrypt vía cert-manager):
**https://stack-viewer-dev.cloudcentinel.com**

Ver el roadmap completo en `kubernetes-practice/roadmap.md` (repo
hermano `k3s-infra`/`k3s-gitops`).

## Qué necesita un repo de app (y nada más)

- Código + `Dockerfile`
- `.github/workflows/deploy.yml`

Ningún YAML de Kubernetes vive acá — eso está centralizado en
`k3s-gitops/charts/<app>`.

## Pipeline (`.github/workflows/deploy.yml`)

1. Push a `main` → build de la imagen, tag = SHA corto del commit
2. Push a `ghcr.io/andressep95/<app>` (usa el `GITHUB_TOKEN` por defecto, scope `packages: write`)
3. Checkout de `k3s-gitops` con una deploy key de **escritura** (secret `GITOPS_DEPLOY_KEY`, distinta de la de solo-lectura que usa Argo CD)
4. `yq` bump de `image.tag` en `charts/<app>/values-dev.yaml`
5. Commit + push a `k3s-gitops` — ahí termina el workflow; el deploy real lo hace Argo CD

## Usar esto como plantilla para una app nueva

1. "Use this template" en GitHub, o `gh repo create <app> --template andressep95/stack-viewer --private`
2. Reemplazar el contenido de la app (`Dockerfile`, código) — dejar `.github/workflows/deploy.yml` tal cual, solo cambia por convención de nombres (`github.repository_owner`/nombre del repo ya lo resuelven solos)
3. Generar una deploy key de **lectura** para Argo CD y una de **escritura** para este workflow (ver `docs/README.md` en `k3s-gitops`)
4. Copiar `k3s-gitops/charts/_template-app` a `k3s-gitops/charts/<app>`, ajustar `values.yaml`
5. Crear `k3s-gitops/argocd-apps/<app>-dev.yaml`
6. Crear el Secret `ghcr-pull` en el namespace destino si el package de GHCR es privado
