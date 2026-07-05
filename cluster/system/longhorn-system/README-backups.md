# Longhorn Backup-Strategie

Mehrschichtige Datensicherung für Stateful Workloads. Longhorn ersetzt kein vollständiges Cluster-Backup (App-Deployments, Secrets) — dafür bleiben GitOps/ArgoCD und CNPG/Barman zuständig.

## Architektur

```
Schicht 1  Snapshot hourly     → lokal, schnelle Wiederherstellung (Tier A)
Schicht 2  Volume backup daily → NFS Block-Daten (Tier A + B)
Schicht 2b System backup daily → NFS Longhorn-Metadaten (global)
Schicht 3  CNPG Barman         → Postgres logisch → RustFS (5d)
Schicht 4  GitOps               → Deployments, Secrets, Helm/Argo
```

NFS-Target: `nfs://192.168.0.3:/volume1/backup/longhorn`  
Konfiguration: [`longhorn/values.yaml`](longhorn/values.yaml) → `defaultBackupStore`.

## RecurringJobs

| Job | Cron | Task | Group | Retain |
|-----|------|------|-------|--------|
| `snapshot-hourly` | `0 * * * *` | snapshot | `snapshot-hourly` | 24 |
| `backup-daily` | `0 2 * * *` | backup | `backup-daily` | 14 |
| `system-backup-daily` | `0 4 * * *` | system-backup | — (global) | 7 |

System Backup verwendet `volume-backup-policy: disabled` — es sichert **keine** Volume-Block-Daten mit (Postgres/Prometheus würden sonst ungewollt mitlaufen).

## Volume-Tiers

### Tier A — snapshot hourly + backup daily

| App | Datei |
|-----|-------|
| RustFS (Barman-ObjectStore) | [`rustfs/values.yaml`](../../platform/rustfs/rustfs/values.yaml) |
| Jenkins | [`jenkins/templates/pvc.yaml`](../../apps/jenkins/templates/pvc.yaml) |
| Keycloak LLDAP | [`keycloak/templates/lldap-pvc.yaml`](../keycloak/templates/lldap-pvc.yaml) |
| Databasus | [`databasus/values.yaml`](../../apps/databasus/values.yaml) |
| OAuth2-Proxy Redis | [`oauth2-proxy/values.yaml`](../oauth2-proxy/values.yaml) |

Labels:

```yaml
recurring-job-group.longhorn.io/backup-daily: enabled
recurring-job-group.longhorn.io/snapshot-hourly: enabled
```

### Tier B — backup daily only

| App | Datei |
|-----|-------|
| Grafana | [`kps/values.yaml`](../../monitoring/kube-prometheus-stack/kps/values.yaml) |
| Alertmanager | [`kps/values.yaml`](../../monitoring/kube-prometheus-stack/kps/values.yaml) |
| Open WebUI App-Daten | [`openwebui/app/values.yaml`](../../apps/openwebui/app/values.yaml), [`xopenwebui/app/values.yaml`](../../apps/xopenwebui/app/values.yaml) |

Label:

```yaml
recurring-job-group.longhorn.io/backup-daily: enabled
```

### Ausgeschlossen

| Kategorie | Grund |
|-----------|-------|
| Postgres (CNPG) | Barman → RustFS, 5d Retention — kein Longhorn-Backup |
| Prometheus TSDB | Metriken 10d Retention, kein Restore-Bedarf |

## System Backup

Longhorn exportiert ein YAML-Bundle (Settings, StorageClasses, RecurringJobs, PVC/PV/Volume-CRs) ins gleiche NFS-Target.

**Enthalten:** Longhorn-eigene CRs und Ressourcen im `longhorn-system`-Namespace.  
**Nicht enthalten:** App-Pods, Deployments, Secrets, Postgres-Inhalt.

**Restore (Cluster-Totalausfall):**

1. GitOps/ArgoCD sync (Apps, Secrets)
2. Longhorn installieren, Backup Target setzen
3. System Restore aus letztem `SystemBackup`
4. Volume Restore pro App falls nötig (Longhorn UI → Backup → Restore)
5. Postgres: CNPG/Barman Recovery (nicht Longhorn allein)

## Synology-Voraussetzungen

1. Share `backup` per NFS exportiert
2. Unterordner `longhorn` im Share vorhanden
3. k3s-Nodes (`192.168.0.250`, `192.168.0.251`) mit Read/Write in NFS Permissions

## Validierung

```bash
kubectl get recurringjobs -n longhorn-system
kubectl get backuptarget default -n longhorn-system
kubectl get systembackups -n longhorn-system

kubectl get volumes.longhorn.io -n longhorn-system -o custom-columns=\
'NAME:.metadata.name,LABELS:.metadata.labels'
```

Erwartung: Postgres- und Prometheus-Volumes **ohne** Group-Labels; Tier-A/B-Volumes mit `backup-daily`.

Manueller Test: Longhorn UI → Volume → Create Backup → Restore in Test-PVC.

## Restore-Runbooks

### Snapshot (Tier A, schnell)

Longhorn UI → Volume → Snapshots → Restore zu neuem Volume oder Rollback.

### Volume Backup (NFS)

Longhorn UI → Backup → Restore Latest Backup → neues Volume → PVC anbinden.

### Postgres (Barman)

CNPG Recovery-Flow über Barman ObjectStore — siehe App-Doku, nicht Longhorn.

## Monitoring

Prometheus-Alerts in [`prometheus-rule.yaml`](longhorn/templates/prometheus-rule.yaml):

- `LonghornBackupTargetUnavailable`
- `LonghornBackupFailed`
- `LonghornVolumeBackupStale` (> 36h)

## Abgrenzung

| Longhorn | GitOps / Barman |
|----------|-----------------|
| Block-Daten (PVC) | SQL-Dumps, WAL, App-Logik |
| Longhorn-Metadaten (System Backup) | Deployments, Secrets, CRs |
| Ein NFS-Target | Pro App ObjectStore |

## Restore-Probe (quartalsweise)

- [ ] Backup Target `AVAILABLE: true`
- [ ] Tier-A-Volume: Snapshot + Backup manuell testen
- [ ] System Backup in UI sichtbar (`kubectl get systembackups`)
- [ ] Optional: Postgres Barman Restore in Test-Namespace
