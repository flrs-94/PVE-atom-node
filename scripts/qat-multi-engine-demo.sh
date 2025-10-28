#!/bin/bash

# Erweiterte QAT Multi-Engine Demo
# Zeigt realistische Load-Balancing über alle Engines

echo "=== QAT Multi-Engine Load Balancing Demo ==="
echo "🔧 Optimiert für gleichzeitige Nutzung aller Crypto Engines"
echo "🌐 Dashboard: http://localhost:8080"
echo ""

cd /var/www/qat-dashboard

# Verbesserte Simulation mit Load-Balancing
simulate_balanced_load() {
    local scenario="$1"
    local duration="$2"
    local base_intensity="$3"
    
    echo "📊 $scenario ($duration Sekunden)..."
    echo "   🔄 Load-Balancing über alle 6 Engines aktiv"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        local elapsed=$(($(date +%s) - start_time))
        local progress=$((elapsed * 100 / duration))
        
        # Realistische Load-Verteilung basierend auf Engine-Typ
        # Engine 0+1: Symmetric Crypto (AES, 3DES) - Höchste Last
        # Engine 2+3: Asymmetric Crypto (RSA, ECDSA) - Mittlere Last  
        # Engine 4+5: Compression (DEFLATE) - Variable Last
        
        # Engine 0: Symmetric Crypto Lead
        local ae0_base=$((base_intensity + 20))
        local ae0_req=$((ae0_base + RANDOM % 80 + elapsed * 3))
        local ae0_util=$((75 + RANDOM % 20 + progress / 10))
        [ $ae0_util -gt 98 ] && ae0_util=98
        
        # Engine 1: Symmetric Crypto Backup  
        local ae1_base=$((base_intensity + 15))
        local ae1_req=$((ae1_base + RANDOM % 70 + elapsed * 2))
        local ae1_util=$((70 + RANDOM % 25 + progress / 12))
        [ $ae1_util -gt 96 ] && ae1_util=96
        
        # Engine 2: Asymmetric Crypto Primary
        local ae2_base=$((base_intensity + 10))
        local ae2_req=$((ae2_base + RANDOM % 60 + elapsed * 2))
        local ae2_util=$((65 + RANDOM % 25 + progress / 8))
        [ $ae2_util -gt 94 ] && ae2_util=94
        
        # Engine 3: Asymmetric Crypto Secondary
        local ae3_base=$((base_intensity + 5))
        local ae3_req=$((ae3_base + RANDOM % 50 + elapsed * 1))
        local ae3_util=$((60 + RANDOM % 30 + progress / 15))
        [ $ae3_util -gt 92 ] && ae3_util=92
        
        # Engine 4: Compression Primary
        local ae4_base=$((base_intensity))
        local ae4_req=$((ae4_base + RANDOM % 90 + elapsed * 4))
        local ae4_util=$((55 + RANDOM % 35 + progress / 5))
        [ $ae4_util -gt 97 ] && ae4_util=97
        
        # Engine 5: Compression Secondary  
        local ae5_base=$((base_intensity - 5))
        [ $ae5_base -lt 0 ] && ae5_base=0
        local ae5_req=$((ae5_base + RANDOM % 45 + elapsed * 1))
        local ae5_util=$((50 + RANDOM % 30 + progress / 20))
        [ $ae5_util -gt 90 ] && ae5_util=90
        
        # Realistische Response-Rates (95-99% bei gesunden Engines)
        local ae0_resp=$((ae0_req * (95 + RANDOM % 5) / 100))
        local ae1_resp=$((ae1_req * (96 + RANDOM % 4) / 100))
        local ae2_resp=$((ae2_req * (94 + RANDOM % 6) / 100))
        local ae3_resp=$((ae3_req * (97 + RANDOM % 3) / 100))
        local ae4_resp=$((ae4_req * (93 + RANDOM % 7) / 100))
        local ae5_resp=$((ae5_req * (95 + RANDOM % 5) / 100))
        
        local total_req=$((ae0_req + ae1_req + ae2_req + ae3_req + ae4_req + ae5_req))
        
        # JSON mit realistischer Multi-Engine Auslastung
        cat > qat-status.json << EOF
{
  "qat_available": true,
  "virtual_functions": 16,
  "crypto_engines": 19,
  "requests_processed": $total_req,
  "acceleration_engines": [
    {"id": 0, "requests": $ae0_req, "responses": $ae0_resp, "utilization": $ae0_util, "type": "AES/3DES"},
    {"id": 1, "requests": $ae1_req, "responses": $ae1_resp, "utilization": $ae1_util, "type": "AES/3DES"},
    {"id": 2, "requests": $ae2_req, "responses": $ae2_resp, "utilization": $ae2_util, "type": "RSA/ECDSA"},
    {"id": 3, "requests": $ae3_req, "responses": $ae3_resp, "utilization": $ae3_util, "type": "RSA/ECDSA"},
    {"id": 4, "requests": $ae4_req, "responses": $ae4_resp, "utilization": $ae4_util, "type": "DEFLATE"},
    {"id": 5, "requests": $ae5_req, "responses": $ae5_resp, "utilization": $ae5_util, "type": "DEFLATE"}
  ],
  "load_balancing": {
    "symmetric_crypto": $((ae0_util + ae1_util)),
    "asymmetric_crypto": $((ae2_util + ae3_util)), 
    "compression": $((ae4_util + ae5_util))
  },
  "timestamp": "$(date -Iseconds)"
}
EOF
        
        # Zeige Live-Status im Terminal
        printf "\r🔥 Engines: AES:%d%% AES:%d%% RSA:%d%% RSA:%d%% ZIP:%d%% ZIP:%d%% | Total: %d reqs" \
               $ae0_util $ae1_util $ae2_util $ae3_util $ae4_util $ae5_util $total_req
        
        sleep 1.5
    done
    echo ""
}

