# k8s-gitops

GitOps-Repo für einen Heim-Kubernetes-Cluster (k3s): Argo CD synchronisiert den Clusterzustand aus `cluster/`, Renovate hält Chart- und Image-Versionen aktuell. Dazu Ansible-Playbooks für Node-Setup und mkdocs-Doku.

> ⚠️ **Merge = Deploy.** Argo CD synchronisiert `main` sofort in den Cluster. Jeder Merge ist eine Produktionsänderung: Jeder PR muss für sich lauffähig sein, Reviews von Manifesten entsprechend streng.

> ⚠️ **Öffentliches Repo.** Keine Secrets, Tokens oder Passwörter – auch nicht als Beispiel. Interne Details (IPs, Hostnamen außerhalb der Manifeste, Vault-Pfade) nicht in Issues, Specs, PR-Texte oder Kommentare schreiben.

## Befehle

Es gibt keinen klassischen Build/Test-Lauf. Geprüft wird statisch; dieselben Pflicht-Prüfungen (YAML-Syntax, yamllint auf geänderten Dateien, Chart-Rendering mit kubeconform für geänderte Apps, gitleaks über die PR-Commits) laufen als GitHub-Actions-Workflow `.github/workflows/validate.yaml` auf jedem PR gegen `main`. Der `Jenkinsfile` ist leer und ungenutzt.

| Zweck | Befehl |
|---|---|
| Abhängigkeiten installieren | – (keine) |
| YAML-Syntax (alle Nicht-Template-YAMLs) | `find cluster -name '*.y*ml' -not -path '*/templates/*' -exec yq e '.' {} + >/dev/null` |
| YAML-Lint, nur geänderte Dateien (Pflicht) | `git diff --name-only --diff-filter=d origin/main...HEAD -- '*.yaml' '*.yml' \| xargs -r -d '\n' yamllint` |
| YAML-Lint, ganzes Repo (Überblick) | `yamllint cluster/` |
| Secret-Scan, Commits des Branches (Pflicht) | `gitleaks detect --no-banner --redact --log-opts="origin/main..HEAD"` |
| Secret-Scan, Arbeitsstand | `gitleaks detect --no-banner --redact --no-git` |
| pre-commit-Hooks (Whitespace, EOF, CRLF, Tabs, Smartquotes, `forbid-secrets`) | `pre-commit run --files <dateien>` |
| Charts rendern + Schema prüfen (je App mit `Chart.yaml`) | `helm dependency build <app> && helm template <app> \| kubeconform -strict -ignore-missing-schemas -summary` |
| Ansible-Lint (nur bei Issues, die `ansible/` nennen) | `ansible-lint ansible/` |
| Doku bauen | `mkdocs build` |
| Tests / Build / Lokal starten | – (nicht vorhanden; Deployment durch Argo CD) |

yamllint liest `.yamllint.yaml` (Basis `relaxed`, ohne Zeilenlänge, `templates/` ausgenommen, weil dort Go-Templates stehen). Gitleaks v8: `gitleaks detect` verwenden, nicht `gitleaks git`/`dir`.

Ein Arbeitsstand gilt als fertig, wenn die Pflicht-Prüfungen und die YAML-Syntax fehlerfrei sind (Warnungen sind erlaubt) und kein Klartext-Secret enthalten ist. Altbestand nur in Dateien bereinigen, die der PR ohnehin anfasst. Nicht ausführbare Prüfungen im PR als „nicht geprüft“ nennen.

Hinweis: `cluster/monitoring/kube-prometheus-stack/kps/values.yaml` definiert den Anker `&host` mehrfach. Das erlaubt die YAML-Spezifikation (yq und Helm akzeptieren es), strikte Parser wie PyYAML melden aber einen Fehler.

## Aufbau

- `cluster/bootstrap/` – Argo CD selbst und das `root`-Chart (`values.yaml` definiert AppProjects und ApplicationSets samt Sync-Wellen).
- `cluster/system/`, `cluster/platform/`, `cluster/monitoring/`, `cluster/apps/` – je ein Verzeichnis pro Anwendung. Die ApplicationSets erzeugen daraus Argo-Applications.
- Typische App: `Chart.yaml` (Wrapper-Chart mit Upstream-Chart als Dependency), `values.yaml`, `templates/` für Zusatz-Manifeste. Größere Apps haben Unterordner (`app/`, `database/`, `valkey/`) und eine `<app>.yaml` mit Application-Definitionen.
- `ansible/` – Playbooks, Rollen und Inventar für k3s/Proxmox/HAProxy.
- `docs/`, `mkdocs.yaml` – Doku (mkdocs).
- `renovate.json` – Renovate-Konfiguration (Manager: helmv3, helm-values, kubernetes, helmfile).

## Konventionen

