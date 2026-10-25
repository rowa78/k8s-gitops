# k8s-gitops

GitOps-Repo für einen Heim-Kubernetes-Cluster (k3s): Argo CD synchronisiert den Clusterzustand aus `cluster/`, Renovate hält Chart- und Image-Versionen aktuell. Dazu Ansible-Playbooks für Node-Setup und mkdocs-Doku.

## Befehle

Es gibt keinen klassischen Build/Test-Lauf; Änderungen wirken erst, wenn Argo CD sie von `main` synchronisiert.

| Zweck | Befehl |
|---|---|
| Abhängigkeiten installieren | – (keine; optional `pip install pre-commit`) |
| Tests | – (keine vorhanden) |
| Linter | `pre-commit run --all-files` (trailing-whitespace, EOF, Zeilenenden, Tabs, Smartquotes, `forbid-secrets`) |
| Build | – (kein Build; Doku: `mkdocs build`, falls mkdocs installiert) |
| Lokal starten | – (nicht sinnvoll; Deployment erfolgt durch Argo CD im Cluster) |

Auf dem Factory-Worker sind `pre-commit` und `yamllint` derzeit nicht installiert. Ein Arbeitsstand gilt als fertig, wenn YAML syntaktisch gültig ist, keine Klartext-Secrets enthalten sind und – wenn verfügbar – der Linter sauber durchläuft. Eine Cluster-Validierung (Rendern von Charts, Dry-Run) ist auf dem Worker nicht möglich.

## Aufbau

- `cluster/bootstrap/` – Argo CD selbst und das `root`-Chart (`values.yaml` definiert AppProjects und ApplicationSets samt Sync-Wellen).
- `cluster/system/`, `cluster/platform/`, `cluster/monitoring/`, `cluster/apps/` – je ein Verzeichnis pro Anwendung. Die ApplicationSets erzeugen daraus Argo-Applications.
- Typische App: `Chart.yaml` (Wrapper-Chart mit Upstream-Chart als Dependency), `values.yaml`, `templates/` für Zusatz-Manifeste. Größere Apps haben Unterordner (`app/`, `database/`, `valkey/`) und eine `<app>.yaml` mit Application-Definitionen.
- `ansible/` – Playbooks, Rollen und Inventar für k3s/Proxmox/HAProxy.
- `docs/`, `mkdocs.yaml` – Doku (mkdocs).
- `renovate.json` – Renovate-Konfiguration (Manager: helmv3, helm-values, kubernetes, helmfile).

## Konventionen

- Versionen werden von Renovate per PR angehoben (Commit-Titel wie „Update Helm release X to vY“); nicht von Hand mit Renovate-Updates kollidieren.
- Secrets nie im Klartext einchecken (SOPS, Hook `forbid-secrets`).
- Neue App = neues Verzeichnis unter der passenden Gruppe in `cluster/`; die Zuordnung zu Projekt/Welle ergibt sich aus der Gruppe.
- Kein Tab, keine CRLF, keine typografischen Anführungszeichen (pre-commit).
- Die `README.md` verweist teils noch auf den Fork `rogerrum/k8s-gitops`; maßgeblich ist `rowa78/k8s-gitops`.

## Factory

Dieses Repo wird von der Agent Factory betreut (Konfiguration: `.factory.yml`).

- Specs liegen unter `docs/specs/<issue>-<slug>.md` und beschreiben, *warum* etwas so gebaut ist. Sie enthalten keinen Status.
- Branches der Factory heißen `factory/<issue>-<slug>`.
- **Neue Issues ohne `factory:*`-Label anlegen** – sie stehen dann unter „Neu“, eingeplant wird von Hand. `factory:inbox` (oder eine Station) nur, wenn ausdrücklich „einplanen“ gesagt wird.
- **Vor Änderungen an Dateien: auf einem Issue-Branch `factory/<n>-…` arbeiten.** Wenn nicht: `/factory:work "<Titel>"` vorschlagen (legt Issue und Branch an, nimmt uncommittete Änderungen mit) bzw. `/factory:work <n>` für ein bestehendes Issue. Abschluss mit `/factory:handoff`. Lesen, Ausprobieren und Tests laufen lassen brauchen das nicht. Auf dem Standard-Branch sperrt ein Hook des Factory-Plugins Änderungen und Commits.
- Wiederkehrende Review-Befunde werden hier unter „Konventionen“ ergänzt.
