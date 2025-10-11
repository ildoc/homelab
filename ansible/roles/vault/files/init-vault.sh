#!/bin/sh
set -euo pipefail

# CONFIGURATIONS
POLICY_NAME="ci-policy"
ROLE_NAME="ci-role"
SECRET_PATHS="ansible cross kubernetes opentofu terraform"
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:?VAULT_TOKEN missing}"

# OIDC Configuration (optional - set via env vars)
OIDC_DISCOVERY_URL="${OIDC_DISCOVERY_URL:-}"
OIDC_CLIENT_ID="${OIDC_CLIENT_ID:-}"
OIDC_CLIENT_SECRET="${OIDC_CLIENT_SECRET:-}"
OIDC_APP_SLUG="${OIDC_APP_SLUG:-vault}"

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
  
  # Configure OIDC with correct discovery URL format
  echo "[+] Configuring OIDC settings..."
  vault write auth/oidc/config \
    oidc_discovery_url="${OIDC_DISCOVERY_URL}/application/o/${OIDC_APP_SLUG}/" \
    oidc_client_id="$OIDC_CLIENT_ID" \
    oidc_client_secret="$OIDC_CLIENT_SECRET" \
    default_role="reader"
  
  # Create reader policy dynamically
  echo "[+] Creating reader policy..."
  READER_POLICY=""
  for SECRET_PATH in $SECRET_PATHS; do
    READER_POLICY="$READER_POLICY
path \"$SECRET_PATH/data/*\" {
  capabilities = [\"read\", \"list\"]
}

path \"$SECRET_PATH/metadata/*\" {
  capabilities = [\"read\", \"list\"]
}"
  done
  
  echo "$READER_POLICY" | vault policy write reader -
  
  # Create admin policy with full access to everything
  echo "[+] Creating admin policy..."
  vault policy write admin - <<EOF
