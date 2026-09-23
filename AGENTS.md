# AGENTS.md — Homelab

Istruzioni operative per agenti AI e operatori umani. Questo file è vincolante.

## 0. Identità del repository

- **Nome:** homelab
- **Source of truth assoluta:** GitLab privato `https://gitlab.local.ildoc.it/ildoc/homelab.git` (branch tipico: `HEAD` / `master`).
- **GitHub** (`ildoc/homelab`) è solo un **mirror pulito**, non autoritativo. Non usare GitHub come destinazione di sync ArgoCD né come riferimento per lo stato reale.
- Stack: **Ansible** (host/VM/servizi Docker e lifecycle cluster) + **ArgoCD GitOps** (tutto ciò che vive su Kubernetes) + **HashiCorp Vault** (secret) + **Renovate** (dipendenze).

---

## 1. Principi non negoziabili

### 1.1 Se non è versionato, non esiste

Qualsiasi configurazione, manifesto, playbook, secret *reference*, hostname, PVC, chart, override o “fix temporaneo” **deve** esistere in questo repository (o in Vault, per i valori sensibili).

| Vietato | Obbligatorio |
|---------|--------------|
| Stato solo sul cluster / sulla VM | Commit su GitLab |
| “Lo sistemo a mano e poi vediamo” | Diff → commit → sync automatico |
| Documentare a voce / in chat senza file | Aggiornare i file del repo |
| Secret in chiaro nel git | Valore in Vault + ExternalSecret / lookup Ansible |

Se qualcosa gira ma non è in git: è **debito**. Va catturato nel repo o rimosso.

### 1.2 Kubernetes = solo GitOps (ArgoCD)

Il cluster è gestito **esclusivamente** da ArgoCD che sincronizza questo repo.

**Vietato in assoluto** (anche “solo per un minuto”, anche su namespace di test, anche se “autorizzato”, anche via Rancher UI):

- `kubectl apply|create|edit|patch|replace|delete|scale|rollout|set|annotate|label` che mutano risorse gestite
- `helm install|upgrade|uninstall` sul cluster
- `argocd app sync` con override / parametri non presenti in git
- Modifiche via dashboard Rancher / ArgoCD UI / Lens che alterano lo stato desiderato
- Creare risorse “a mano” e aspettarsi che restino (selfHeal + prune le cancellano o le sovrascrivono)

**Consentito** (sola osservazione / diagnosi):

- `kubectl get|describe|logs|top|api-resources|explain`
- Lettura stato ArgoCD (UI o CLI) **senza** forzare sync fuori da git
- Diff ArgoCD “live vs desired” per capire drift — poi **fix in git**, mai sul live

Eccezione strettissima: bootstrap iniziale di ArgoCD stesso via Ansible (`ansible/argocd.yml` + role `argocd`), che applica la root Application. Dopo il bootstrap, day-2 = solo git.

### 1.3 Scope di lavoro degli agenti

**Lavora su:** `ansible/`, `kubernetes/`, root config rilevanti (`.gitlab-ci.yml`, `renovate.json`, `.yamllint`, `.ansible-lint`, `AGENTS.md`, `README.md`).

**Ignora (non esplorare, non modificare, non usare come riferimento operativo):**

- `opentofu/`
- `terraform/`
- `tmp/`
- `docs/`
- `_skill_memory/`

Anche `appunti.md` è materiale personale/storico (spesso pre-GitOps): **non** usarlo come procedura. Preferisci i path versionati sotto `kubernetes/` e `ansible/`.

---

## 2. Mappa architetturale

