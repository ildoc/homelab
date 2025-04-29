#!/bin/bash
set -euo pipefail

# CONFIGURAZIONE
POLICY_NAME="ansible-policy"
ROLE_NAME="ansible-role"
SECRET_PATH="ansible"  # sarà montato come kv-v2
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:?VAULT_TOKEN mancante}"

apk add jq

echo "🟡 Inizializzazione Vault..."

# Check se il secret engine è già abilitato
if vault secrets list -format=json | jq -e ".[\"$SECRET_PATH/\"]"; then
  echo "✅ Secret engine '$SECRET_PATH/' già abilitato."
else
  echo "➕ Abilitazione secret engine '$SECRET_PATH/' (kv-v2)..."
  vault secrets enable -path="$SECRET_PATH" -version=2 kv
fi

# Check se l'auth method approle è già abilitato
if vault auth list -format=json | jq -e '."approle/"'; then
  echo "✅ Auth method AppRole già abilitato."
else
  echo "➕ Abilitazione auth method AppRole..."
  vault auth enable approle
fi

# Crea o aggiorna la policy
echo "📜 Scrittura policy '$POLICY_NAME'..."
cat <<EOF | vault policy write "$POLICY_NAME" -
path "$SECRET_PATH/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

# Check se il ruolo esiste già
if vault read -format=json "auth/approle/role/$ROLE_NAME" > /dev/null 2>&1; then
  echo "✅ Ruolo AppRole '$ROLE_NAME' già esistente."
else
  echo "➕ Creazione ruolo AppRole '$ROLE_NAME'..."
  vault write "auth/approle/role/$ROLE_NAME" \
    token_policies="$POLICY_NAME" \
    token_ttl="3600" \
    token_max_ttl="7200"
fi

# Recupera role_id (fisso per il ruolo)
ROLE_ID=$(vault read -field=role_id "auth/approle/role/$ROLE_NAME/role-id")

# Crea un nuovo secret_id (questo è sempre one-time-use)
SECRET_ID=$(vault write -f -field=secret_id "auth/approle/role/$ROLE_NAME/secret-id")

# Output
echo ""
echo "✅ AppRole configurato con successo:"
echo "export VAULT_ROLE_ID=\"$ROLE_ID\""
echo "export VAULT_SECRET_ID=\"$SECRET_ID\""
