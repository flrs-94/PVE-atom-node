# Intel QAT Engine-Aufteilung für PVE-atom-node Gateway
# Datum: 28.10.2025
# Hardware: Intel C3000 SoC mit QAT

## Hardware-Topologie
```
Intel C3000 QAT Hardware:
├── 19 Physische Crypto Engines
│   ├── 12x Symmetric Crypto Engines (AES-128/256, 3DES, KASUMI)
│   ├── 4x Asymmetric Crypto Engines (RSA-2048/4096, ECDSA-P256/384, DH)
│   └── 3x Compression Engines (DEFLATE, LZS)
├── 16 Virtual Functions (VFs) via SR-IOV
└── 1 Physical Function (PF) für Management
```

## Empfohlene Strategische Aufteilung

### **Option A: Performance-Optimiert (Empfohlen)**
```
Acceleration Engine 0 (AE0) - Host Critical Services
├── VF: 0, 1, 2
├── Typ: Mixed Crypto (AES + DEFLATE)
├── Zweck: Proxmox Host, System-Encryption, ZFS, Management
├── Workload: LUKS, SSH, System-TLS, ZFS Compression, Snapshots
└── Priorität: HOCH

Acceleration Engine 1 (AE1) - pfSense Gateway
├── VF: 3, 4, 5, 6
├── Typ: Mixed Crypto (AES + RSA)
├── Zweck: VPN-Gateway, Firewall, IPsec
├── Workload: OpenVPN, WireGuard, IPsec, HTTPS Proxy
└── Priorität: KRITISCH

Acceleration Engine 2 (AE2) - VM Storage & Backup
├── VF: 7, 8, 9
├── Typ: Compression + AES
├── Zweck: VM NAS, Dedicated Backup-Server, Secondary Storage
├── Workload: VM-based ZFS, VM Backup Encryption, File-Sync
└── Priorität: MITTEL

Acceleration Engine 3 (AE3) - Certificate Services
├── VF: 10, 11
├── Typ: Asymmetric Crypto (RSA/ECDSA)
├── Zweck: CA, Certificate Validation, PKI
├── Workload: Let's Encrypt, Internal CA, Certificate Chain
└── Priorität: MITTEL

Acceleration Engine 4 (AE4) - Web Services
├── VF: 12, 13
├── Typ: Symmetric Crypto (AES)
├── Zweck: Web-Server, Reverse Proxy, CDN
├── Workload: Nginx TLS, Apache SSL, Load Balancer
└── Priorität: NIEDRIG

Acceleration Engine 5 (AE5) - Development & Testing
├── VF: 14, 15
├── Typ: Mixed (AES + Compression)
├── Zweck: Test-VMs, Development, Staging
├── Workload: Dev-Workloads, Crypto-Tests, Benchmarks
└── Priorität: SEHR NIEDRIG
```

### **Option B: VM-Basiert (Alternative)**
```
AE0: Proxmox Host (VF 0-2)           - System Critical
AE1: pfSense VM (VF 3-5)             - Gateway Critical  
AE2: NAS VM (VF 6-8)                 - Storage Primary
AE3: Backup VM (VF 9-10)             - Storage Secondary
AE4: Web-Services VM (VF 11-13)      - Application Layer
AE5: Monitoring/Management (VF 14-15) - Infrastructure
```

## VFIO Passthrough Mapping

### Host behält (Management):
- **AE0**: VF 0, 1, 2 (System-Critical)
- **Monitoring**: Zugriff auf alle AE-Status

### pfSense VM bekommt:
- **AE1**: VF 3, 4, 5, 6 (Maximale VPN-Performance)
- **Backup AE3**: VF 10 bei Bedarf

### Storage VMs bekommen:
- **AE2**: VF 7, 8, 9 (Primary Storage)
- **AE5**: VF 14, 15 (Backup/Development)

### Web/App VMs bekommen:
- **AE4**: VF 12, 13 (Web-Workloads)
- **AE3**: VF 11 (Certificate Handling)

## Performance-Erwartungen

### Theoretical Throughput:
```
AE0 (Host):           ~6 Gbps AES-256 + 600 MB/s DEFLATE, 2K RSA/sec
AE1 (pfSense):        ~12 Gbps AES-256, 1.5K RSA/sec  
AE2 (VM Storage):     ~8 Gbps AES + 1.2 GB/s DEFLATE
AE3 (Certificates):   ~4K RSA-2048/sec, 2K ECDSA/sec
AE4 (Web):            ~10 Gbps TLS 1.3, 3K Handshakes/sec
AE5 (Dev/Test):       ~5 Gbps Mixed Workload
```

### Real-World Workload:
```
Gateway-Szenario (typisch):
├── pfSense VPN:      70-90% AE1 Auslastung
├── Storage Sync:     40-60% AE2 Auslastung  
├── Web HTTPS:        20-40% AE4 Auslastung
├── Certificate:      10-30% AE3 Auslastung
└── Host Management:  5-15% AE0 Auslastung
```

## Monitoring & Alerting

### Critical Thresholds:
- **AE0 (Host) > 80%**: System Performance Warning
- **AE1 (pfSense) > 95%**: Gateway Bottleneck Alert
- **AE2 (Storage) > 85%**: Backup Performance Warning
- **Jede AE > 98%**: Overload Protection

### Load Balancing Rules:
1. **AE1 overload** → Overflow zu AE3 (VF 10)
2. **AE2 overload** → Deferral zu AE5 (VF 14-15)  
3. **AE4 overload** → Queue Management
4. **Host Critical** → AE0 hat immer Priorität

## Configuration Files

### Proxmox Host (/etc/qat/):
```bash
# QAT VF Assignment
echo "0000:XX:00.0" > /sys/bus/pci/drivers/vfio-pci/bind  # VF0 → AE0
echo "0000:XX:00.1" > /sys/bus/pci/drivers/vfio-pci/bind  # VF1 → AE0  
echo "0000:XX:00.2" > /sys/bus/pci/drivers/vfio-pci/bind  # VF2 → AE0
```

### pfSense VM Assignment:
```xml
<hostdev mode='subsystem' type='pci' managed='yes'>
  <source><address domain='0x0000' bus='0xXX' slot='0x00' function='0x3'/></source>
</hostdev>
<!-- VF 3,4,5,6 für AE1 -->
```

## Implementierung Roadmap

### Phase 1: Host Setup
- [x] QAT Hardware Detection
- [x] SR-IOV Activation (16 VFs)
- [ ] AE0 Host-Assignment
- [ ] Monitoring Dashboard

### Phase 2: pfSense Integration  
- [ ] VF 3-6 Passthrough
- [ ] AE1 Configuration
- [ ] VPN Performance Testing
- [ ] Failover zu AE3

### Phase 3: Storage VMs
- [ ] VF 7-9 für AE2
- [ ] ZFS QAT Integration
- [ ] Compression Benchmarks
- [ ] Backup Performance

### Phase 4: Production Optimization
- [ ] Load Balancing Tuning
- [ ] Performance Monitoring
- [ ] Alert Thresholds
- [ ] Disaster Recovery

---
**Status**: Design Phase Complete
**Nächster Schritt**: AE0 Host-Assignment Implementation
**Monitoring**: http://localhost:8080 Dashboard Ready