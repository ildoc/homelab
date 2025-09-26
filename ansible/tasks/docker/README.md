# Docker Compose Update Tasks

Questa directory contiene tre task Ansible per gestire gli aggiornamenti dei file docker-compose:

## 1. update-compose.yaml
Task per copiare file docker-compose statici dal controller Ansible all'host remoto.

### Variabili richieste:
- `update_compose_remote_path`: Percorso del file docker-compose.yml sull'host remoto
- `update_compose_local_path`: Percorso del file docker-compose.yml locale
- `update_compose_project_path`: Directory del progetto Docker Compose

### Variabili opzionali:
- `force_update`: Forza l'aggiornamento anche se i file sono identici (default: false)
- `max_backups`: Numero massimo di backup da mantenere (default: 3)
- `validate_compose`: Valida la sintassi docker-compose prima del deploy (default: true)
- `cleanup_resources`: Pulisce risorse Docker inutilizzate dopo il deploy (default: true)

### Esempio d'uso:
```yaml
- include_tasks: tasks/docker/update-compose.yaml
  vars:
    update_compose_local_path: "{{ playbook_dir }}/templates/myapp/docker-compose.yml"
    update_compose_remote_path: "/opt/myapp/docker-compose.yml"
    update_compose_project_path: "/opt/myapp"
    force_update: false
```

## 2. update-compose-template.yaml
Task per renderizzare e deployare template docker-compose usando il sistema di template di Ansible.

### Variabili richieste:
- `update_compose_remote_path`: Percorso del file docker-compose.yml sull'host remoto
- `template_file_name`: Nome del file template (relativo alla directory templates/)
- `update_compose_project_path`: Directory del progetto Docker Compose

### Variabili opzionali:
- `force_update`: Forza l'aggiornamento anche se i contenuti sono identici (default: false)
- `pull_retries`: Numero di tentativi per il pull (default: 5)
- `pull_delay`: Ritardo tra i tentativi in secondi (default: 20)
- `max_backups`: Numero massimo di backup da mantenere (default: 3)
- `validate_compose`: Valida la sintassi docker-compose prima del deploy (default: true)
- `cleanup_resources`: Pulisce risorse Docker inutilizzate dopo il deploy (default: true)

### Esempio d'uso:
```yaml
- include_tasks: tasks/docker/update-compose-template.yaml
  vars:
    template_file_name: "myapp/docker-compose.yml.j2"
    update_compose_remote_path: "/opt/myapp/docker-compose.yml"
    update_compose_project_path: "/opt/myapp"
    pull_retries: 3
    pull_delay: 10
```

## 3. update-compose-unified.yaml
Task unificato che supporta sia la copia di file statici che il rendering di template.

### Variabili richieste:
- `update_compose_remote_path`: Percorso del file docker-compose.yml sull'host remoto
- `update_compose_project_path`: Directory del progetto Docker Compose
- Una di queste due:
  - `update_compose_local_path`: Per modalità copia
  - `template_file_name`: Per modalità template

### Variabili opzionali:
- `force_update`: Forza l'aggiornamento (default: false)
- `pull_retries`: Numero di tentativi per il pull (default: 3)
- `pull_delay`: Ritardo tra i tentativi in secondi (default: 10)
- `max_backups`: Numero massimo di backup da mantenere (default: 3)
- `validate_compose`: Valida la sintassi docker-compose prima del deploy (default: true)
- `cleanup_resources`: Pulisce risorse Docker inutilizzate dopo il deploy (default: true)

### Esempio d'uso (modalità copia):
```yaml
- include_tasks: tasks/docker/update-compose-unified.yaml
  vars:
    update_compose_local_path: "{{ playbook_dir }}/files/myapp/docker-compose.yml"
    update_compose_remote_path: "/opt/myapp/docker-compose.yml"
    update_compose_project_path: "/opt/myapp"
```

### Esempio d'uso (modalità template):
```yaml
- include_tasks: tasks/docker/update-compose-unified.yaml
  vars:
    template_file_name: "myapp/docker-compose.yml.j2"
    update_compose_remote_path: "/opt/myapp/docker-compose.yml"
    update_compose_project_path: "/opt/myapp"
```

## Miglioramenti implementati

### Robustezza:
- Validazione delle variabili richieste all'inizio
- Gestione degli errori più granulare
- Retry logic per il pull delle immagini
- Backup automatico dei file esistenti
- Controlli di esistenza dei file locali

### Ridondanza ridotta:
- Logica comune estratta in blocchi riutilizzabili
- Task unificato che supporta entrambe le modalità
- Messaggi di debug più chiari e consistenti
- Variabili con valori di default sensati

### Funzionalità aggiunte:
- **Gestione backup intelligente**: Mantiene solo gli ultimi N backup (configurabile)
- **Validazione pre-deploy**: Verifica la sintassi docker-compose prima della sovrascrittura
- **Pulizia automatica**: Rimuove immagini, volumi e reti inutilizzate dopo il deploy
- **Backup automatico dei file esistenti** con timestamp
- **Configurabilità dei parametri di retry**
- **Validazione più rigorosa degli input**
- **Logging migliorato delle operazioni**

## Nuove caratteristiche di sicurezza e manutenzione

### Gestione Backup:
- I backup vengono denominati con timestamp: `docker-compose.yml.1732633200.backup`
- Viene mantenuto solo il numero configurato di backup (default: 3)
- I backup più vecchi vengono automaticamente rimossi

### Validazione Pre-Deploy:
- Prima di sovrascrivere il file esistente, viene validata la sintassi del nuovo docker-compose usando `docker compose config`
- Se la validazione fallisce, il processo si interrompe senza modificare il file originale
- Utilizza un file temporaneo per la validazione che viene sempre pulito
- La validazione verifica sintassi YAML e configurazione Docker Compose

### Pulizia Automatica:
- Dopo il deploy dei nuovi container, vengono rimosse:
  - Immagini Docker non utilizzate (incluse quelle non dangling)
  - Volumi Docker orfani
  - Reti Docker inutilizzate
- La pulizia può essere disabilitata con `cleanup_resources: false`
- Mostra un report delle risorse rimosse

### Esempio completo con tutte le opzioni:
```yaml
- include_tasks: tasks/docker/update-compose-unified.yaml
  vars:
    template_file_name: "myapp/docker-compose.yml.j2"
    update_compose_remote_path: "/opt/myapp/docker-compose.yml"
    update_compose_project_path: "/opt/myapp"
    max_backups: 5                    # Mantieni 5 backup
    validate_compose: true            # Valida sempre (default)
    cleanup_resources: true           # Pulisci dopo deploy (default)
    pull_retries: 5                   # 5 tentativi per il pull
    pull_delay: 15                    # 15 secondi tra i tentativi
    force_update: false               # Solo se necessario
```

## Raccomandazioni per l'uso

1. **Per progetti semplici**: Usa `update-compose.yaml` per file statici
2. **Per progetti con configurazioni dinamiche**: Usa `update-compose-template.yaml`
3. **Per massima flessibilità**: Usa `update-compose-unified.yaml`

Tutti i task sono retrocompatibili con i playbook esistenti, ma offrono maggiore robustezza e controllo sulle operazioni.
