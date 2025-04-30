#!/bin/bash
set -euo pipefail

# CONFIGURATIONS
POLICY_NAME="ansible-policy"
ROLE_NAME="ansible-role"
SECRET_PATH="ansible"
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:?VAULT_TOKEN mancante}"

# Install dependencies
apk add jq

echo "[+] Init Vault..."

# Check if secret engine is already enabled
if vault secrets list -format=json | jq -e ".[\"$SECRET_PATH/\"]"; then
  echo "[+] Secret engine '$SECRET_PATH/' already enabled."
else
  echo "[+] Enabling secret engine '$SECRET_PATH/' (kv-v2)..."
  vault secrets enable -path="$SECRET_PATH" -version=2 kv
fi

# Check if Approle auth method is already enabled
if vault auth list -format=json | jq -e '."approle/"'; then
  echo "[+] Auth method AppRole already enabled."
else
  echo "[+] Enabling auth method AppRole..."
  vault auth enable approle
fi

# Create or update policy
echo "[+] Writing policy '$POLICY_NAME'..."
cat <<EOF | vault policy write "$POLICY_NAME" -
path "$SECRET_PATH/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

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
