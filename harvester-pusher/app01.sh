#!/bin/sh
set -e

# Leggi username e password dalle secret montate
USER=$(cat /secrets/username)
PASS=$(cat /secrets/password)

# Ottieni token da Harvester
TOKEN=$(curl -sk -X POST https://vip-hrv-test.site05.nivolapiemonte.it/v3-public/localProviders/local* \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USER\",\"password\":\"$PASS\"}" | jq -r .token)

# Interroga API Harvester per le VM
RESPONSE=$(curl -sk -H "Authorization: Bearer $TOKEN" \
https://vip-hrv-test.site05.nivolapiemonte.it/v1/harvester/kubevirt.io.virtualmachines)

# Parsa le metriche e le invia una per una al pushgateway, usando il nome della VM come etichetta 'instance'.
# Questo crea un gruppo di metriche separato per ogni VM, come raccomandato dalla documentazione del pushgateway.
echo "$RESPONSE" | jq -r '
.data[] |
{
  name: .metadata.name,
  phase: .status.printableStatus,
  agentReachability: (
    ( .status.conditions // [] | map(select(.type == "AgentConnected")) | .[0]? ) as $cond
    | if ($cond != null and $cond.status == "True") then
        1
      else
        0
      end
  )
} |
# Prepara una linea per ogni VM con: "nome_vm metrica"
"\(.name) harvester_vm_agent_reachable{phase=\"\(.phase)\"} \(.agentReachability)"
' | while IFS= read -r line; do
    # Estrai il nome della VM (la prima parola) e il corpo della metrica (il resto della linea)
    instance_name=$(echo "$line" | cut -d' ' -f1)
    metric_body=$(echo "$line" | cut -d' ' -f2-)

    # Invia la metrica al pushgateway, usando un gruppo per ogni istanza
    echo "$metric_body" | curl --data-binary @- "http://pushgateway.cattle-monitoring-system.svc.cluster.local:9091/metrics/job/harvester-vm-health/instance/$instance_name"
done
