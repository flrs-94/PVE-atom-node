#!/bin/bash
echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

# QAT Status sammeln
QAT_AVAILABLE=false
VF_COUNT=0
CRYPTO_ENGINES=0
TOTAL_REQUESTS=0

if [ -f "/sys/bus/pci/devices/0000:01:00.0/sriov_numvfs" ]; then
    QAT_AVAILABLE=true
    VF_COUNT=$(cat /sys/bus/pci/devices/0000:01:00.0/sriov_numvfs 2>/dev/null || echo 0)
    CRYPTO_ENGINES=$(grep -c qat /proc/crypto 2>/dev/null || echo 0)
fi

# QAT Engine Status
ENGINES_JSON="[]"
if [ -f "/proc/qat" ]; then
    ENGINES_JSON=$(awk '
    BEGIN { print "[" }
    /^[[:space:]]*[0-9]+:/ {
        if (NR > 1) print ","
        gsub(/[[:space:]]+/, " ")
        split($0, parts, " ")
        id = substr(parts[1], 1, length(parts[1])-1)
        req = parts[2]
        resp = parts[3]
        util = (req > 0) ? (resp/req)*100 : 0
        printf "{\"id\":%d,\"requests\":%d,\"responses\":%d,\"utilization\":%.1f}", id, req, resp, util
        total += req
    }
    END { 
        print "]"
    }' /proc/qat 2>/dev/null || echo "[]")
fi

# JSON Response
cat << JSON
{
  "qat_available": $QAT_AVAILABLE,
  "virtual_functions": $VF_COUNT,
  "crypto_engines": $CRYPTO_ENGINES,
  "requests_processed": $TOTAL_REQUESTS,
  "acceleration_engines": $ENGINES_JSON,
  "timestamp": "$(date -Iseconds)"
}
JSON