```
GitLab homelab (SoT)
├── ansible/                    # Host, VM, Docker compose, kubeadm lifecycle, bootstrap ArgoCD
└── kubernetes/
    ├── root-applications.yaml  # Application "root" → path kubernetes/groups
    ├── groups/
    │   ├── infra.yaml          # Application "infra" → kubernetes/infra (Application CR per componente)
    │   ├── apps.yaml           # ApplicationSet → kubernetes/applications/*  (ns: apps)
    │   └── charts.yaml         # ApplicationSet → kubernetes/charts/*         (ns: apps, Helm)
    ├── infra/
    │   ├── <component>.yaml    # Application ArgoCD (sync-wave, dest ns)
    │   └── manifests/<name>/   # Chart umbrella / YAML reali
    ├── applications/<app>/     # Manifest plain YAML (auto-discovery)
    └── charts/<chart>/         # Helm chart locali / wrapper (auto-discovery)
```

Sync policy tipica: `automated.prune: true`, `automated.selfHeal: true`.  
Cartella `archived/` sotto `applications/` o `charts/` = esclusa dai generator → non deployata ma resta in git (soft-delete).

Repo ArgoCD: **sempre** `https://gitlab.local.ildoc.it/ildoc/homelab.git`, `targetRevision: HEAD`.

---

## 3. Cosa fare / non fare (cheat sheet)

| Obiettivo | Dove | Come |
|-----------|------|------|
| Nuova app plain | `kubernetes/applications/<nome>/` | Aggiungi YAML; ApplicationSet la crea da solo |
| Nuova app Helm-wrapped | `kubernetes/charts/<nome>/` | `Chart.yaml` + `values.yaml` (+ templates); ApplicationSet la crea |
| Nuovo pezzo infra | `kubernetes/infra/manifests/<nome>/` + `kubernetes/infra/<nome>.yaml` | Application CR con sync-wave |
| Dismettere un’app | sposta in `…/archived/<nome>/` | Non solo `kubectl delete` |
| Secret k8s | Vault + `ExternalSecret` | Mai Secret con data in chiaro nel repo |
| Secret Ansible | Vault path `ansible/data/…` + lookup `hashi_vault` | Mai password in `host_vars` plain |
| Host/Docker/DNS/DB | `ansible/` playbook + role | Commit, poi esegui playbook |
| Fix drift cluster | git | ArgoCD selfHeal; non “sistemare” il live |

---

## 4. Kubernetes — convenzioni obbligatorie

### 4.1 Namespace e routing

- Workload utente: namespace **`apps`** (già imposto dagli ApplicationSet).
- Infra: namespace dedicati (`argocd`, `cert-manager`, `monitoring`, `external-secrets`, …).
- Esposizione HTTP: **Gateway API** via `HTTPRoute` → parent `cilium-gateway` in `kube-system`, `sectionName: https`.
- Hostname tipico: `<servizio>.local.ildoc.it`. Domini pubblici solo dove già previsto (es. `matrix.ildoc.it`, `auth.ildoc.it`).
- Non introdurre Ingress Traefik/nginx “classici” per nuove app salvo necessità documentata e allineata all’infra esistente.

### 4.2 Storage

- Nuovi PVC: preferire StorageClass **`nfs-csi`** (default).
- `nfs-storage` (nfs-subdir) è legacy: non usarlo per risorse nuove.
- Media path: volumi `nfs:` diretti verso TrueNAS `192.168.0.123` dove già pattern consolidato (*arr).

### 4.3 Immagini e workload

- Pin delle immagini con **digest** (`image: …@sha256:…`) dove già pratica del repo / Renovate.
- Env comuni dove applicabile: `PUID=1000`, `PGID=1000`, `TZ=Europe/Rome`.
- Imposta `resources` (almeno limits) sui Deployment.
- Nome directory app ≈ nome Application ArgoCD ≈ `metadata.name` delle risorse principali.

### 4.4 App plain — file tipici

```
kubernetes/applications/<app>/
  deployment.yaml
  service.yaml
  pvc.yaml          # se serve
  httproute.yaml    # se esposta
  secret.yaml       # ExternalSecret, non Secret plaintext
  configmap.yaml    # se serve
```

Riferimento: `kubernetes/applications/sonarr/`, `kubernetes/applications/wakapi/`.

### 4.5 Chart Helm — file tipici

