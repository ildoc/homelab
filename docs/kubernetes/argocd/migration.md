# Guida ArgoCD: Migrazione e Bootstrap

## Parte 1: Migrazione da install.yaml a Self-Management GitOps

### Prerequisiti
- Cluster Kubernetes funzionante con ArgoCD installato via `kubectl apply -f install.yaml`
- Repository GitOps già configurato
- External Secrets Operator funzionante

### Step 1: Preparazione del Chart Wrapper

Creare la struttura del chart wrapper per ArgoCD:

```bash
# Struttura directory
kubernetes/infra/manifests/argocd/
├── Chart.yaml
├── values.yaml
└── templates/
    └── httproute.yaml
```

**Chart.yaml:**
```yaml
apiVersion: v2
name: argocd
version: 1.0.0
dependencies:
  - name: argo-cd
    version: 8.5.8
    repository: https://argoproj.github.io/argo-helm
```

**values.yaml:**
```yaml
gateway:
  enabled: true
  name: cilium-gateway
  namespace: kube-system
  hostname: argocd.local.ildoc.it

argo-cd:
  global:
    domain: argocd.local.ildoc.it

  redis-ha:
    enabled: true
    haproxy:
      enabled: true

  controller:
    replicas: 1

  server:
    replicas: 2
    ingress:
      enabled: false

  repoServer:
    replicas: 2

  applicationSet:
    replicas: 2

  configs:
    cm:
      timeout.reconciliation: 180s
    params:
      server.insecure: "true"
```

**templates/httproute.yaml:**
```yaml
{{- if .Values.gateway.enabled }}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: argocd-server
  labels:
    app.kubernetes.io/name: argocd
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  parentRefs:
  - name: {{ .Values.gateway.name }}
    namespace: {{ .Values.gateway.namespace }}
    sectionName: https
  hostnames:
  - {{ .Values.gateway.hostname | quote }}
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: argocd-server
      port: 443
{{- end }}
```

### Step 2: Generazione Chart.lock

```bash
cd kubernetes/infra/manifests/argocd
helm dependency update
cd -

# Committa Chart.lock (opzionale ma consigliato)
git add kubernetes/infra/manifests/argocd/Chart.lock
git commit -m "Add ArgoCD Chart.lock"
```

### Step 3: Creazione Application per Self-Management

**kubernetes/infra/argocd.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-100"
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://gitlab.local.ildoc.it/ildoc/homelab.git
    targetRevision: HEAD
    path: kubernetes/infra/manifests/argocd
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      prune: false  # Importante: non cancellare automaticamente
      selfHeal: true
  ignoreDifferences:
    - group: argoproj.io
      kind: Application
      jsonPointers:
        - /status
        - /operation
```

### Step 4: Migrazione Effettiva

```bash
# 1. Rimuovi finalizers dalle Applications per evitare blocchi
kubectl get applications -n argocd -o name | while read app; do
  kubectl patch $app -n argocd -p '{"metadata":{"finalizers":[]}}' --type=merge
done

# 2. Rimuovi vecchia installazione
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/ha/install.yaml

# 3. Attendi che il namespace sia pulito
kubectl get namespace argocd -w  # Aspetta che termini la cancellazione

# 4. Installa con Helm (saltando le CRD già esistenti)
helm install argocd ./kubernetes/infra/manifests/argocd \
  -n argocd \
  --create-namespace \
  --skip-crds

# 5. Verifica installazione
kubectl get pods -n argocd -w

# 6. Applica l'Application per self-management
kubectl apply -f kubernetes/infra/argocd.yaml

# 7. Verifica che ArgoCD gestisca se stesso
kubectl get application argocd -n argocd
```

### Step 5: Verifica e Test

```bash
# Verifica che l'Application sia sincronizzata
argocd app get argocd

# Test di modifica: cambia un valore nel values.yaml
vim kubernetes/infra/manifests/argocd/values.yaml
# Cambia ad esempio: timeout.reconciliation: 180s → 300s

git add kubernetes/infra/manifests/argocd/values.yaml
git commit -m "Test self-management: update timeout"
git push

# Verifica che ArgoCD applichi automaticamente il cambiamento
kubectl get configmap argocd-cm -n argocd -o yaml | grep reconciliation
```

---

## Parte 2: Prima Installazione di un Nuovo Cluster

### Step 1: Installazione Iniziale di ArgoCD

```bash
# 1. Clona il repository GitOps
git clone https://gitlab.local.ildoc.it/ildoc/homelab.git
cd homelab

# 2. Installa ArgoCD con Helm
cd kubernetes/infra/manifests/argocd

# Genera Chart.lock (se non committato)
helm dependency update

# Installa ArgoCD
helm install argocd . \
  -n argocd \
  --create-namespace \
  --skip-crds  # Le CRD sono già nel manifest HA

cd -

# 3. Attendi che tutti i pod siano pronti
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

### Step 2: Configurazione Accesso (Opzionale)

```bash
# Ottieni la password admin di default
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Login tramite CLI (opzionale)
argocd login argocd.local.ildoc.it --username admin
```

### Step 3: Configurazione Repository SSH (se privato)

