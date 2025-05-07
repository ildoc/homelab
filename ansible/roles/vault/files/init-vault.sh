#!/bin/sh
set -euo pipefail

# CONFIGURATIONS
POLICY_NAME="ci-policy"
ROLE_NAME="ci-role"
# Usa un array per i percorsi dei segreti
SECRET_PATHS="ansible terraform"
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:?VAULT_TOKEN missing}"

# Install dependencies
apk add jq

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
path "auth/token/create" {
  capabilities = ["update"]
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