```
kubernetes/charts/<chart>/
  Chart.yaml        # spesso umbrella su chart upstream OCI/HTTP
  values.yaml       # valueFiles obbligatorio per ApplicationSet
  templates/        # HTTPRoute, ExternalSecret, PVC, …
  Chart.lock        # se ci sono dependencies
```

Riferimento: `kubernetes/charts/immich/`.

### 4.6 Infra — pattern

1. Manifest/chart in `kubernetes/infra/manifests/<component>/`
2. Application in `kubernetes/infra/<component>.yaml` con:
   - `argocd.argoproj.io/sync-wave` coerente con dipendenze
   - `destination.namespace` corretto
   - `syncPolicy.automated` prune + selfHeal (salvo eccezioni già presenti, es. prune selettivo su ArgoCD)
3. Secret infra centralizzati dove possibile in `kubernetes/infra/manifests/infra-secrets/`

Onde sync indicative (non inventare onde a caso; allineati ai vicini):  
`-100` core (argocd, cilium, ESO CRDs) → CRD/operatori → certificati/istio/monitoring → secrets/ingress → servizi (runner, rancher, authentik, cloudflared).

### 4.7 Secret su Kubernetes

| Store | Uso |
|-------|-----|
| `ClusterSecretStore/vault-kubernetes-secret-store` | Secret app/infra mount Vault `kubernetes` |
| `ClusterSecretStore/vault-cross-secret-store` | Secret condivisi (es. password DB) mount `cross` |

Path Vault tipici:

- App: `kubernetes/data/apps/<app>` o `cross/data/apps/<app>`
- Infra: `kubernetes/data/infra/<component>`, `kubernetes/data/cert-manager`, …

Flusso: **1)** crea/aggiorna secret in Vault → **2)** dichiara `ExternalSecret` in git → **3)** Deployment usa `secretKeyRef` sul Secret generato.

**Non** usare SOPS / Sealed Secrets: non fanno parte di questo repo.

---

## 5. Ansible — convenzioni

### 5.1 Ruolo

Ansible gestisce ciò che **non** è (o non ancora) GitOps sul cluster:

- Lifecycle kubeadm (install/upgrade/join), kube-vip, bootstrap Cilium lato host
- Bootstrap ArgoCD + root Application
- Host servizi: Vault, GitLab, DB Postgres, Redis, Technitium DNS, WireGuard, Gitea, Invidious, Proxmox upgrade, ecc.

### 5.2 Layout

| Path | Ruolo |
|------|--------|
| `ansible/*.yml` | Un playbook per concern |
| `ansible/roles/<role>/` | Task, template (`docker-compose.yml.j2`), defaults |
| `ansible/inventory/hosts.ini` | Inventario |
| `ansible/inventory/group_vars/`, `host_vars/` | Variabili (lookup Vault in `all.yml`) |
| `ansible/tasks/` | Include condivisi (load Vault secrets, docker, …) |
| `ansible/collections/requirements.yml` | `community.hashi_vault`, `kubernetes.core`, … |

### 5.3 Secret

- **Non** Ansible Vault file-based come SoT primaria.
- Usare `community.hashi_vault.hashi_vault` verso path `ansible/data/…` (e dove serve `cross/data/…`).
- Playbook che caricano mappe secret: pattern `vault_secrets_map` + `tasks/vault/load-secrets.yaml`.

### 5.4 Esecuzione

- Modifica sempre i file nel repo **prima** di lanciare un playbook.
- Non “aggiustare” a SSH config non tracciate: aggiorna role/template/vars e ri-applica.
- Inventario e VIP cluster: vedi `group_vars` (`kubernetes.vip_address`, versioni k8s/cilium).

---

## 6. Workflow obbligatori per l’agente

### 6.1 Prima di qualsiasi cambiamento

