# Calibre Web Automated Helm Chart

Dieses Helm-Chart deployt Calibre-Web-Automated in einem Kubernetes-Cluster.

## Übersicht

Calibre-Web-Automated ist eine vollautomatisierte Web-Oberfläche für Calibre mit automatischer Buchverarbeitung.

## Features

- **Automatische Buchverarbeitung**: Bücher, die in das Ingest-Verzeichnis gelegt werden, werden automatisch zur Bibliothek hinzugefügt
- **Web-Oberfläche**: Moderne Web-UI zum Verwalten und Lesen deiner eBooks
- **Persistente Speicherung**: Separate Volumes für Config, Ingest, Library und Plugins
- **Ingress-Support**: Einfacher Zugriff über einen Hostnamen mit TLS-Unterstützung
- **Anpassbare Umgebungsvariablen**: Vollständig konfigurierbar über values.yaml

## Installation

### Mit ArgoCD

1. Bearbeite die `calibre.yaml` Datei und passe die Repository-URL an
2. Apply die ArgoCD Application:
   ```bash
   kubectl apply -f calibre.yaml
   ```

### Mit Helm direkt

```bash
helm install calibre-web-automated . -n calibre --create-namespace
```

## Konfiguration

### Wichtige Values

Die Konfiguration erfolgt über die `values.yaml` Datei:

```yaml
calibre-web-automated:
  # Image-Konfiguration
  image:
    repository: crocodilestick/calibre-web-automated
    tag: latest
    
  # Umgebungsvariablen
  env:
    PUID: "1000"              # User ID
    PGID: "1000"              # Group ID
    TZ: "Europe/Berlin"       # Zeitzone
    HARDCOVER_TOKEN: "..."    # Hardcover API Key (optional)
    
  # Ingress
  ingress:
    enabled: true
    host: calibre.rwcloud.org # Deine Domain
    
  # Persistence
  persistence:
    config:
      size: 1Gi               # Größe des Config-Volumes
    ingest:
      size: 10Gi              # Größe des Ingest-Volumes
    library:
      size: 100Gi             # Größe des Library-Volumes
```

### Umgebungsvariablen

| Variable | Beschreibung | Standard |
|----------|--------------|----------|
| `PUID` | User ID für den Container | `1000` |
| `PGID` | Group ID für den Container | `1000` |
| `TZ` | Zeitzone | `Europe/Berlin` |
| `CWA_PORT_OVERRIDE` | Port-Override (optional) | `8083` |
| `HARDCOVER_TOKEN` | Hardcover API Key für Metadaten | - |
| `NETWORK_SHARE_MODE` | Modus für Netzwerk-Shares | `false` |
| `CWA_WATCH_MODE` | Watch-Modus (`poll` oder `inotify`) | - |
| `TRUSTED_PROXY_COUNT` | Anzahl vertrauenswürdiger Proxies | `1` |
| `DISABLE_LIBRARY_AUTOMOUNT` | Library-Automount deaktivieren | `false` |

### Persistence

Das Chart erstellt folgende PersistentVolumeClaims:

- **config**: Konfigurationsdateien und Benutzereinstellungen (1Gi)
- **ingest**: Temporäres Verzeichnis für neue Bücher (10Gi)
- **library**: Calibre-Bibliothek mit allen Büchern (100Gi)
- **plugins**: Calibre-Plugins (optional, 1Gi)

Du kannst bestehende PVCs verwenden, indem du `existingClaim` setzt:

```yaml
calibre-web-automated:
  persistence:
    library:
      existingClaim: my-existing-pvc
```

### Resources

Standard-Ressourcen:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 2000m
    memory: 2Gi
```

## Nutzung

### Bücher hinzufügen

1. **Manuell über die Web-UI**: Greife auf `https://calibre.rwcloud.org` zu und nutze die Upload-Funktion

2. **Automatisch über Ingest**:
   - Kopiere Bücher in das Ingest-Volume
   - Calibre-Web-Automated verarbeitet sie automatisch
   - Nach der Verarbeitung werden die Dateien aus dem Ingest-Verzeichnis entfernt

### Erste Schritte

1. Nach dem Deployment greife auf die Web-UI zu: `https://calibre.rwcloud.org`
2. Beim ersten Start wird automatisch eine Bibliothek erstellt
3. Konfiguriere die Einstellungen nach deinen Wünschen in der Web-UI
4. Beginne, Bücher hinzuzufügen!

### Plugins

Falls du Calibre-Plugins nutzen möchtest:

1. Aktiviere das Plugins-Volume:
   ```yaml
   persistence:
     plugins:
       enabled: true
   ```

2. Kopiere `customize.py.json` in das Config-Volume:
   ```bash
   kubectl cp customize.py.json calibre/calibre-web-automated-xxx:/config/.config/calibre/
   ```

## Ports

| Port | Beschreibung |
|------|--------------|
| 8083 | Web-UI (HTTP) |

Für Ports < 1024 müssen zusätzliche Capabilities gesetzt werden (siehe Security Context).

## Security Context

Das Chart läuft standardmäßig mit:
- User ID: 1000
- Group ID: 1000
- FSGroup: 1000

Für privilegierte Ports < 1024, uncomment im `values.yaml`:

```yaml
securityContext:
  capabilities:
    add:
      - NET_BIND_SERVICE
```

## Troubleshooting

### Pod startet nicht

Prüfe die Logs:
```bash
kubectl logs -n calibre deployment/calibre-web-automated
```

### Berechtigungsprobleme

Stelle sicher, dass die PVCs mit den richtigen Berechtigungen erstellt wurden:
```bash
kubectl exec -n calibre deployment/calibre-web-automated -- chown -R 1000:1000 /config /cwa-book-ingest /calibre-library
```

### Netzwerk-Shares

Falls deine Bibliothek auf einem Netzwerk-Share liegt:
```yaml
env:
  NETWORK_SHARE_MODE: "true"
  CWA_WATCH_MODE: "poll"
```

## Migration von Docker Compose

Falls du von Docker Compose migrierst:

1. Stoppe den Docker-Container:
   ```bash
   docker-compose down
   ```

2. Sichere deine Daten:
   ```bash
   tar czf calibre-backup.tar.gz ./config ./library
   ```

3. Extrahiere die Backup-Daten in die PVCs nach dem Deployment

4. Starte das Helm-Chart

## Updates

### Image-Update

Ändere den Tag in `values.yaml`:
```yaml
image:
  tag: "new-version"
```

### Chart-Update

```bash
helm upgrade calibre-web-automated . -n calibre
```

## Links

- [Calibre-Web-Automated GitHub](https://github.com/crocodilestick/Calibre-Web-Automated)
- [Docker Hub](https://hub.docker.com/r/crocodilestick/calibre-web-automated)
- [Hardcover API](https://docs.hardcover.app/api/getting-started/)

## Support

Bei Problemen mit dem Helm-Chart erstelle ein Issue im Repository.
Für Probleme mit Calibre-Web-Automated selbst, siehe das [offizielle Repository](https://github.com/crocodilestick/Calibre-Web-Automated).
