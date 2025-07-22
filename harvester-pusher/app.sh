METRICS=$(curl -s -k -H "Authorization: Bearer $TOKEN" \
  "https://vip-hrv-test.site05.nivolapiemonte.it/v1/harvester/kubevirt.io.virtualmachines" | \
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
#echo $METRICS
echo "$METRICS" | curl --data-binary @- http://127.0.0.1:9091/metrics/job/harvester-vm-status