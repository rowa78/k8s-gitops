# Longhorn Backups auf NFS (Synology)

Longhorn sichert Block-Volumes per RecurringJob zum NFS-Backup-Target. App-Konfiguration (Deployments, Secrets) bleibt GitOps; Postgres logisch über CNPG/Barman → RustFS.

## Backup Target

`nfs://192.168.0.3:/volume1/backup/longhorn` — konfiguriert in [`longhorn/values.yaml`](longhorn/values.yaml) → `defaultBackupStore`.

## RecurringJobs (Gruppe `default`)

Jobs in der **`default`-Gruppe** laufen automatisch auf allen Volumes **ohne** explizite RecurringJob-Labels.

| Job | Cron | Task | Retain |
|-----|------|------|--------|
| `snapshot-hourly` | `0 * * * *` | snapshot (lokal) | 24 |
| `backup-daily` | `0 2 * * *` | backup (NFS) | 14 |

Keine PVC-Labels nötig. Volumes mit **eigenen** RecurringJob-Labels am PVC werden der `default`-Gruppe nicht zugeordnet — solche Labels entfernen.

## Validierung

```bash
kubectl get recurringjobs -n longhorn-system
kubectl get backuptarget default -n longhorn-system

kubectl get volumes.longhorn.io -n longhorn-system -o custom-columns=\
'NAME:.metadata.name,PVC:.status.kubernetesStatus.pvcName,NS:.status.kubernetesStatus.namespace'
```

Longhorn UI → Volume → Recurring Jobs: `default`-Gruppe mit snapshot-hourly + backup-daily.

## Restore

- **Snapshot:** Longhorn UI → Volume → Snapshots → Restore
- **Backup (NFS):** Longhorn UI → Backup → Restore Latest Backup
- **Postgres:** CNPG/Barman, nicht Longhorn allein

## Abgrenzung

| Longhorn | GitOps / Barman |
|----------|-----------------|
| Block-Daten (PVC) | SQL-Dumps, WAL |
| Snapshots lokal | App-Manifeste, Secrets |

## Synology

Share `backup` per NFS für k3s-Nodes (`.250`, `.251`) exportieren; Unterordner `longhorn` muss existieren.