```bash
# 1. Genera SSH key per ArgoCD
ssh-keygen -t ed25519 \
  -C "argocd@local.ildoc.it" \
  -f ~/.ssh/argocd_gitlab \
  -N ""

# 2. Aggiungi la chiave pubblica a GitLab
cat ~/.ssh/argocd_gitlab.pub
# Copia e incolla in GitLab → Settings → Repository → Deploy Keys

# 3. Salva la chiave privata in Vault
vault kv put kubernetes/argocd \
  gitlab-ssh-key=@~/.ssh/argocd_gitlab

# 4. Ottieni l'host key di GitLab
ssh-keyscan gitlab.local.ildoc.it

# 5. Aggiungi le known hosts al values.yaml
vim kubernetes/infra/manifests/argocd/values.yaml
```

Aggiungere:
```yaml
argo-cd:
  configs:
    ssh:
      knownHosts: |
        gitlab.local.ildoc.it ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...
```

```bash
# 6. Upgrade ArgoCD con la nuova configurazione
helm upgrade argocd kubernetes/infra/manifests/argocd \
  -n argocd
```

### Step 4: Creazione ExternalSecret per Repository

**kubernetes/infra/manifests/infra-secrets/argocd-repo-ssh.yaml:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: argocd-repo-ssh
  namespace: argocd
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-kubernetes-secret-store
    kind: ClusterSecretStore
  target:
    name: repo-homelab-ssh
    creationPolicy: Owner
    template:
      metadata:
        labels:
          argocd.argoproj.io/secret-type: repository
      data:
        type: git
        url: git@gitlab.local.ildoc.it:ildoc/homelab.git
        sshPrivateKey: "{{ .sshKey }}"
  data:
    - secretKey: sshKey
      remoteRef:
        key: kubernetes/data/argocd
        property: gitlab-ssh-key
```

### Step 5: Bootstrap del Sistema GitOps

```bash
# 1. Applica l'Application root (app-of-apps)
kubectl apply -f kubernetes/root-applications.yaml

# 2. Verifica che la root Application sia stata creata
kubectl get application root -n argocd

# 3. La root Application creerà automaticamente tutte le altre
kubectl get applications -n argocd -w

# Output atteso:
# NAME              SYNC STATUS   HEALTH STATUS
# root              Synced        Healthy
# infra             Synced        Healthy
# argocd            OutOfSync     Healthy  <- Normale, ancora manuale
# cert-manager      Synced        Healthy
# cilium            Synced        Healthy
# ...
```

### Step 6: Adozione Self-Management di ArgoCD

```bash
# 1. Applica l'Application per ArgoCD stesso
kubectl apply -f kubernetes/infra/argocd.yaml

# 2. Verifica lo stato
kubectl get application argocd -n argocd

# 3. Forza il primo sync (può essere OutOfSync)
argocd app sync argocd

# 4. Da ora in poi, ArgoCD gestisce se stesso!
# Ogni modifica a values.yaml viene applicata automaticamente
```

### Step 7: Verifica Finale

```bash
# 1. Controlla tutte le Applications
kubectl get applications -n argocd

# 2. Verifica la salute di ArgoCD
kubectl get pods -n argocd

# 3. Test self-management
# Modifica qualcosa nel values.yaml di ArgoCD
vim kubernetes/infra/manifests/argocd/values.yaml
git add . && git commit -m "Test" && git push

# 4. Osserva ArgoCD applicare la modifica automaticamente
kubectl get application argocd -n argocd -w
```

### Ordine di Deploy Consigliato

Grazie alle sync-waves, l'ordine è automatico:
1. **Wave -100**: Cilium, External Secrets CRDs
2. **Wave -99**: NFS CSI, Metrics Server
3. **Wave -98**: Cert-Manager, External Secrets Operator
4. **Wave -90**: Certificates
5. **Wave -85**: Prometheus Stack
6. **Wave -80**: Infra Secrets
7. **Wave -79**: Ingresses
8. **Wave -75**: GitLab Runner
9. **Wave -70**: Rancher
10. **Wave -60**: Authentik
11. Altre applicazioni

---

## Note Importanti

### Gestione degli Aggiornamenti

**Per aggiornare ArgoCD:**
```bash
# 1. Modifica Chart.yaml
vim kubernetes/infra/manifests/argocd/Chart.yaml
# version: 8.5.8 → 8.6.0

# 2. Aggiorna dipendenze
cd kubernetes/infra/manifests/argocd
helm dependency update

# 3. Committa
git add Chart.yaml Chart.lock
git commit -m "Update ArgoCD to 8.6.0"
git push

# 4. ArgoCD si aggiorna automaticamente!
```

### Troubleshooting Comune

**Application OutOfSync permanente:**
```bash
# Verifica ignoreDifferences
kubectl describe application argocd -n argocd

# Forza sync
argocd app sync argocd --force
```

**Repository connection failed:**
```bash
# Verifica il secret
kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=repository

# Test connessione
kubectl exec -n argocd deployment/argocd-repo-server -- \
  ssh -T git@gitlab.local.ildoc.it
```

**Namespace bloccato in Terminating:**
```bash
# Rimuovi finalizers
kubectl get applications -n argocd -o name | while read app; do
  kubectl patch $app -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge
done
```

### Backup e Disaster Recovery

In caso di disaster, il ripristino è semplice:
```bash
# 1. Reinstalla ArgoCD con Helm
helm install argocd ./kubernetes/infra/manifests/argocd -n argocd

# 2. Applica root-applications.yaml
kubectl apply -f kubernetes/root-applications.yaml

# 3. Tutto si ricrea automaticamente da Git!
```