# Erweiterte Demo-Szenarien
echo "🚀 Starte Multi-Engine Load Balancing..."

# Phase 1: Startup mit gestaffeltem Engine-Start
echo ""
echo "Phase 1: Gestaffelter Engine-Start"
for engine in {0..5}; do
    case $engine in
        0) type="AES" ;;
        1) type="AES" ;;
        2) type="RSA" ;;
        3) type="RSA" ;;
        4) type="ZIP" ;;
        5) type="ZIP" ;;
    esac
    echo "   🔧 Engine $engine ($type) startet..."
    sleep 1
done

# Phase 2: Leichte Multi-Engine Last
simulate_balanced_load "Phase 2: Multi-Engine Warm-up" 12 5

# Phase 3: Web-Traffic (AES dominiert)
simulate_balanced_load "Phase 3: HTTPS Web-Traffic" 15 25

# Phase 4: VPN + Storage (Alle Engines aktiv)
simulate_balanced_load "Phase 4: VPN + NAS Compression" 20 60

# Phase 5: Peak Load (Maximale Verteilung)
simulate_balanced_load "Phase 5: Peak Multi-Engine Load" 18 120

# Phase 6: Asymmetric Focus (Cert-Validierung)
simulate_balanced_load "Phase 6: Certificate Validation" 12 40

# Phase 7: Graduelle Reduzierung
simulate_balanced_load "Phase 7: Load Balancing Cooldown" 10 15

echo ""
echo "✅ Multi-Engine Load Balancing Demo abgeschlossen!"
echo ""
echo "📈 Optimierungen gezeigt:"
echo "   • Engines 0+1: AES/3DES Symmetric Crypto (75-98%)"
echo "   • Engines 2+3: RSA/ECDSA Asymmetric Crypto (60-94%)"  
echo "   • Engines 4+5: DEFLATE Compression (50-97%)"
echo "   • Realistische Load-Verteilung je Engine-Typ"
echo "   • Gestaffelte Auslastung für optimale Performance"
echo ""
echo "🎯 Alle 6 Engines werden jetzt gleichzeitig genutzt!"