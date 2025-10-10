# Configurazione Authentik come OIDC Provider per Matrix

## Fase 1: Configurazione Authentik (Web UI)

### 1.1 Crea un OAuth2/OIDC Provider

1. Accedi ad Authentik: `https://auth.ildoc.it`
2. Vai su **Applications** → **Providers**
3. Click su **Create**
4. Seleziona **OAuth2/OpenID Provider**

Configurazione del Provider:
- **Name**: `Matrix Synapse`
- **Authorization flow**: `default-provider-authorization-implicit-consent` (o quello che preferisci)
- **Client type**: `Confidential`
- **Client ID**: `matrix-synapse` (puoi personalizzarlo)
- **Client Secret**: **Copia questo valore!** Lo useremo dopo in Vault
- **Redirect URIs/Origins (RegEx)**:
  ```
  https://matrix\.ildoc\.it/_synapse/client/oidc/callback
  ```
- **Signing Key**: `authentik Self-signed Certificate` (o il tuo certificato)

Configurazioni avanzate (clicca "Advanced protocol settings"):
- **Scopes**: 
  - `openid` ✓
  - `email` ✓
  - `profile` ✓
- **Subject mode**: `Based on the User's UUID`
- **Include claims in id_token**: ✓ (abilitato)

### 1.2 Crea l'Application

1. Vai su **Applications** → **Applications**
2. Click su **Create**

Configurazione:
- **Name**: `Matrix`
- **Slug**: `matrix`
- **Provider**: Seleziona il provider `Matrix Synapse` creato prima
- **Launch URL**: `https://element.ildoc.it` (opzionale)
- **Policy engine mode**: `any` (o configura policy specifiche)

### 1.3 (Opzionale) Crea un gruppo per utenti Matrix

1. Vai su **Directory** → **Groups**
2. Crea un gruppo chiamato `matrix-users`
3. Assegna gli utenti che devono accedere a Matrix

Poi nella Application, configura le policy per permettere solo a questo gruppo l'accesso.

## Fase 2: Salva il Client Secret in Vault

```bash
# Salva il client secret che hai copiato da Authentik
vault kv put kubernetes/data/apps/matrix \
  oidc_client_secret="<IL_CLIENT_SECRET_DA_AUTHENTIK>"

# Verifica
vault kv get kubernetes/data/apps/matrix
```

## Fase 3: Aggiorna Matrix ConfigMap

Aggiungi la configurazione OIDC a `homeserver.yaml` nella ConfigMap di Matrix.

## Fase 4: Aggiorna Matrix Deployment

Aggiungi l'environment variable per il client secret.

## Fase 5: Aggiorna l'External Secret

Aggiungi il client secret ai secret di Matrix.

## Fase 6: Test del flusso OIDC

### Test via Element Web

1. Vai su `https://element.ildoc.it`
2. Clicca su "Sign in"
3. Dovresti vedere un pulsante "Continue with Authentik" (o simile)
4. Click → redirect ad Authentik
5. Login con le tue credenziali Authentik
6. Consent screen (se necessario)
7. Redirect a Element, ora sei autenticato!

### Test via curl (per debug)

```bash
# 1. Discovery endpoint
curl https://auth.ildoc.it/application/o/matrix-synapse/.well-known/openid-configuration | jq

# 2. Verifica che Matrix veda la configurazione OIDC
kubectl exec -n apps deploy/matrix-synapse -- \
  grep -A 20 "oidc_providers" /data/homeserver.yaml

# 3. Controlla i logs di Matrix durante il login
kubectl logs -n apps -l app=matrix-synapse -f | grep -i oidc
```

## Troubleshooting

### Errore "redirect_uri mismatch"

Verifica che l'URI in Authentik sia esattamente:
```
https://matrix\.ildoc\.it/_synapse/client/oidc/callback
```

### Utente non viene creato automaticamente

Controlla i mapping in Authentik e assicurati che `allow_existing_users` sia true.

### Errore "issuer mismatch"

Verifica che `issuer` nella configurazione Matrix corrisponda esattamente all'URL di Authentik (con trailing slash).

### Voglio vedere gli attributi che Authentik passa a Matrix

```bash
# Abilita debug logging in Matrix
kubectl exec -n apps deploy/matrix-synapse -- \
  sed -i 's/level: INFO/level: DEBUG/' /data/log.config

# Restart del pod
kubectl rollout restart -n apps deploy/matrix-synapse

# Guarda i log
kubectl logs -n apps -l app=matrix-synapse -f | grep -i "oidc\|userinfo"
```

## Attributi mappati

Con questa configurazione, Authentik passerà a Matrix:

| Attributo Authentik | Claim OIDC | Uso in Matrix |
|---------------------|------------|---------------|
| `username` | `preferred_username` | Matrix User ID |
| `email` | `email` | Email utente |
| `name` | `name` | Display name |
| `UUID` | `sub` | Subject ID (univoco) |

## Gestione utenti

### Utenti esistenti

Se hai già utenti in Matrix con password locale, e vuoi permettere loro di usare OIDC:
- Imposta `allow_existing_users: true`
- L'utente deve avere lo stesso `localpart` (parte prima di `:matrix.ildoc.it`)

### Solo OIDC (consigliato)

Per forzare OIDC e disabilitare completamente la registrazione locale:

```yaml
enable_registration: false
password_config:
  enabled: false  # Disabilita completamente le password
```

### Mapping username

Matrix userID = `@<preferred_username>:matrix.ildoc.it`

Assicurati che gli username in Authentik siano:
- Minuscoli
- Senza spazi
- Senza caratteri speciali (solo lettere, numeri, `_`, `-`, `.`)

## Flusso di autenticazione completo

```
1. Utente visita Element Web
2. Click "Sign in with Authentik"
3. → Redirect a https://auth.ildoc.it/application/o/authorize/
4. Authentik: login + consent
5. → Redirect a https://matrix.ildoc.it/_synapse/client/oidc/callback?code=...
6. Matrix scambia code con access token
7. Matrix chiama userinfo endpoint di Authentik
8. Matrix crea/aggiorna utente locale
9. Matrix genera access token per Element
10. Element è autenticato!
```

## Best Practices

1. **Usa gruppi Authentik** per controllare chi può accedere a Matrix
2. **Abilita MFA in Authentik** per maggiore sicurezza
3. **Monitora i log** durante i primi test
4. **Backup** della configurazione prima di modificare
5. **Testa con un utente di test** prima di rollout completo

## Next Steps

Una volta funzionante:
- Configura policy di accesso in Authentik
- Abilita MFA per utenti Matrix
- Configura email notifications da Authentik
- Considera federation con altri server Matrix (se necessario)
