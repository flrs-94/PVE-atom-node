#!/bin/bash

# Einfaches QAT Web-Monitoring via Custom HTML-Dashboard
# Für Proxmox VE - Sicherer Ansatz ohne Core-Modification

echo "=== QAT Web-Dashboard Setup ==="
echo "Zeitstempel: $(date)"

# Erstelle Web-Dashboard Verzeichnis
mkdir -p /var/www/qat-dashboard
cd /var/www/qat-dashboard

# Erstelle QAT Status API (CGI-basiert)
cat > qat-api.cgi << 'EOF'
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
EOF

chmod +x qat-api.cgi

# Erstelle HTML Dashboard
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Intel QAT Monitoring - PVE-atom-node</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #2c3e50, #34495e);
            color: white;
            padding: 20px;
            text-align: center;
        }
        
        .header h1 {
            margin: 0;
            font-size: 2.5em;
        }
        
        .subtitle {
            margin-top: 5px;
            opacity: 0.8;
        }
        
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            padding: 30px;
        }
        
        .card {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            border-left: 4px solid #007bff;
        }
        
        .card h3 {
            margin-top: 0;
            color: #333;
        }
        
        .status-ok { border-left-color: #28a745; }
        .status-warning { border-left-color: #ffc107; }
        .status-error { border-left-color: #dc3545; }
        
        .progress-bar {
            width: 100%;
            height: 30px;
            background: #e9ecef;
            border-radius: 15px;
            overflow: hidden;
            margin: 10px 0;
        }
        
        .progress-fill {
            height: 100%;
            transition: width 0.5s ease;
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        
        .progress-low { background: linear-gradient(45deg, #28a745, #20c997); }
        .progress-medium { background: linear-gradient(45deg, #ffc107, #fd7e14); }
        .progress-high { background: linear-gradient(45deg, #dc3545, #e83e8c); }
        
        .engine-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 10px;
            margin-top: 15px;
        }
        
        .engine {
            background: white;
            padding: 10px;
            border-radius: 5px;
            text-align: center;
            border: 2px solid #e9ecef;
        }
        
        .engine.active { border-color: #28a745; }
        .engine.idle { border-color: #6c757d; }
        
        .metric {
            font-size: 2em;
            font-weight: bold;
            color: #007bff;
        }
        
        .loading {
            text-align: center;
            padding: 50px;
            color: #6c757d;
        }
        
        .refresh-indicator {
            position: fixed;
            top: 20px;
            right: 20px;
            background: #007bff;
            color: white;
            padding: 10px 15px;
            border-radius: 20px;
            font-size: 12px;
            opacity: 0;
            transition: opacity 0.3s;
        }
        
        .refresh-indicator.active { opacity: 1; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Intel QAT Hardware Acceleration</h1>
            <div class="subtitle">PVE-atom-node Gateway System</div>
        </div>
        
        <div id="dashboard" class="dashboard">
            <div class="loading">
                <h3>🔄 Lade QAT-Status...</h3>
            </div>
        </div>
    </div>
    
    <div id="refresh-indicator" class="refresh-indicator">Aktualisiere...</div>

    <script>
        let qatData = null;
        
        async function fetchQATStatus() {
            try {
                const indicator = document.getElementById('refresh-indicator');
                indicator.classList.add('active');
                
                const response = await fetch('./qat-api.cgi');
                const data = await response.json();
                qatData = data;
                updateDashboard();
                
                setTimeout(() => {
                    indicator.classList.remove('active');
                }, 500);
            } catch (error) {
                console.error('QAT Status Fehler:', error);
                showError();
            }
        }
        
        function updateDashboard() {
            if (!qatData) return;
            
            const dashboard = document.getElementById('dashboard');
            
            // Berechne Gesamt-Utilization
            let totalUtil = 0;
            if (qatData.acceleration_engines && qatData.acceleration_engines.length > 0) {
                const activeEngines = qatData.acceleration_engines.filter(e => e.requests > 0);
                if (activeEngines.length > 0) {
                    totalUtil = activeEngines.reduce((sum, e) => sum + e.utilization, 0) / activeEngines.length;
                }
            }
            
            const utilClass = totalUtil > 80 ? 'progress-high' : 
                             totalUtil > 50 ? 'progress-medium' : 'progress-low';
            
            const statusClass = qatData.qat_available ? 'status-ok' : 'status-error';
            
            dashboard.innerHTML = `
                <div class="card ${statusClass}">
                    <h3>📊 QAT Hardware Status</h3>
                    <div class="metric">${qatData.qat_available ? '✅ Verfügbar' : '❌ Nicht verfügbar'}</div>
                    <p><strong>Virtual Functions:</strong> ${qatData.virtual_functions} VFs</p>
                    <p><strong>Crypto Engines:</strong> ${qatData.crypto_engines}</p>
                    <p><strong>Letztes Update:</strong> ${new Date(qatData.timestamp).toLocaleTimeString()}</p>
                </div>
                
                <div class="card">
                    <h3>⚡ Gesamt-Auslastung</h3>
                    <div class="progress-bar">
                        <div class="progress-fill ${utilClass}" style="width: ${totalUtil}%">
                            ${Math.round(totalUtil)}%
                        </div>
                    </div>
                    <p><strong>Requests verarbeitet:</strong> ${qatData.requests_processed.toLocaleString()}</p>
                </div>
                
                <div class="card">
                    <h3>🔧 Acceleration Engines</h3>
                    <div class="engine-grid">
                        ${qatData.acceleration_engines.map(engine => `
                            <div class="engine ${engine.requests > 0 ? 'active' : 'idle'}">
                                <div><strong>AE${engine.id}</strong></div>
                                <div>${engine.requests.toLocaleString()} req</div>
                                <div>${Math.round(engine.utilization)}%</div>
                                <div style="font-size: 0.8em; color: ${engine.requests > 0 ? '#28a745' : '#6c757d'}">
                                    ${engine.requests > 0 ? 'Aktiv' : 'Idle'}
                                </div>
                            </div>
                        `).join('')}
                    </div>
                </div>
            `;
        }
        
        function showError() {
            const dashboard = document.getElementById('dashboard');
            dashboard.innerHTML = `
                <div class="card status-error">
                    <h3>❌ Verbindungsfehler</h3>
                    <p>QAT-Status konnte nicht abgerufen werden.</p>
                    <p>Prüfe ob die QAT-API verfügbar ist.</p>
                </div>
            `;
        }
        
        // Initial load
        fetchQATStatus();
        
        // Auto-refresh alle 5 Sekunden
        setInterval(fetchQATStatus, 5000);
    </script>
</body>
</html>
EOF

echo "✅ QAT Web-Dashboard erstellt!"
echo ""
echo "📁 Dashboard-Verzeichnis: /var/www/qat-dashboard/"
echo "🌐 Test lokal: file:///var/www/qat-dashboard/index.html"
echo ""
echo "🔧 Für Webserver-Integration:"
echo "nginx/apache: DocumentRoot auf /var/www/qat-dashboard"
echo "Port 8080: python3 -m http.server 8080"
echo ""
echo "📊 API-Test: ./qat-api.cgi"