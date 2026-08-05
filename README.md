# stack-viewer

App piloto del stack `k3s-infra` + `k3s-gitops` + Argo CD — una página
100% estática (HTML + CSS, sin JS) que muestra en qué ambiente/cluster
está corriendo. `ENVIRONMENT`/`CLUSTER_NAME`/`BASE_DOMAIN` se hornean
en **build-time** (el CI reemplaza los placeholders de
`index.html.template` antes de armar la imagen) — nada se lee en
runtime, sin `envFrom` ni Downward API. Sirve para confirmar que el
pipeline completo (commit → imagen → Argo CD → pod) funciona, y como
plantilla de partida para el repo de una app nueva — este repo está
marcado como **template** en GitHub.

Corriendo en vivo, con HTTPS real (Let's Encrypt vía cert-manager):
- dev: **https://stack-viewer-dev.cloudcentinel.com**
- prod: **https://stack-viewer.cloudcentinel.com**

Ver el roadmap completo en `kubernetes-practice/roadmap.md` (repo
hermano `k3s-infra`/`k3s-gitops`).

## Qué necesita un repo de app (y nada más)

- Código + `Dockerfile`
- `.github/workflows/deploy.yml`

Ningún YAML de Kubernetes vive acá — eso está centralizado en
`k3s-gitops/charts/<app>`.

## Ramas: `develop` → dev, `main` → prod con aprobación

- Push a `develop` → build, scan, bump `values-dev.yaml` en
  `k3s-gitops` → Argo CD sincroniza `<app>-dev` sin pausas.
- Push a `main` → mismo pipeline, pero el bump a `values-prod.yaml`
  queda pausado hasta aprobación manual (GitHub Environment
  `production` con reviewer — se configura una vez por repo, no viene
  del template, ver `k3s-gitops/docs/nueva-app.md`).

## Pipeline (`.github/workflows/deploy.yml`)

1. Checkout + `sha_short` = SHA corto del commit
2. Genera `index.html` desde `index.html.template`, sustituyendo
   `ENVIRONMENT` (derivado de la rama), `CLUSTER_NAME`/`BASE_DOMAIN`
   (Variables del repo en GitHub, no hardcodeadas en el workflow)
3. Build de la imagen **sin pushear todavía**
4. Trivy escanea la imagen local — si encuentra CRITICAL/HIGH, corta
   acá y nunca llega a publicarse
5. Push a `ghcr.io/andressep95/<app>` (usa el `GITHUB_TOKEN` por
   defecto, scope `packages: write`)
6. Checkout de `k3s-gitops` con una deploy key de **escritura**
   (secret `GITOPS_DEPLOY_KEY`, distinta de la de solo-lectura que usa
   Argo CD)
7. `yq` bump de `image.tag` en `charts/<app>/values-<ambiente>.yaml`
8. Commit + push a `k3s-gitops` — ahí termina el workflow; el deploy
   real lo hace Argo CD

## Usar esto como plantilla para una app nueva

Checklist completo, paso a paso, en `k3s-gitops/docs/nueva-app.md`.
Resumen:

1. "Use this template" en GitHub, o `gh repo create <app> --template andressep95/stack-viewer --private`
2. Reemplazar el contenido de la app (`Dockerfile`, código) — dejar
   `.github/workflows/deploy.yml` tal cual si tu app también es
   estática; si no, vas a necesitar tu propio mecanismo de build (este
   workflow asume `envsubst` sobre un `index.html.template`)
3. Crear la rama `develop` y el Environment `production` con reviewer
   (config de GitHub, no un archivo — no se copia del template)
4. Generar una deploy key de **lectura** para Argo CD y una de
   **escritura** para este workflow (ver `docs/README.md` en
   `k3s-gitops`)
5. Copiar `k3s-gitops/charts/_template-app` a `k3s-gitops/charts/<app>`, ajustar `values.yaml`
6. Copiar `k3s-gitops/argocd-apps/stack-viewer-dev/` y `stack-viewer-prod/` a `<app>-dev/`/`<app>-prod/`
7. Crear el Secret `ghcr-pull` en el namespace destino si el package de GHCR es privado