1. Capire se il target è **kubernetes/** (GitOps) o **ansible/** (host).
2. Cercare un pattern esistente gemello e copiarne la struttura.
3. Non toccare le directory in §1.3 (ignore list).

### 6.2 Cambiamento Kubernetes

1. Modifica solo file sotto `kubernetes/`.
2. Non applicare nulla al cluster.
3. Verifica coerenza: namespace `apps`, HTTPRoute, ExternalSecret, StorageClass, digest.
4. Lascia che ArgoCD (dopo push su GitLab) converga. Se lavori in locale senza push, dichiara esplicitamente che il cluster non cambierà finché non c’è commit/push sul SoT.

### 6.3 Cambiamento Ansible

1. Modifica playbook/role/inventory/vars.
2. Nessun secret in chiaro.
3. Se richiesto dall’utente, esegui il playbook mirato — non inventare playbook “god” (`main.yml` è in gran parte legacy/commentato).

### 6.4 Diagnosi di drift / incident

1. `kubectl get/describe/logs` e/o stato ArgoCD (read-only).
2. Confronta con i file in git.
3. **Ripara il repo**, non il cluster.
4. Se selfHeal non basta, il problema è nel desired state o nei controller — non in un `kubectl edit`.

---

## 7. CI, Renovate, mirror

- **GitLab CI** (`.gitlab-ci.yml`, `.gitlab/ci/`): lint YAML/Ansible e altri job. Fonte operativa CI = GitLab.
- **Renovate** (`renovate.json`): aggiorna digest Docker, Helm, Application ArgoCD, immagini nei template compose Ansible. Ignora `**/archived/**` e `docs/**`.
- **`.exclude_from_github`**: path esclusi dal mirror pubblico — non “cancellare” app solo perché non compaiono su GitHub.
- Non committare secret, token, kubeconfig, file Vault. Se trovi secret già nel tree (es. note personali), **non** propagarli; segnala e preferisci rotazione fuori banda.

---

## 8. Checklist rapida — nuova applicazione (plain)

- [ ] Directory `kubernetes/applications/<nome>/` (non sotto `archived/`)
- [ ] `deployment.yaml` + `service.yaml` in `namespace: apps`
- [ ] Immagine pinata; `resources`; `TZ`/PUID/PGID se coerente
- [ ] `pvc.yaml` con `storageClassName: nfs-csi` se serve disco
- [ ] `httproute.yaml` → `cilium-gateway` / hostname `*.local.ildoc.it`
- [ ] Secret: voce in Vault + `ExternalSecret` (store corretto)
- [ ] DNS interno (Technitium) se hostname nuovo — via Ansible/processo esistente, non a mano non tracciata
- [ ] Commit su GitLab SoT; nessun `kubectl apply`

---

## 9. Anti-pattern (rifiutare / correggere)

- Qualsiasi “applichiamo sul cluster e poi aggiorniamo git”
- Usare il mirror GitHub come SoT
- Mettere Secret Kubernetes con `data:`/`stringData:` sensibili nel repo
- Creare Application ArgoCD a mano per app sotto `applications/` o `charts/` (ci pensano gli ApplicationSet)
- Usare `docs/`, `tmp/`, `opentofu/`, `terraform/`, `_skill_memory/` come guida operativa in questa sessione
- Copiare procedure da `appunti.md` (kubectl/helm imperativi legacy)
- Introdurre un secondo tool GitOps (Flux, ecc.) o un secondo ingresso reverse-proxy per default

---

## 10. Stile di lavoro

- Preferisci cambiamenti **piccoli, allineati ai file vicini**, senza refactor non richiesti.
- Non creare documentazione Markdown extra se non chiesta (questo `AGENTS.md` è l’eccezione esplicitamente richiesta).
- Lingua: italiano per comunicazione; YAML/API restano in inglese idiomatico Kubernetes.
- In caso di conflitto tra chat e repo: **vince il repo**. In caso di conflitto tra cluster live e repo: **vince il repo** (ripristina il live via ArgoCD, non il contrario).

---

**TL;DR:** GitLab è la realtà. ArgoCD la applica. Vault custodisce i secret. Ansible governa gli host. Il cluster non si tocca a mano.