# Full access to all secret engines (current and future)
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Explicit deny on sensitive operations if needed
# path "sys/raw/*" {
#   capabilities = ["deny"]
# }
EOF
  
  # Create OIDC reader role with all required redirect URIs
  echo "[+] Creating OIDC reader role..."
  vault write auth/oidc/role/reader \
    bound_audiences="$OIDC_CLIENT_ID" \
    allowed_redirect_uris="https://vault.local.ildoc.it/ui/vault/auth/oidc/oidc/callback" \
    allowed_redirect_uris="https://vault.local.ildoc.it/oidc/callback" \
    allowed_redirect_uris="http://localhost:8250/oidc/callback" \
    user_claim="sub" \
    policies="default,reader" \
    groups_claim="groups" \
    oidc_scopes="openid,profile,email" \
    ttl="1h"
  
  # Create OIDC admin role
  echo "[+] Creating OIDC admin role..."
  vault write auth/oidc/role/admin \
    bound_audiences="$OIDC_CLIENT_ID" \
    allowed_redirect_uris="https://vault.local.ildoc.it/ui/vault/auth/oidc/oidc/callback" \
    allowed_redirect_uris="https://vault.local.ildoc.it/oidc/callback" \
    allowed_redirect_uris="http://localhost:8250/oidc/callback" \
    user_claim="sub" \
    policies="default,admin" \
    groups_claim="groups" \
    oidc_scopes="openid,profile,email" \
    ttl="8h"
  
  # Get OIDC accessor for group aliases
  echo "[+] Getting OIDC accessor..."
  OIDC_ACCESSOR=$(vault auth list -format=json | jq -r '.["oidc/"].accessor')
  echo "[+] OIDC Accessor: $OIDC_ACCESSOR"
  
  # Create external group for vault-admins
  echo "[+] Creating external group 'vault-admins'..."
  if vault read identity/group/name/vault-admins > /dev/null 2>&1; then
    # Check if it's external type
    GROUP_TYPE=$(vault read -field=type identity/group/name/vault-admins)
    if [ "$GROUP_TYPE" = "internal" ]; then
      echo "[!] Group 'vault-admins' exists but is 'internal' type. Deleting and recreating as 'external'..."
      vault delete identity/group/name/vault-admins
      ADMINS_GROUP_ID=$(vault write -format=json identity/group \
        name="vault-admins" \
        policies="admin" \
        type="external" | jq -r '.data.id')
      echo "[+] Created group 'vault-admins' with ID: $ADMINS_GROUP_ID"
    else
      echo "[+] Group 'vault-admins' already exists as external type"
      ADMINS_GROUP_ID=$(vault read -field=id identity/group/name/vault-admins)
      # Update policies in case they changed
      vault write identity/group/id/$ADMINS_GROUP_ID policies="admin"
    fi
  else
    ADMINS_GROUP_ID=$(vault write -format=json identity/group \
      name="vault-admins" \
      policies="admin" \
      type="external" | jq -r '.data.id')
    echo "[+] Created group 'vault-admins' with ID: $ADMINS_GROUP_ID"
  fi
  
  # Create group alias for vault-admins
  echo "[+] Creating group alias for 'vault-admins'..."
  if vault list identity/group-alias/id 2>/dev/null | grep -q .; then
    # Check if alias already exists
    EXISTING_ALIAS=$(vault list -format=json identity/group-alias/id 2>/dev/null | jq -r '.[]' | while read alias_id; do
      ALIAS_INFO=$(vault read -format=json "identity/group-alias/id/$alias_id")
      ALIAS_NAME=$(echo "$ALIAS_INFO" | jq -r '.data.name')
      ALIAS_CANONICAL=$(echo "$ALIAS_INFO" | jq -r '.data.canonical_id')
      if [ "$ALIAS_NAME" = "vault-admins" ] && [ "$ALIAS_CANONICAL" = "$ADMINS_GROUP_ID" ]; then
        echo "$alias_id"
        break
      fi
    done)
    
    if [ -n "$EXISTING_ALIAS" ]; then
      echo "[+] Group alias for 'vault-admins' already exists"
    else
      vault write identity/group-alias \
        name="vault-admins" \
        mount_accessor="$OIDC_ACCESSOR" \
        canonical_id="$ADMINS_GROUP_ID"
      echo "[+] Created group alias for 'vault-admins'"
    fi
  else
    vault write identity/group-alias \
      name="vault-admins" \
      mount_accessor="$OIDC_ACCESSOR" \
      canonical_id="$ADMINS_GROUP_ID"
    echo "[+] Created group alias for 'vault-admins'"
  fi
  
  # Create external group for vault-readers
  echo "[+] Creating external group 'vault-readers'..."
  if vault read identity/group/name/vault-readers > /dev/null 2>&1; then
    # Check if it's external type
    GROUP_TYPE=$(vault read -field=type identity/group/name/vault-readers)
    if [ "$GROUP_TYPE" = "internal" ]; then
      echo "[!] Group 'vault-readers' exists but is 'internal' type. Deleting and recreating as 'external'..."
      vault delete identity/group/name/vault-readers
      READERS_GROUP_ID=$(vault write -format=json identity/group \
        name="vault-readers" \
        policies="reader" \
        type="external" | jq -r '.data.id')
      echo "[+] Created group 'vault-readers' with ID: $READERS_GROUP_ID"
    else
      echo "[+] Group 'vault-readers' already exists as external type"
      READERS_GROUP_ID=$(vault read -field=id identity/group/name/vault-readers)
      # Update policies in case they changed
      vault write identity/group/id/$READERS_GROUP_ID policies="reader"
    fi
  else
    READERS_GROUP_ID=$(vault write -format=json identity/group \
      name="vault-readers" \
      policies="reader" \
      type="external" | jq -r '.data.id')
    echo "[+] Created group 'vault-readers' with ID: $READERS_GROUP_ID"
  fi
  
  # Create group alias for vault-readers
  echo "[+] Creating group alias for 'vault-readers'..."
  if vault list identity/group-alias/id 2>/dev/null | grep -q .; then
    # Check if alias already exists
    EXISTING_ALIAS=$(vault list -format=json identity/group-alias/id 2>/dev/null | jq -r '.[]' | while read alias_id; do
      ALIAS_INFO=$(vault read -format=json "identity/group-alias/id/$alias_id")
      ALIAS_NAME=$(echo "$ALIAS_INFO" | jq -r '.data.name')
      ALIAS_CANONICAL=$(echo "$ALIAS_INFO" | jq -r '.data.canonical_id')
      if [ "$ALIAS_NAME" = "vault-readers" ] && [ "$ALIAS_CANONICAL" = "$READERS_GROUP_ID" ]; then
        echo "$alias_id"
        break
      fi
    done)
    
    if [ -n "$EXISTING_ALIAS" ]; then
      echo "[+] Group alias for 'vault-readers' already exists"
    else
      vault write identity/group-alias \
        name="vault-readers" \
        mount_accessor="$OIDC_ACCESSOR" \
        canonical_id="$READERS_GROUP_ID"
      echo "[+] Created group alias for 'vault-readers'"
    fi
  else
    vault write identity/group-alias \
      name="vault-readers" \
      mount_accessor="$OIDC_ACCESSOR" \
      canonical_id="$READERS_GROUP_ID"
    echo "[+] Created group alias for 'vault-readers'"
  fi
  
  echo ""
  echo "[+] OIDC configuration completed!"
  echo ""
  echo "=== CONFIGURATION SUMMARY ==="
  echo "OIDC Accessor: $OIDC_ACCESSOR"
  echo "vault-admins Group ID: $ADMINS_GROUP_ID"
  echo "vault-readers Group ID: $READERS_GROUP_ID"
  echo ""
  echo "=== NEXT STEPS IN AUTHENTIK ==="
  echo "1. Go to your Vault provider in Authentik (https://auth.ildoc.it)"
  echo "2. Verify these STRICT Redirect URIs are configured:"
  echo "   - https://vault.local.ildoc.it/ui/vault/auth/oidc/oidc/callback"
  echo "   - https://vault.local.ildoc.it/oidc/callback"
  echo "   - http://localhost:8250/oidc/callback"
  echo ""
  echo "3. Under 'Advanced protocol settings', verify the scope mapping:"
  echo "   - authentik default OAuth Mapping: OpenID 'profile'"
  echo ""
  echo "4. Verify these groups exist in Authentik:"
  echo "   - vault-admins (for admin access)"
  echo "   - vault-readers (for read-only access)"
  echo ""
  echo "5. Add your user to the 'vault-admins' group"
  echo ""
  echo "=== TESTING ==="
  echo "Test login with: vault login -method=oidc role=\"reader\""
  echo ""
  echo "After login, verify your groups with:"
  echo "vault token lookup | grep policies"
  echo "vault read auth/token/lookup-self"
fi
