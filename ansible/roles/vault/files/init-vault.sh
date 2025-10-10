#!/bin/sh
set -euo pipefail

# CONFIGURATIONS
POLICY_NAME="ci-policy"
ROLE_NAME="ci-role"
SECRET_PATHS="ansible terraform"
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:?VAULT_TOKEN missing}"

# OIDC Configuration (optional - set via env vars)
OIDC_DISCOVERY_URL="${OIDC_DISCOVERY_URL:-}"
OIDC_CLIENT_ID="${OIDC_CLIENT_ID:-}"
OIDC_CLIENT_SECRET="${OIDC_CLIENT_SECRET:-}"

# Install dependencies
apk add jq curl

echo "[+] Init Vault..."

# Abilita tutti i motori di segreti specificati nell'array
for SECRET_PATH in $SECRET_PATHS; do
  # Check if secret engine is already enabled
  if vault secrets list -format=json | jq -e ".[\"$SECRET_PATH/\"]" > /dev/null 2>&1; then
    echo "[+] Secret engine '$SECRET_PATH/' already enabled."
  else
    echo "[+] Enabling secret engine '$SECRET_PATH/' (kv-v2)..."
    vault secrets enable -path="$SECRET_PATH" -version=2 kv
  fi
done

# Check if Approle auth method is already enabled
if vault auth list -format=json | jq -e '."approle/"' > /dev/null 2>&1; then
  echo "[+] Auth method AppRole already enabled."
else
  echo "[+] Enabling auth method AppRole..."
  vault auth enable approle
fi

# Crea una policy che include tutti i path specificati
echo "[+] Writing policy '$POLICY_NAME'..."

# Inizia la policy con un'intestazione vuota
POLICY_CONTENT=""

# Aggiungi ogni percorso alla policy
for SECRET_PATH in $SECRET_PATHS; do
  POLICY_CONTENT="$POLICY_CONTENT
  path \"$SECRET_PATH/data/*\" {
    capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]
  }"
done

POLICY_CONTENT="$POLICY_CONTENT
path \"auth/token/create\" {
  capabilities = [\"update\"]
}"

# Scrivi la policy completa
echo "$POLICY_CONTENT" | vault policy write "$POLICY_NAME" -

# Check if role is already created
if vault read -format=json "auth/approle/role/$ROLE_NAME" > /dev/null 2>&1; then
  echo "[+] Role AppRole '$ROLE_NAME' already existing."
else
  echo "[+] Creating role AppRole '$ROLE_NAME'..."
  vault write "auth/approle/role/$ROLE_NAME" \
    token_policies="$POLICY_NAME" \
    token_ttl="3600" \
    token_max_ttl="7200"
fi

# Get role_id (fixed for the role)
ROLE_ID=$(vault read -field=role_id "auth/approle/role/$ROLE_NAME/role-id")

# Create new secret_id (this is always one-time-use)
SECRET_ID=$(vault write -f -field=secret_id "auth/approle/role/$ROLE_NAME/secret-id")

# Output
echo ""
echo "[+] AppRole successfully configured:"
echo "export VAULT_ROLE_ID=\"$ROLE_ID\""
echo "export VAULT_SECRET_ID=\"$SECRET_ID\""

# Configure OIDC if credentials are provided
if [ -n "$OIDC_DISCOVERY_URL" ] && [ -n "$OIDC_CLIENT_ID" ] && [ -n "$OIDC_CLIENT_SECRET" ]; then
  echo ""
  echo "[+] Configuring OIDC authentication..."
  
  # Check if OIDC auth method is already enabled
  if vault auth list -format=json | jq -e '."oidc/"' > /dev/null 2>&1; then
    echo "[+] Auth method OIDC already enabled."
  else
    echo "[+] Enabling auth method OIDC..."
    vault auth enable oidc
  fi
  
  # Configure OIDC
  echo "[+] Configuring OIDC settings..."
  vault write auth/oidc/config \
    oidc_discovery_url="$OIDC_DISCOVERY_URL" \
    oidc_client_id="$OIDC_CLIENT_ID" \
    oidc_client_secret="$OIDC_CLIENT_SECRET" \
    default_role="reader"
  
  # Create reader policy
  echo "[+] Creating reader policy..."
  vault policy write reader - <<EOF
path "ansible/data/*" {
  capabilities = ["read", "list"]
}

path "terraform/data/*" {
  capabilities = ["read", "list"]
}

path "cross/data/*" {
  capabilities = ["read", "list"]
}
EOF
  
  # Create admin policy
  echo "[+] Creating admin policy..."
  vault policy write admin - <<EOF
path "ansible/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "terraform/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "cross/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/*" {
  capabilities = ["read", "list"]
}

path "auth/*" {
  capabilities = ["read", "list"]
}
EOF
  
  # Create OIDC reader role
  echo "[+] Creating OIDC reader role..."
  vault write auth/oidc/role/reader \
    bound_audiences="$OIDC_CLIENT_ID" \
    allowed_redirect_uris="https://vault.local.ildoc.it/ui/vault/auth/oidc/oidc/callback" \
    user_claim="sub" \
    policies="default,reader" \
    groups_claim="groups" \
    ttl="1h"
  
  # Create OIDC admin role
  echo "[+] Creating OIDC admin role..."
  
  # Use wget (already available in Alpine)
  wget --post-data='{
    "bound_audiences": "'"$OIDC_CLIENT_ID"'",
    "allowed_redirect_uris": ["https://vault.local.ildoc.it/ui/vault/auth/oidc/oidc/callback"],
    "user_claim": "sub",
    "policies": ["default", "admin"],
    "groups_claim": "groups",
    "bound_claims": {
      "groups": ["vault-admins"]
    },
    "ttl": "8h"
  }' \
    --header="X-Vault-Token: $VAULT_TOKEN" \
    --header="Content-Type: application/json" \
    -O - \
    "${VAULT_ADDR}/v1/auth/oidc/role/admin" 2>&1 || true
  
  echo ""
  echo "[+] OIDC configuration completed!"
  echo "[+] Create groups in Authentik: 'vault-admins' and 'vault-readers'"
fi
