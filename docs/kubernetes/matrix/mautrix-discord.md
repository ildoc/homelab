# mautrix-discord — bridge Discord ↔ Matrix

Controlla il tuo account Discord da Matrix (puppeting), seguendo la documentazione ufficiale:

- [Go bridge setup (Discord)](https://docs.mau.fi/bridges/go/setup.html?bridge=discord)
- [Docker / Kubernetes notes](https://docs.mau.fi/bridges/general/docker-setup.html?bridge=discord)
- [Registering appservices](https://docs.mau.fi/bridges/general/registering-appservices.html)
- [Authentication](https://docs.mau.fi/bridges/go/discord/authentication.html)

## Architettura

```
Element → Synapse ←appservice→ mautrix-discord → Discord API
                 registration.yaml montata in Synapse
```

- App ArgoCD: `mautrix-discord` (`kubernetes/applications/mautrix-discord/`)
- DB dedicato: `matrix_discord_db` (non condividere il DB di Synapse)
- Bot Matrix: `@discordbot:matrix.ildoc.it`

## Deploy (ordine)

### 1. Secret + registration

```bash
chmod +x scripts/mautrix-discord-bootstrap-secrets.sh
./scripts/mautrix-discord-bootstrap-secrets.sh
# esegui i vault kv put stampati
```

Proprietà Vault:

| Path | Property |
|------|----------|
| `cross/data/apps/mautrix-discord` | `postgres_password` |
| `k8s/data/apps/mautrix-discord` | `as_token`, `hs_token`, `provisioning_secret`, `avatar_proxy_key`, `registration_yaml` |

`registration_yaml` deve essere il file YAML generato (token identici a `as_token`/`hs_token`).

### 2. Database

```bash
ansible-playbook ansible/db.yml
```

### 3. Git push / ArgoCD

1. Sync **prima** `mautrix-discord` (crea i Secret)
2. Poi sync **matrix** (Synapse monta `registration.yaml` e richiede restart)

Synapse ha:

```yaml
app_service_config_files:
  - /data/appservices/mautrix-discord-registration.yaml
```

Dopo il sync, verifica:

```bash
kubectl -n apps rollout status sts/mautrix-discord
kubectl -n apps logs -f sts/mautrix-discord
kubectl -n apps logs deploy/matrix-synapse | grep -i appservice
```

### 4. Login Discord

1. Su Element, apri una DM con `@discordbot:matrix.ildoc.it`
2. Segui [Authentication](https://docs.mau.fi/bridges/go/discord/authentication.html):
   - `login-qr` (app mobile Discord), oppure
   - `login-token user <Authorization header>` (browser), oppure
   - `login-token bot <bot token>` (meno rischio ban)
3. Per i server Discord: comando `guilds` (vedi help del bot)

> Discord può ban-nare account sospetti. Per uso personale `login-token` / QR di solito va bene; il bot token è più sicuro.

## Note GitOps / k8s

Allineate alle note ufficiali Kubernetes:

- comando diretto `mautrix-discord -c … -n` (no rewrite config)
- una sola replica (`StatefulSet`)
- `publishNotReadyAddresses: true`
- probes `/_matrix/mau/live` e `/_matrix/mau/ready`

## Permission

In config: `@filippo:matrix.ildoc.it` = `admin`. Aggiungi altri MXID in `bridge.permissions` se serve.
