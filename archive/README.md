# Archive - Obsolete und Historische Dateien

Dieses Verzeichnis enthält archivierte Dateien, die während der Entwicklung des PVE-atom-node Projekts erstellt wurden, aber nicht mehr aktiv genutzt werden oder durch neuere Versionen ersetzt wurden.

---

## 📁 Struktur

```
archive/
├── README.md           # Diese Datei
├── docs/              # Alte/doppelte Dokumentation
├── configs/           # Obsolete Konfigurationen
└── scripts/           # Deprecated Scripts
```

---

## 📋 Archivierte Inhalte

### `/archive/configs/` - Alte Konfigurationen

**Grund der Archivierung**: Duplikat-Verzeichnis, konsolidiert in `/config/`

| Datei | Beschreibung | Ersetzt durch |
|-------|--------------|---------------|
| `network-interfaces-gateway.conf` | Frühe Network Config | `/config/network/interfaces` |
| `network/10-eth*.link` | Alte systemd Links (teilweise) | `/config/network/10-eth*.link` |
| `network/10-persistent-net.rules` | Alte udev Rules | `/config/network/10-persistent-net.rules` |
| `vfio-pci.conf` | Alte VFIO Config | `/config/network/vfio-pci.conf` |
| `vfio-sfp.conf` | SFP-spezifische VFIO Config | Zusammengeführt in vfio-pci.conf |
| `zfs-qat.conf` | ZFS QAT Config (nicht verwendet) | N/A (Host ZFS ohne native QAT) |

**Status**: Veraltet, durch konsolidierte Configs in `/config/` ersetzt  
**Datum der Archivierung**: 29. Oktober 2025

---

### `/archive/docs/` - Obsolete Dokumentation

#### 1. QAT-INTEGRATION-SUCCESS.md
**Status**: Ersetzt  
**Grund**: Zwischenbericht, konsolidiert in `QAT_INTEGRATION_FINAL_REPORT.md`  
**Inhalt**: Frühe QAT Success-Meldung, Performance-Zahlen, erste Engine-Allocation  
**Ersetzt durch**: `/docs/QAT_INTEGRATION_FINAL_REPORT.md`

#### 2. QAT_Engine_Allocation_Strategy.md
**Status**: Archiviert  
**Grund**: Detaillierte Strategie-Planung, nicht mehr aktiv benötigt  
**Inhalt**: 
- Engine-Aufteilungs-Strategien (AE0-AE5)
- VM-basierte vs. Performance-optimierte Allocation
- VFIO Passthrough Mapping Details
- Theoretische Performance-Zahlen

**Relevanz**: Referenz für Engine-Allocation, aber nicht mehr aktiv verwendet

#### 3. QAT_VFIO_Denylist_Fix.md
**Status**: Archiviert (Problem gelöst)  
**Grund**: Technisches Problem-Dokument, Lösung implementiert  
**Inhalt**:
- VFIO-PCI Denylist Problem für QAT VFs
- Lösung: `disable_denylist=1` Parameter
- Service und Binding-Scripts
- Security Notes

**Relevanz**: Historisch wichtig, Problem permanent gelöst

#### 4. ZFS-QAT-OPTIMIZATION-REPORT.md
**Status**: Ersetzt  
**Grund**: Früher Optimierungs-Bericht, konsolidiert in finale Dokumente  
**Inhalt**:
- ZFS Pool Config
- QAT Engine Allocation (Host AE0)
- Performance Resultate (2.57x Compression)
- Phase 5 Status

**Ersetzt durch**: `/docs/STORAGE-ARCHITECTURE-FINAL.md` und `/docs/ZFS_QAT_SOLUTIONS.md`

#### 5. Interface-Naming-Persistenz.md
**Status**: Archiviert (Problem gelöst)  
**Grund**: Technisches Problem-Dokument, Lösung implementiert und in Network README integriert  
**Inhalt**:
- Problem: Interface-Namen nicht persistent
- Lösung: Multi-Layer Approach (udev + systemd)
- Interface-Mapping-Tabelle
- Verifikations-System

**Ersetzt durch**: `/config/network/README.md` (Lösung dokumentiert)

---

### `/archive/scripts/` - Deprecated Scripts

#### 1. phase2-host-ae0-setup.sh
**Status**: Veraltet  
**Grund**: Phasen-spezifisches Script, nicht mehr benötigt  
**Funktionalität**: Host AE0 Engine Setup für QAT  
**Ersetzt durch**: Systemd Services und manuelle Config

