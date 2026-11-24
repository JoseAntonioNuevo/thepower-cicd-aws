#!/usr/bin/env bash
# Repite la misma consulta de prioridad baja en las versiones A y B de staging.
set -euo pipefail
base=${1:?Uso: bash scripts/consulta-baja.sh URL 200|500}
esperado=${2:?Indica el estado HTTP esperado para esta versión}
[[ "$esperado" == 200 || "$esperado" == 500 ]] || exit 2
cuerpo="$(mktemp)"
trap 'rm -f "$cuerpo"' EXIT
estado="$(curl -sS --connect-timeout 5 --max-time 20 --output "$cuerpo" --write-out '%{http_code}' \
  -H 'Content-Type: application/json' -d '{"texto":"Tengo una duda sobre los horarios"}' "${base%/}/clasificar")"
printf 'HTTP %s\n' "$estado"
jq '{request_id, version, prioridad: .resultado.prioridad, error}' "$cuerpo"
[[ "$estado" == "$esperado" ]]
jq -e --arg estado "$estado" '
  (.request_id | type == "string" and length > 0) and
  (if $estado == "200" then .resultado.prioridad == "baja" else .error == "error_interno" end)
' "$cuerpo" >/dev/null
