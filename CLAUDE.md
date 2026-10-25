# k8s-gitops

GitOps-Repo für einen Heim-Kubernetes-Cluster (k3s): Argo CD synchronisiert den Clusterzustand aus `cluster/`, Renovate hält Chart- und Image-Versionen aktuell. Dazu Ansible-Playbooks für Node-Setup und mkdocs-Doku.

> ⚠️ **Merge = Deploy.** Argo CD synchronisiert `main` sofort in den Cluster. Jeder Merge ist eine Produktionsänderung: Jeder PR muss für sich lauffähig sein, Reviews von Manifesten entsprechend streng.

> ⚠️ **Öffentliches Repo.** Keine Secrets, Tokens oder Passwörter – auch nicht als Beispiel. Interne Details (IPs, Hostnamen außerhalb der Manifeste, Vault-Pfade) nicht in Issues, Specs, PR-Texte oder Kommentare schreiben.

## Befehle

Es gibt keinen klassischen Build/Test-Lauf und noch keine CI (`Jenkinsfile` ist leer, kein `.github/workflows/`). Geprüft wird statisch:

| Zweck | Befehl | Auf dem Worker |
|---|---|---|
| Abhängigkeiten installieren | – (keine) | – |
| YAML-Syntax (alle Nicht-Template-YAMLs) | `find cluster -name '*.y*ml' -not -path '*/templates/*' -exec yq e '.' {} + >/dev/null` | ✅ |
| YAML-Lint, nur geänderte Dateien (Pflicht) | `git diff --name-only --diff-filter=d origin/main -- '*.yaml' '*.yml' \| xargs -r -d '\n' yamllint` | ✅ |
| YAML-Lint, ganzes Repo (Überblick) | `yamllint cluster/` | ✅ (Altbestand: ca. 340 Fehler, nur Whitespace/EOF/Einrückung) |
| Secret-Scan, Commits des Branches (Pflicht) | `gitleaks detect --no-banner --redact --log-opts="origin/main..HEAD"` | ✅ |
| Secret-Scan, Arbeitsstand | `gitleaks detect --no-banner --redact --no-git` | ✅ (6 Treffer, alle Platzhalter/Kommentare im Altbestand) |
| pre-commit-Hooks (Whitespace, EOF, CRLF, Tabs, Smartquotes, `forbid-secrets`) | `pre-commit run --files <dateien>` | ❌ Hook-Repos nicht ladbar (kein Netz zu github.com) |
| Charts rendern + Schema prüfen (je App mit `Chart.yaml`) | `helm dependency build <app> && helm template <app> \| kubeconform -strict -ignore-missing-schemas -summary` | ❌ vom dev-pack-Hook gesperrt → CI |
| Ansible-Lint (nur bei Issues, die `ansible/` nennen) | `ansible-lint ansible/` | ❌ vom dev-pack-Hook gesperrt |
| Doku bauen | `mkdocs build` | ❌ nicht installiert |
| Tests / Build / Lokal starten | – (nicht vorhanden; Deployment durch Argo CD) | – |

yamllint liest `.yamllint.yaml` (Basis `relaxed`, ohne Zeilenlänge, `templates/` ausgenommen, weil dort Go-Templates stehen). Gitleaks ist auf dem Worker eine ältere v8: `gitleaks detect` verwenden, nicht `gitleaks git`/`dir`.

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

- **Secrets nur über Vault/ExternalSecret**, nie als Klartext-`Secret` im Repo. Die vorhandenen `SealedSecret`s sind Altbestand und werden nicht neu eingeführt. Der pre-commit-Hook `forbid-secrets` ist nur ein zusätzliches Netz: Er fängt nur unverschlüsselte `kind: Secret`.
- **`ansible/` nur ändern, wenn ein Issue es ausdrücklich nennt.**
- Versionen werden von Renovate per PR angehoben (Commit-Titel wie „Update Helm release X to vY“); nicht von Hand mit Renovate-Updates kollidieren.
- Neue App = neues Verzeichnis unter der passenden Gruppe in `cluster/`; die Zuordnung zu Projekt/Welle ergibt sich aus der Gruppe.
- Kein Tab, keine CRLF, keine typografischen Anführungszeichen (pre-commit).
- Die `README.md` verweist teils noch auf den Fork `rogerrum/k8s-gitops`; maßgeblich ist `rowa78/k8s-gitops`.

## Factory

Dieses Repo wird von der Agent Factory betreut (Konfiguration: `.factory.yml`). Standard-Workflow ist `change` (`build → review → gate:merge`, ohne Spec-Station).

- Specs liegen unter `docs/specs/<issue>-<slug>.md` und beschreiben, *warum* etwas so gebaut ist. Sie enthalten keinen Status.
- Branches der Factory heißen `factory/<issue>-<slug>`.
- **Neue Issues ohne `factory:*`-Label anlegen** – sie stehen dann unter „Neu“, eingeplant wird von Hand. `factory:inbox` (oder eine Station) nur, wenn ausdrücklich „einplanen“ gesagt wird.
- **Vor Änderungen an Dateien: auf einem Issue-Branch `factory/<n>-…` arbeiten.** Wenn nicht: `/factory:work "<Titel>"` vorschlagen (legt Issue und Branch an, nimmt uncommittete Änderungen mit) bzw. `/factory:work <n>` für ein bestehendes Issue. Abschluss mit `/factory:handoff`. Lesen, Ausprobieren und Tests laufen lassen brauchen das nicht. Auf dem Standard-Branch sperrt ein Hook des Factory-Plugins Änderungen und Commits.
- Wiederkehrende Review-Befunde werden hier unter „Konventionen“ ergänzt.