#### 2. phase3-pfsense-passthrough.sh
**Status**: Veraltet  
**Grund**: Phasen-spezifisches Script, ersetzt durch generische VM-Creation Scripts  
**Funktionalität**: pfSense VM mit SFP+ Passthrough Setup  
**Ersetzt durch**: `/scripts/create-pfsense-vm.sh` und `/scripts/bind-pfsense-qat-vfs.sh`

---

## 🔍 Warum Archivieren?

### Gründe für Archivierung

1. **Duplikate entfernt**
   - `/configs/` und `/config/` → Konsolidiert in `/config/`
   - Vermeidung von Verwirrung über "richtige" Dateien

2. **Dokumentation konsolidiert**
   - Multiple Zwischen-Reports → Finale Dokumente
   - Bessere Übersichtlichkeit für neue Nutzer
   - Klare Struktur: Aktuelles in `/docs/`, Historisches in `/archive/`

3. **Scripts modernisiert**
   - Phasen-spezifische Scripts → Generische, wiederverwendbare Scripts
   - Bessere Wartbarkeit

4. **Problem-Dokumente abgeschlossen**
   - Gelöste Probleme archiviert (Interface Naming, VFIO Denylist)
   - Lösung in aktiver Dokumentation referenziert

### Vorteile

- ✅ Klarere Repository-Struktur
- ✅ Einfacherer Einstieg für neue Nutzer
- ✅ Historische Referenz erhalten
- ✅ Keine Datenverlust (alles noch verfügbar)
- ✅ Git-History bleibt intakt

---

## 📖 Verwendung Archivierter Dateien

### Wann Archive durchsuchen?

1. **Historische Referenz**
   - Wie wurde ein Problem ursprünglich gelöst?
   - Welche Strategien wurden erwogen?

2. **Troubleshooting**
   - Ähnliches Problem wie früher?
   - Alte Lösung als Inspiration

3. **Dokumentations-Archäologie**
   - Entwicklungsgeschichte nachvollziehen
   - Lernen aus vergangenen Entscheidungen

### Zugriff auf archivierte Dateien

```bash
# Archiv durchsuchen
cd /root/PVE-atom-node/archive

# Dokumentation lesen
cat docs/QAT-INTEGRATION-SUCCESS.md

# Alte Config einsehen
cat configs/vfio-sfp.conf

# Git History für archivierte Datei
git log --follow -- archive/docs/QAT-INTEGRATION-SUCCESS.md
```

---

## ⚠️ Wichtige Hinweise

### Nicht verwenden für Production

- ❌ Archivierte Configs sind **nicht** die aktuellen Configs
- ❌ Archivierte Scripts sind **deprecated** und sollten nicht ausgeführt werden
- ❌ Archivierte Docs sind **veraltet** und können inkorrekte Informationen enthalten

### Immer aktuelle Dateien verwenden

- ✅ Configs: `/config/`
- ✅ Docs: `/docs/`
- ✅ Scripts: `/scripts/`
- ✅ Main Docs: `/README.md`, `/ROADMAP.md`, `/REPRODUCTION-GUIDE.md`

---

## 🗓️ Archivierungs-Historie

| Datum | Aktion | Details |
|-------|--------|---------|
| 29.10.2025 | Initiale Archivierung | Duplikate und obsolete Docs verschoben |
| 29.10.2025 | Repository-Reorganisation | Klare Struktur etabliert |

---

## 🔄 Wiederherstellung

Falls eine archivierte Datei wieder benötigt wird:

```bash
# Zurück in aktives Verzeichnis verschieben
cp archive/docs/BEISPIEL.md docs/

# Oder mit Git wiederherstellen
git log --all --full-history -- archive/docs/BEISPIEL.md
git checkout <commit-hash> -- docs/BEISPIEL.md
```

---

## 📞 Fragen?

Wenn unklar ist, ob eine Datei archiviert oder aktiv sein sollte:

1. Prüfe die aktuelle Dokumentation in `/docs/`
2. Siehe [README.md](../README.md) für Repository-Übersicht
3. Erstelle ein GitHub Issue bei Unklarheiten

---

**Archiv erstellt**: 29. Oktober 2025  
**Letzte Aktualisierung**: 29. Oktober 2025  
**Archive Version**: 1.0