- **Secrets nur über ExternalSecret (1Password)**, nie als Klartext-`Secret` im Repo. Die vorhandenen `SealedSecret`s sind Altbestand und werden nicht neu eingeführt (Migration je App später). Beispiel siehe unten. Der pre-commit-Hook `forbid-secrets` ist nur ein zusätzliches Netz: Er fängt nur unverschlüsselte `kind: Secret`.
  Der External Secrets Operator (`cluster/system/external-secrets`) bietet den `ClusterSecretStore` `onepassword` auf den 1Password-Tresor `k8s`. Ein `ExternalSecret` verweist nur auf `<Eintrag>/<Feld>`, nie auf Werte; den Eintrag legt der Mensch in 1Password an:

  ```yaml
  apiVersion: external-secrets.io/v1
  kind: ExternalSecret
  metadata:
    name: meine-app
  spec:
    refreshInterval: 1h
    secretStoreRef:
      kind: ClusterSecretStore
      name: onepassword
    target:
      name: meine-app          # Name des erzeugten Kubernetes-Secrets
    data:
      - secretKey: password    # Schlüssel im Kubernetes-Secret
        remoteRef:
          key: meine-app/password   # <Eintrag>/<Feld> im Tresor k8s
  ```

  **Ganzer Eintrag per `dataFrom.extract`:** Jedes Feld des Eintrags wird zu einem Schlüssel im Secret. `deletionPolicy` bleibt beim Standard (nicht `Retain`).

  ```yaml
  spec:
    refreshInterval: 1h
    secretStoreRef:
      kind: ClusterSecretStore
      name: onepassword
    target:
      name: meine-app
    dataFrom:
      - extract:
          key: meine-ns#meine-app   # Titel des Eintrags im Tresor k8s
  ```

  - **Namensschema** der Einträge im Tresor `k8s`: `<namespace>#<app>`. Die Felder heißen wie die gewünschten Secret-Schlüssel bzw. Umgebungsvariablen.
  - **Faustregel:** `dataFrom.extract`, wenn alles aus einem Eintrag gebraucht wird; `data` für einzelne Felder oder umbenannte Schlüssel.
  - **Hinweis:** Standardfelder des Eintrags (z. B. `username`, `notesPlain`) können mit ins Secret wandern. Feldnamen dürfen nur Buchstaben, Ziffern, `-`, `_`, `.` enthalten.
- **Migration SealedSecret → ExternalSecret** (Muster aus `renovate-rwcloud`, Spec `docs/specs/616-sealedsecret-migration.md`), in zwei getrennten Merges, weil Merge = Deploy:
  1. Ein `PushSecret` (Store `onepassword-push`, `deletionPolicy: None`) schreibt das vorhandene Secret je Schlüssel in den Eintrag `<namespace>#<secret-name>` im Tresor `k8s`.
  2. Prüfen (Mensch): PushSecret synced, Eintrag enthält alle Felder.
  3. Umstellen: SealedSecret und PushSecret entfernen, `ExternalSecret` mit `dataFrom.extract` anlegen. Das Secret gehört dem SealedSecret; beim Prunen fehlt es kurz, bis ESO es neu anlegt. Danach prüfen, dass es dem ExternalSecret gehört und genau die erwarteten Schlüssel enthält (sonst `data` statt `dataFrom.extract`).
- **SealedSecrets nur noch für die Tokens der Secret-Stores** (Henne-Ei-Problem); alles andere ist ein ExternalSecret.
- **`ansible/` nur ändern, wenn ein Issue es ausdrücklich nennt.**
- Versionen werden von Renovate per PR angehoben (Commit-Titel wie „Update Helm release X to vY“); nicht von Hand mit Renovate-Updates kollidieren.
- Neue App = neues Verzeichnis unter der passenden Gruppe in `cluster/`; die Zuordnung zu Projekt/Welle ergibt sich aus der Gruppe.
- Kein Tab, keine CRLF, keine typografischen Anführungszeichen (pre-commit).
- Die `README.md` verweist teils noch auf den Fork `rogerrum/k8s-gitops`; maßgeblich ist `rowa78/k8s-gitops`.
- Apps, die große CRDs über das Chart installieren, setzen `argocd.argoproj.io/sync-options: ServerSideApply=true` an den CRDs (Grenze: 256 KB für `last-applied-configuration`). Prüfen mit `helm template … | yq -o=json -I=0 'select(.kind=="CustomResourceDefinition")' | awk '{print length}'`.

## Factory

Dieses Repo wird von der Agent Factory betreut (Konfiguration: `.factory.yml`). Standard-Workflow ist `change` (`build → review → gate:merge`, ohne Spec-Station).

- Specs liegen unter `docs/specs/<issue>-<slug>.md` und beschreiben, *warum* etwas so gebaut ist. Sie enthalten keinen Status.
- Branches der Factory heißen `factory/<issue>-<slug>`.
- **Neue Issues ohne `factory:*`-Label anlegen** – sie stehen dann unter „Neu“, eingeplant wird von Hand. `factory:inbox` (oder eine Station) nur, wenn ausdrücklich „einplanen“ gesagt wird.
- **Vor Änderungen an Dateien: auf einem Issue-Branch `factory/<n>-…` arbeiten.** Wenn nicht: `/factory:work "<Titel>"` vorschlagen (legt Issue und Branch an, nimmt uncommittete Änderungen mit) bzw. `/factory:work <n>` für ein bestehendes Issue. Abschluss mit `/factory:handoff`. Lesen, Ausprobieren und Tests laufen lassen brauchen das nicht. Auf dem Standard-Branch sperrt ein Hook des Factory-Plugins Änderungen und Commits.
- Wiederkehrende Review-Befunde werden hier unter „Konventionen“ ergänzt.
