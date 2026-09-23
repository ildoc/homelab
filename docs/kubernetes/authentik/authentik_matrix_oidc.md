# Configurazione Authentik come upstream OIDC per Matrix (via MAS)

> **Aggiornamento 2026-09:** Synapse non usa più `oidc_providers` diretti.
> Authentik è upstream di [Matrix Authentication Service](./../matrix/mas-qr-login.md).
> Per il QR login / Element X segui quel runbook.

## Provider OAuth2/OIDC per MAS

1. Accedi ad Authentik: `https://auth.ildoc.it`
2. **Applications → Providers → Create → OAuth2/OpenID Provider**

Parametri:
- **Name**: `Matrix MAS`
- **Authorization flow**: `default-provider-authorization-implicit-consent` (o il tuo default)
- **Client type**: `Confidential`
- **Client ID**: `matrix-mas`
- **Client Secret**: copialo → Vault `k8s/data/apps/matrix:mas_oidc_client_secret`
- **Redirect URIs**:
  ```
  https://mas.ildoc.it/upstream/callback/01M36BMBEJ574P140G5TQ8NYBA
  ```
- **Signing Key**: certificato **RSA** (ECC non supportato)
- **Scopes**: `openid`, `email`, `profile`
- **Subject mode**: Based on the User's UUID
- **Include claims in id_token**: abilitato

## Application

- **Name**: `Matrix MAS`
- **Slug**: `matrix-mas` (obbligatorio: deve matchare l'issuer)
- **Provider**: `Matrix MAS`
- **Launch URL**: `https://element.ildoc.it` (opzionale)

Issuer risultante:
```
https://auth.ildoc.it/application/o/matrix-mas/
```

## Vault

```bash
vault kv patch k8s/data/apps/matrix \
  mas_oidc_client_secret='<CLIENT_SECRET>'
```

## Flusso login (dopo cutover MAS)

```
1. Element → OAuth discovery su matrix.ildoc.it (auth_metadata → issuer mas.ildoc.it)
2. Redirect a https://mas.ildoc.it/...
3. MAS → upstream Authentik
4. Login Authentik + consent
5. Callback https://mas.ildoc.it/upstream/callback/01M36BMBEJ574P140G5TQ8NYBA
6. MAS emette token Matrix → Element autenticato
```

## Legacy (pre-MAS) — non usare più

La vecchia integrazione puntava Synapse a:
- Redirect: `https://matrix.ildoc.it/_synapse/client/oidc/callback`
- Application slug: `matrix-synapse`
- Config Synapse: `oidc_providers` + `enable_device_authorization`

Quel path **non** abilita il QR “Link new device” di Element (serve MSC4108 + MAS).
