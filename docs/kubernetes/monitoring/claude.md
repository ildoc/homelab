Perfetto! Hai ragione su entrambi i fronti. Facciamo un setup pulito e dichiarativo.

## 📁 **Manifest necessari per il tuo setup**

### **Struttura file da creare:**
```
kubernetes/
├── infra/
│   ├── prometheus-stack.yaml                    # ArgoCD Application
│   └── manifests/
│       └── prometheus-stack/
│           ├── Chart.yaml                       # Helm chart definition
│           ├── values.yaml                       # Configurazione principale
│           └── templates/
│               ├── httproutes.yaml               # Routes per Grafana/Prometheus/AlertManager
│               ├── pve-exporter.yaml             # Proxmox exporter deployment
│               └── monitoring-targets.yaml       # ServiceMonitors e Probes
```

## 📝 **I Manifest essenziali:**## 🚀 **Step da eseguire:**

### **1. Prepara Proxmox (5 minuti)**
```bash
# Sul tuo Proxmox, crea un utente read-only per il monitoring
pveum user add monitoring@pve --comment "Prometheus monitoring"
pveum passwd monitoring@pve  # Setta la password
pveum aclmod / -user monitoring@pve -role PVEAuditor
```

### **2. Configura GitLab (5 minuti)**
```bash
# Verifica che i exporter siano abilitati in /etc/gitlab/gitlab.rb
gitlab_exporter['enable'] = true
prometheus['enable'] = true
node_exporter['enable'] = true
redis_exporter['enable'] = true
postgres_exporter['enable'] = true
gitlab_monitor['enable'] = true

# Riconfigura GitLab
sudo gitlab-ctl reconfigure
```

### **3. Crea i file nel repo (10 minuti)**
```bash
# Crea la struttura
mkdir -p kubernetes/infra/manifests/prometheus-stack/templates

# Copia i manifest nelle posizioni corrette
# - prometheus-stack.yaml in kubernetes/infra/
# - Chart.yaml in kubernetes/infra/manifests/prometheus-stack/
# - values.yaml in kubernetes/infra/manifests/prometheus-stack/
# - *.yaml in kubernetes/infra/manifests/prometheus-stack/templates/
```

### **4. Personalizza le configurazioni**
Modifica nei file:
- Password Grafana in `values.yaml`
- Credenziali Proxmox in `pve-exporter.yaml`
- Token Telegram in `values.yaml` (se vuoi gli alert)
- IP dei nodi Proxmox in `pve-exporter.yaml`

### **5. Commit e deploy**
```bash
git add kubernetes/infra/prometheus-stack.yaml
git add kubernetes/infra/manifests/prometheus-stack/
git commit -m "Add Prometheus monitoring stack with GitLab and Proxmox"
git push
```

### **6. ArgoCD farà il deploy automatico**
Dopo qualche minuto avrai:
- 📊 **Grafana**: https://grafana.local.ildoc.it
- 📈 **Prometheus**: https://prometheus.local.ildoc.it
- 🔔 **AlertManager**: https://alertmanager.local.ildoc.it

## ✅ **Cosa avrai:**

1. **Monitoring completo dichiarativo** (tutto in Git)
2. **GitLab** monitorato con tutte le metriche native
3. **Proxmox cluster** con metriche di VM, container, storage
4. **HTTP Probes** per tutti i servizi (sostituisce Uptime Kuma)
5. **Dashboard Grafana** pre-configurate
6. **Alert** configurabili via YAML

## 🎯 **Pro di questo approccio:**

- ✅ **100% GitOps** - tutto versionato e dichiarativo
- ✅ **No agent da installare** - GitLab e Proxmox hanno già tutto
- ✅ **Probes dichiarativi** - aggiungi/rimuovi target via Git
- ✅ **Storia metriche** - 30 giorni di retention
- ✅ **Alert intelligenti** - basati su metriche, non solo up/down

Puoi tenere Uptime Kuma per la status page pubblica, ma ora hai il monitoring serio sotto! 🚀
