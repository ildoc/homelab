#!/usr/bin/env bash
# Genera i secret Vault necessari per Matrix Authentication Service.
# Uso: ./scripts/matrix-mas-bootstrap-secrets.sh
set -euo pipefail

IMAGE="${MAS_IMAGE:-ghcr.io/element-hq/matrix-authentication-service:1.23.0}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> Genero configurazione MAS con ${IMAGE}"
docker run --rm "$IMAGE" config generate >"$WORKDIR/full.yaml"

python3 - "$WORKDIR" <<'PY'
import pathlib, secrets, sys, yaml

workdir = pathlib.Path(sys.argv[1])
full = yaml.safe_load((workdir / "full.yaml").read_text())

encryption = full["secrets"]["encryption"]
keys = full["secrets"]["keys"]
matrix_secret = full["matrix"]["secret"]
postgres_password = secrets.token_urlsafe(32)

keys_yaml = yaml.safe_dump(keys, default_flow_style=False)

(workdir / "mas_keys.yaml").write_text(keys_yaml)
(workdir / "vault.env").write_text(
    "\n".join(
        [
            f"MAS_ENCRYPTION={encryption}",
            f"MAS_MATRIX_SECRET={matrix_secret}",
            f"MAS_POSTGRES_PASSWORD={postgres_password}",
            "",
        ]
    )
)

print("==> Valori generati (NON committare):")
print(f"  mas_encryption      = {encryption}")
print(f"  mas_matrix_secret   = {matrix_secret}")
print(f"  mas_postgres_password = {postgres_password}")
print(f"  mas_keys_yaml       = {workdir / 'mas_keys.yaml'} ({len(keys)} keys)")
print()
print("==> Comandi Vault suggeriti:")
print()
print("# Secret cross (postgres MAS) — merge con le chiavi esistenti")
print("vault kv patch cross/data/apps/matrix \\")
print(f"  mas_postgres_password='{postgres_password}'")
print()
print("# Secret k8s (MAS crypto + shared secret con Synapse)")
print("vault kv patch k8s/data/apps/matrix \\")
print(f"  mas_encryption='{encryption}' \\")
print(f"  mas_matrix_secret='{matrix_secret}' \\")
print(f"  mas_oidc_client_secret='<CLIENT_SECRET_DA_AUTHENTIK>'")
print()
print("# Chiavi di firma (contenuto YAML della lista keys)")
print(f"vault kv patch k8s/data/apps/matrix mas_keys_yaml=@{workdir / 'mas_keys.yaml'}")
print()
print("Copia mas_keys.yaml in un posto sicuro prima che il temp dir venga cancellato:")
print(f"  cp {workdir / 'mas_keys.yaml'} /tmp/mas_keys.yaml")
PY

cp "$WORKDIR/mas_keys.yaml" /tmp/mas_keys.yaml
echo "==> Copia di sicurezza: /tmp/mas_keys.yaml"
echo "Fatto. Completa Authentik e poi esegui i comandi vault sopra."
