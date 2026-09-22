# CrowdSec Helm Chart

Chart Helm personalizzato per deployare CrowdSec su Kubernetes seguendo il pattern degli altri chart (immich, sonarqube).

## Configurazione

Questo chart è configurato per monitorare i log di **sing-box** nel namespace `apps`.

### Struttura

- `Chart.yaml`: Definisce la dipendenza dal chart ufficiale CrowdSec
- `values.yaml`: Configurazione personalizzata per il nostro ambiente

### Deployment

Prima di deployare, aggiorna le dipendenze Helm:

```bash
cd /home/filippo/homelab/kubernetes/charts/crowdsec
helm dependency update
```

Poi deploya il chart:

```bash
helm install crowdsec . -n crowdsec --create-namespace
```

Oppure se usi ArgoCD, crea un'applicazione ArgoCD che punti a questo chart.

### Configurazione sing-box

Il chart è configurato per monitorare i log di sing-box con:
- **Namespace**: `apps`
- **Pod pattern**: `sing-box-*`
- **Program name**: `sing-box`

### Parser per sing-box

**IMPORTANTE**: sing-box potrebbe non avere un parser specifico nel CrowdSec Hub. Potrebbe essere necessario:

1. Verificare se esiste un parser per sing-box nel [CrowdSec Hub](https://hub.crowdsec.net/)
2. Creare un parser custom se necessario
3. Usare un parser generico per log JSON se sing-box outputta log in formato JSON

Per verificare i log di sing-box e il loro formato:
```bash
kubectl logs -n apps -l app=sing-box
```

### Persistenza

Il chart è configurato per usare:
- **StorageClass**: `nfs-csi` (stesso degli altri chart)
- **Size**: 10Gi

### Bouncer Key

Per generare una bouncer key dopo il deployment (se hai persistenza abilitata):

```bash
kubectl -n crowdsec exec -it crowdsec-lapi-<pod-id> -- cscli bouncers add my-bouncer-name
```

Oppure configura la key direttamente nel `values.yaml` sotto `lapi.env` come `BOUNCER_KEY_<name>`.

### Firewall Bouncer e Sidecar

**AGGIORNAMENTO**: È possibile usare un **firewall-bouncer come sidecar** nel pod di sing-box per bloccare traffico malevolo in tempo reale.

Come funziona CrowdSec in Kubernetes:

1. **Agent CrowdSec**: L'agent CrowdSec viene deployato come DaemonSet e legge **direttamente i log dai pod Kubernetes** senza bisogno di sidecar. L'agent si connette automaticamente ai pod specificati in `agent.acquisition` e legge i loro log dal container runtime (containerd/docker).

2. **Firewall Bouncer come Sidecar**: È possibile aggiungere un sidecar container con `davidbcn86/crowdsec-firewall-bouncer-docker:latest-nftables` nel pod di sing-box per:
   - ✅ Bloccare traffico malevolo **prima che raggiunga sing-box**
   - ✅ Applicare regole nftables nel network namespace del pod
   - ✅ Ricevere decisioni in tempo reale da CrowdSec LAPI

3. **Configurazione Sidecar**: Vedi `/home/filippo/homelab/kubernetes/applications/sing-box/deployment-with-bouncer.yaml` per un esempio completo.

**Nota sulla sicurezza**: Il bouncer sidecar richiede la capability `NET_ADMIN` per modificare le regole nftables. Questo potrebbe richiedere configurazioni Pod Security Standards appropriate nel cluster.

**Alternative al Sidecar**:
- Deployare il bouncer come **DaemonSet** sul nodo (blocca traffico a livello di nodo)
- Usare **NetworkPolicies** di Kubernetes per bloccare traffico basato su label/annotations
- Integrare con il tuo **ingress controller** se sing-box è dietro un ingress

### Documentazione

- [CrowdSec Kubernetes Installation](https://docs.crowdsec.net/u/getting_started/installation/kubernetes)
- [CrowdSec Hub](https://hub.crowdsec.net/)
