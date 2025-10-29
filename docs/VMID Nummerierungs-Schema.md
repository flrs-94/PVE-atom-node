VMID Nummerierungs-Schema 📊
┌─────────────────────────────────────────────────────────┐
│           PVE-atom-node VMID Struktur                  │
├─────────────────────────────────────────────────────────┤
│ 100-199: Core Infrastructure (Gateway, DNS, DHCP)      │
│   100: pfSense (Gateway Critical)      - AE1 (VF 3-6)  │
│   101: Backup pfSense (Failover)       - AE3 (VF 10)   │
│   110: Monitoring (Zabbix/Prometheus)  - No QAT       │
│                                                         │
│ 200-299: Storage & Backup                              │
│   200: TrueNAS SCALE (Primary Storage) - AE2 (VF 7-9)  │
│   201: Backup Storage VM               - AE5 (VF 14)   │
│   210: Proxmox Backup Server           - AE2 (VF 9)    │
│                                                         │
│ 300-399: Web & Applications                           │
│   300: Reverse Proxy (Nginx/Traefik)  - AE4 (VF 12)   │
│   301: Web Application Server          - AE4 (VF 13)   │
│   310: Database Server (PostgreSQL)    - No QAT       │
│                                                         │
│ 400-499: Development & Testing                        │
│   400: Docker Host                     - No QAT       │
│   410: Development Container           - AE5 (VF 15)   │
│                                                         │
│ 900-999: Testing / Staging                             │
│   900: Test VM 1                       - AE5 (VF 14-15)│
│   910: Staging Environment             - AE5           │
└─────────────────────────────────────────────────────────┘
Empfohlene Struktur 🎯

100-109: pfSense & Firewall
200-209: TrueNAS & Storage
300-309: Web Services
400-409: Databases
500-509: Monitoring
900-999: Test/Dev

Meine Empfehlung für dein Setup:
VMID 100: pfSense         # Gateway Critical, erste VM
VMID 200: TrueNAS SCALE   # Storage Primary
VMID 300: Reverse Proxy   # Web Services
VMID 900: Test VM         # Development