#!/bin/sh
set -e

echo "--- Starting metrics push script ---"

# Leggi le configurazioni dal secret montato
echo "Reading secrets from /secrets..."
USERNAME=$(cat /secrets/username)
PASSWORD=$(cat /secrets/password)
HARVESTER_ENDPOINT=$(cat /secrets/harvester-endpoint)
echo "Harvester endpoint: $HARVESTER_ENDPOINT"
echo "Username: $USERNAME"

# Costruisci gli URL delle API
# Endpoint di autenticazione corretto per Harvester/Rancher API
LOGIN_URL="$HARVESTER_ENDPOINT/v3-public/localProviders/local?action=login"
METRICS_URL="$HARVESTER_ENDPOINT/v1/harvester/kubevirt.io.virtualmachines"

echo "Attempting to get token from: $LOGIN_URL"
# Ottieni token da Harvester e cattura la risposta per il debug
TOKEN_RESPONSE=$(curl -s -k -X POST "$LOGIN_URL" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}")

TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token')

# Controlla se il token è stato ottenuto correttamente
if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to retrieve token."
  echo "Response from server: $TOKEN_RESPONSE"
  exit 1
fi
echo "Successfully retrieved token."

# Recupera le metriche
echo "Attempting to get metrics from: $METRICS_URL"
METRICS=$(curl -s -k -H "Authorization: Bearer $TOKEN" "$METRICS_URL" | \
jq -r '
  .data[] |
  {
    name: .metadata.name,
    phase: .status.printableStatus,
    reachable: (
      (.status.conditions // [] | map(select(.type == "AgentConnected")) | .[0]?.status) == "True"
    )
  } |
  "harvester_vm_reachable{name=\"" + .name + "\",phase=\"" + .phase + "\"} " + (if .reachable then "1" else "0" end)
')

if [ -z "$METRICS" ]; then
    echo "WARNING: No metrics were generated. The response from the metrics endpoint might be empty or malformed."
else
    echo "Successfully generated metrics."
fi

# Log del contenuto delle metriche prima dell'invio
echo "--- BEGIN METRICS CONTENT ---"
echo "$METRICS"
echo "--- END METRICS CONTENT ---"

# Invia le metriche al pushgateway usando l'indirizzo del servizio in-cluster
PUSHGATEWAY_URL="http://my-pushgateway-prometheus-pushgateway:9091/metrics/job/harvester-vm-status"
echo "Pushing metrics to: $PUSHGATEWAY_URL"
echo "$METRICS" | curl --data-binary @- "$PUSHGATEWAY_URL"

echo
echo "--- Metrics push script finished successfully ---"
