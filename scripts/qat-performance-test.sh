#!/bin/bash

# QAT Engine v2.0.0 Performance Test für C3xxx
# Testet ob Hardware-Beschleunigung wirklich funktioniert

set -e

echo "=== QAT Engine v2.0.0 Performance Test (C3xxx) ==="
echo "Hardware: Intel Atom C3000 mit QAT"
echo "Engine Version: $(openssl engine -t qatengine 2>&1 | head -1)"
echo ""

# Test-Parameter
TEST_DURATION=3
BLOCK_SIZE=8192

echo "📊 Test-Konfiguration:"
echo "   • Duration: ${TEST_DURATION}s pro Test"
echo "   • Block Size: ${BLOCK_SIZE} bytes"
echo "   • Algorithmus: AES-256-GCM (häufigster Gateway-Use-Case)"
echo ""

# Test 1: CPU-Only Baseline
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣ CPU-Only Baseline (ohne QAT)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CPU_RESULT=$(openssl speed -evp aes-256-gcm -bytes $BLOCK_SIZE -seconds $TEST_DURATION 2>&1 | grep "aes-256-gcm" | tail -1)
echo "$CPU_RESULT"
CPU_SPEED=$(echo "$CPU_RESULT" | awk '{print $2}')
echo "→ CPU Performance: ${CPU_SPEED} ops/sec"
echo ""

# Test 2: QAT Hardware-Beschleunigung
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣ QAT Hardware Acceleration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Prüfe ob QAT Device aktiv ist
if lspci | grep -q "QuickAssist.*Virtual"; then
    echo "✅ QAT VFs erkannt: $(lspci | grep -c 'QuickAssist.*Virtual') aktiv"
else
    echo "⚠️  Keine QAT VFs gefunden - teste trotzdem..."
fi

QAT_RESULT=$(openssl speed -engine qatengine -elapsed -evp aes-256-gcm -bytes $BLOCK_SIZE -seconds $TEST_DURATION 2>&1 | grep "aes-256-gcm" | tail -1)
echo "$QAT_RESULT"
QAT_SPEED=$(echo "$QAT_RESULT" | awk '{print $2}')
echo "→ QAT Performance: ${QAT_SPEED} ops/sec"
echo ""

# Performance-Vergleich
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 Performance-Vergleich"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -z "$CPU_SPEED" ] && [ ! -z "$QAT_SPEED" ]; then
    SPEEDUP=$(echo "scale=2; $QAT_SPEED / $CPU_SPEED" | bc)
    IMPROVEMENT=$(echo "scale=1; ($QAT_SPEED - $CPU_SPEED) / $CPU_SPEED * 100" | bc)
    
    echo "CPU-Only:     ${CPU_SPEED} ops/sec"
    echo "QAT-Hardware: ${QAT_SPEED} ops/sec"
    echo ""
    echo "🚀 Speedup Factor: ${SPEEDUP}x"
    echo "📊 Performance Gain: +${IMPROVEMENT}%"
    echo ""
    
    # Bewertung
    if (( $(echo "$SPEEDUP > 2.0" | bc -l) )); then
        echo "✅ EXZELLENT: QAT Hardware-Beschleunigung funktioniert perfekt!"
        echo "   Für Gateway-Workloads (VPN, HTTPS) sehr gut geeignet."
    elif (( $(echo "$SPEEDUP > 1.2" | bc -l) )); then
        echo "✅ GUT: QAT Hardware-Beschleunigung funktioniert!"
        echo "   Merkbarer Performance-Gewinn für Crypto-Operationen."
    elif (( $(echo "$SPEEDUP > 1.0" | bc -l) )); then
        echo "⚠️  MODERAT: Leichte Verbesserung durch QAT."
        echo "   Möglicherweise limitiert durch kleine Test-Größen."
    else
        echo "❌ PROBLEM: QAT langsamer als CPU!"
        echo "   Prüfe Driver-Konfiguration und VF-Zuordnung."
    fi
else
    echo "❌ Konnte Performance nicht vergleichen"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣ Zusätzliche Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# RSA Test (wichtig für TLS Handshakes)
echo ""
echo "🔐 RSA-2048 Test (TLS Handshake Performance):"
echo "   CPU-Only:"
openssl speed rsa2048 -elapsed -seconds 2 2>&1 | grep "^rsa" | head -1
echo "   QAT-Hardware:"
openssl speed -engine qatengine rsa2048 -elapsed -seconds 2 2>&1 | grep "^rsa" | head -1

# ECDSA Test (moderne TLS)
echo ""
echo "🔑 ECDSA P-256 Test (moderne TLS Performance):"
echo "   CPU-Only:"
openssl speed ecdsap256 -elapsed -seconds 2 2>&1 | grep "^256" | head -1
echo "   QAT-Hardware:"  
openssl speed -engine qatengine ecdsap256 -elapsed -seconds 2 2>&1 | grep "^256" | head -1

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣ QAT Hardware Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VF Status:"
lspci | grep "QuickAssist.*Virtual" | wc -l | awk '{print "   VFs aktiv: " $1 "/16"}'
echo ""
echo "Kernel Messages (letzte QAT-Events):"
dmesg | grep -i qat | tail -5 | sed 's/^/   /'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Performance Test Abgeschlossen!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💾 Ergebnis gespeichert in /tmp/qat-perf-test-$(date +%Y%m%d-%H%M%S).log"

# Speichere Ergebnis
cat > /tmp/qat-perf-test-$(date +%Y%m%d-%H%M%S).log << EOF
QAT Engine v2.0.0 Performance Test
Date: $(date)
Hardware: Intel Atom C3000 (C3xxx)

AES-256-GCM Results:
CPU-Only:     ${CPU_SPEED} ops/sec
QAT-Hardware: ${QAT_SPEED} ops/sec
Speedup:      ${SPEEDUP}x
Improvement:  +${IMPROVEMENT}%

Status: $(if (( $(echo "$SPEEDUP > 1.2" | bc -l) )); then echo "PASS - QAT funktioniert"; else echo "CHECK - Needs Investigation"; fi)
EOF

echo ""
echo "🔧 Fallback-Plan (falls Performance ungenügend):"
echo "   1. Legacy QAT Driver testen (QAT.L.4.28.0)"
echo "   2. VF-Konfiguration optimieren"
echo "   3. Kernel-Parameter tunen"
echo "   → Dokumentiert in /root/PVE-atom-node/docs/"
