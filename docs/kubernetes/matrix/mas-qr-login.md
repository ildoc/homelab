# Matrix Authentication Service (MAS) — QR login / Element X

Abilita MSC4108 (QR) e OAuth Client Auth per Element X.

Docs ufficiali: [homeserver](https://element-hq.github.io/matrix-authentication-service/setup/homeserver.html) · [migration](https://element-hq.github.io/matrix-authentication-service/setup/migration.html) · [Authentik SSO](https://element-hq.github.io/matrix-authentication-service/setup/sso.html)

## Perché il Job syn2mas è in `docs/` e non in `applications/`?

È **corretto** in GitOps:

| Cosa | Dove | Perché |
|------|------|--------|
| Stato stabile (MAS, Synapse, gateway) | `kubernetes/applications/matrix/` | ArgoCD sync continuo |
| Tunnel hostnames | `kubernetes/infra/.../cloudflared` | ArgoCD sync continuo |
| Migrazione one-shot `syn2mas` | `docs/.../manifests/mas-syn2mas-job.yaml` | Non deve rieseguire / essere pruned a ogni sync |

Il Job resta **dichiarativo e versionato in git**. L’unico `kubectl apply -f docs/...` è applicare quel manifesto dal repo (come un “migration runner”), non modificare oggetti a mano.

## Prerequisiti (già fatti da te)

- [x] DB `matrix_mas_db` / user
- [x] Authentik app `matrix-mas` + redirect ULID
- [x] Secret Vault MAS

Verifica anche DNS `mas.ildoc.it` sul tunnel Cloudflare.

---

## Flusso GitOps (2 commit + 1 Job)

### Fase 1 — Deploy MAS senza rompere il login (commit ora)

Stato attuale del repo (sicuro da pushare):

- MAS + gateway + ExternalSecrets MAS
- Synapse **ancora OIDC** → Authentik (login invariato)
- `matrix.ildoc.it` → Synapse diretto
- `mas.ildoc.it` → MAS

```bash
git add kubernetes/applications/matrix \
        kubernetes/infra/manifests/cloudflared \
        ansible docs/kubernetes/matrix scripts/matrix-mas-*.sh
git commit -m "feat(matrix): deploy MAS alongside Synapse (pre-cutover)"
git push
# aspetta sync ArgoCD app matrix (+ infra cloudflared)
```

Verifica:

```bash
kubectl -n apps rollout status deploy/matrix-mas
curl -fsS https://mas.ildoc.it/health
# login Element Web deve funzionare ancora via Authentik (OIDC Synapse)
```

### Fase 1.5 — Downtime: ferma Synapse (commit GitOps)

Nel `deployment.yaml` di Synapse aggiungi/imposta `replicas: 0`, commit, push, aspetta che il pod sparisca (PVC RWO libero per il Job).

```yaml
spec:
  replicas: 0
```

### Migrazione syn2mas (unico apply da git)

```bash
kubectl -n apps delete job matrix-mas-syn2mas --ignore-not-found
kubectl apply -f docs/kubernetes/matrix/manifests/mas-syn2mas-job.yaml
kubectl -n apps wait --for=condition=complete job/matrix-mas-syn2mas --timeout=600s
kubectl -n apps logs job/matrix-mas-syn2mas
```

Se fallisce: fix → eventualmente ricrea solo `matrix_mas_db` → riesegui il Job. Synapse DB non viene scritto da syn2mas.

### Fase 2 — Cutover (commit GitOps)

Copia i file finali nel path ArgoCD e pusha:

```bash
chmod +x scripts/matrix-mas-apply-cutover.sh
./scripts/matrix-mas-apply-cutover.sh
git add kubernetes/applications/matrix kubernetes/infra/manifests/cloudflared
git commit -m "feat(matrix): cutover Synapse auth to MAS + MSC4108"
git push
```

Effetto:

- Synapse → `matrix_authentication_service` + `msc4108_enabled`
- `matrix.ildoc.it` → `matrix-gateway` (login/logout/refresh → MAS)
- `replicas: 1` su Synapse

### Verifica

```bash
curl -sS https://matrix.ildoc.it/_matrix/client/versions | jq '.unstable_features["org.matrix.msc4108"]'
# true

curl -sS https://matrix.ildoc.it/_matrix/client/v1/auth_metadata | jq .
# issuer https://mas.ildoc.it/
```

Client: Element Web → Link new device (QR); Element X → scan o homeserver `matrix.ildoc.it`.

## Rollback

Ripristina dal commit Fase 1 (OIDC + matrix diretto a Synapse). syn2mas non altera il DB Synapse.

## File

- `kubernetes/applications/matrix/mas-*.yaml`, `gateway-*.yaml` — Fase 1
- `docs/kubernetes/matrix/manifests/mas-syn2mas-job.yaml` — migrate
- `docs/kubernetes/matrix/manifests/cutover/*` — Fase 2 (copiati da `matrix-mas-apply-cutover.sh`)
