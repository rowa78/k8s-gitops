# Longhorn Backups auf NFS (Synology)

Longhorn sichert Block-Volumes zum NFS-Backup-Target auf der DiskStation. Es ersetzt kein vollständiges Cluster-Backup (Namespaces, Secrets, Deployments) – dafür bleibt GitOps bzw. CNPG/Barman zuständig.

## Architektur

```
Longhorn Volume  →  RecurringJob (optional, gelabelt)  →  NFS
                      nfs://192.168.0.3:/volume1/k8s/longhorn-backups
```

Konfiguration: [`longhorn/values.yaml`](longhorn/values.yaml) → `defaultBackupStore`.

## Voraussetzungen Synology

1. Ordner `/volume1/k8s/longhorn-backups` auf der DiskStation anlegen.
2. NFS-Export `/volume1/k8s` muss für die k3s-Nodes Schreibzugriff erlauben (bereits via [`nfs-diskstation`](../nfs-diskstation/values.yaml) genutzt).
3. Bei Timeout-Problemen NFS-Optionen an die URL anhängen, z. B.  
   `nfs://192.168.0.3:/volume1/k8s/longhorn-backups?nfsOptions=soft,timeo=330,retrans=3`

## Backup Target prüfen

```bash
kubectl get backuptarget -n longhorn-system
# NAME      URL                                              AVAILABLE
# default   nfs://192.168.0.3:/volume1/k8s/longhorn-backups  true

kubectl get settings.longhorn.io backup-target -n longhorn-system -o jsonpath='{.value}{"\n"}'
```

Alternativ: Longhorn UI → Setting → General → Backup Target.

## Automatische Backups (RecurringJob)

RecurringJob `nfs-backup-daily` (täglich 02:00, retain 30) läuft **nur** für explizit gelabelte Volumes.

Volume-Namen ermitteln:

```bash
kubectl get volumes.longhorn.io -n longhorn-system
kubectl get pvc -n keycloak -o wide
```

Volume aktivieren:

```bash
kubectl -n longhorn-system label volume <volume-name> \
  recurring-job.longhorn.io/nfs-backup-daily=enabled
```

Label entfernen:

```bash
kubectl -n longhorn-system label volume <volume-name> \
  recurring-job.longhorn.io/nfs-backup-daily-
```

## Manuellen Backup-Test

Longhorn UI: Volume → Create Backup.

Oder per CR (Volume-Name anpassen):

```yaml
apiVersion: longhorn.io/v1beta2
kind: Backup
metadata:
  name: manual-test
  namespace: longhorn-system
spec:
  snapshotName: <snapshot-name>
  labels:
    manual: test
```

Snapshot zuerst am Volume erstellen (UI oder `Snapshot` CR), dann Backup darauf.

## Restore (Kurzüberblick)

1. Longhorn UI → Backup → Restore Latest Backup (neues Volume).
2. Neues PVC mit restored Volume verbinden oder CNPG/StatefulSet Recovery-Flow nutzen.
3. App-spezifische Logik (Postgres PITR etc.) weiter über CNPG/Barman, nicht über Longhorn allein.

## Abgrenzung

| Longhorn Backup | GitOps / CNPG Barman |
|-----------------|----------------------|
| PVC / Block-Daten | SQL-Dumps, WAL, App-Logik |
| Ein Backup-Target (NFS) | Pro App ObjectStore möglich |
