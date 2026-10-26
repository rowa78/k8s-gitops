# SealedSecret-Migration: Vorgehen für alle Apps

Issue: #620

## Ziel

Alle deployten SealedSecrets werden nach dem Muster des Piloten (`renovate-rwcloud`, #616/#617, Spec `docs/specs/616-sealedsecret-migration.md`) durch ExternalSecrets aus 1Password ersetzt. Dabei werden keine Werte von Hand übertragen. Am Ende sind nur noch die Tokens der Secret-Stores SealedSecrets.

## Kontext

- Der Pilot hat den Ablauf erprobt: Ein `PushSecret` schreibt das vorhandene Secret über den Store `onepassword-push` nach 1Password. Danach wird auf ein `ExternalSecret` (Store `onepassword`) umgestellt. Der Ablauf steht in der CLAUDE.md unter „Konventionen".
- Bestand: 79 SealedSecrets. Davon sind
  - 2 Tokens der Secret-Stores (`onepassword-service-account`, `onepassword-push-service-account`). Sie bleiben vorerst.
  - 15 inaktiv: Sie liegen in Verzeichnissen, deren Argo-Application auskommentiert ist (siehe unten).
  - 62 deployt, verteilt auf 23 Apps. Diese werden migriert.
- Schritt 1 (PushSecret) ändert am Verhalten des Clusters nichts. Schritt 2 (Umstellen) löscht das Secret beim Prunen kurz (ownerReference des SealedSecrets), bis ESO es neu anlegt.

## Lösungsansatz

### Aufteilung

| Issue | Inhalt |
|---|---|
| #620 | dieses Design (nur Spec) |
| #621 | Push-Issue: PushSecrets für alle 62 deployten SealedSecrets |
| #623–#645 | Umstellen, je App ein Issue, in drei Wellen |
| #622 | Inaktive SealedSecrets aufräumen (unabhängig) |
| #646 | Abschluss: Push-Store abbauen |

Die Push-Schritte werden gesammelt, die Umstell-Schritte pro App gemacht. Grund: Schritt 1 ist risikolos und braucht nur eine Prüfung durch den Menschen. Schritt 2 ist eine Produktionsänderung und soll je App klein und für sich prüfbar bleiben.

### Push-Issue (#621)

- Für jedes deployte SealedSecret ein `PushSecret` im selben Verzeichnis bzw. Namespace, aufgebaut wie im Piloten:
  - `secretStoreRefs`: `ClusterSecretStore` `onepassword-push`
  - `selector.secret.name`: Name des Secrets
  - je Schlüssel ein Eintrag in `data`: `remoteRef.remoteKey` = `<namespace>#<secret-name>`, `remoteRef.property` = Schlüsselname
  - `deletionPolicy: None`, `refreshInterval: 1h`
- Steht im Manifest kein Namespace, ergibt er sich aus der `destination.namespace` der Application.
- Helm-bedingte SealedSecrets (argocd: `.Values.sealedsecret`; keycloak: `lldap.secrets.sealedSecret.*`) bekommen ein PushSecret unter derselben Bedingung.
- Liegt ein SealedSecret als einfaches Manifest (nicht in `templates/`), liegt auch das PushSecret als einfaches Manifest daneben.
- **Prüfung durch den Menschen, einmal für alle:** Alle PushSecrets sind synced. Stichproben im Tresor `k8s`, besonders bei mehrzeiligen Werten und bei `.dockerconfigjson`. Erst danach starten die Umstell-Issues.

### Umstellen je App (#623–#645)

Je App, wie bei #617:

1. SealedSecrets und PushSecrets der App entfernen.
2. Je Secret ein `ExternalSecret` gleichen Namens anlegen: Store `onepassword`, `target.name` = bisheriger Secret-Name, `dataFrom.extract.key` = `<namespace>#<secret-name>`, `refreshInterval: 1h`.
3. Typ `kubernetes.io/dockerconfigjson`: `target.template.type: kubernetes.io/dockerconfigjson` setzen.
4. Gehören zum SealedSecret Helm-Bedingungen oder values (argocd, keycloak), diese mit entfernen.
5. Nach dem Deploy prüft der Mensch: Jedes Secret gehört dem ExternalSecret und enthält genau die bisherigen Schlüssel, die App läuft. Kommen Zusatzfelder des Eintrags mit ins Secret, wird auf `data` mit den einzelnen Schlüsseln umgestellt.
6. Hat die Application `prune: false` (z. B. `vocabolario-dev-app`, ebenso vocabolario, club20(-dev), clash), prunt Argo CD die SealedSecrets und PushSecrets nicht. Die Secrets behalten dann die ownerReference des SealedSecrets, und ESO kann sie nicht übernehmen. Nach dem Merge deshalb in Argo CD manuell mit Prune synchronisieren (nur die entfernten SealedSecrets und PushSecrets). `prune` der Application nicht dauerhaft umstellen, das ist eine eigene Änderung.

### Wellen und Reihenfolge

1. **Welle 1 – Apps** (#623–#637). Den Anfang macht `vocabolario-dev` (#623): Es ist eine Dev-Umgebung und deckt `dockerconfigjson` und mehrzeilige Werte ab. Erkenntnisse daraus werden vor den übrigen Issues in diese Spec bzw. die CLAUDE.md übernommen.
2. **Welle 2 – Platform/Monitoring** (#638 coder, #639 dtrack, #640 kube-prometheus-stack).
3. **Welle 3 – Infrastruktur** (#641 keycloak, #642 oauth2-proxy, #643 cert-manager, #644 cloudflare, #645 argocd). Merge zu einem ruhigen Zeitpunkt, argocd zuletzt.

Innerhalb einer Welle ist die Reihenfolge frei.

| Issue | App | Verzeichnis | Secrets |
|---|---|---|---|
| #623 | vocabolario-dev | `cluster/apps/vocabolario-dev/vocabolario-app` | 9 |
| #624 | vocabolario | `cluster/apps/vocabolario/vocabolario-app` | 9 |
| #625 | club20-dev | `cluster/apps/club20-dev/club20-app` | 3 |
| #626 | club20 | `cluster/apps/club20/club20-app` | 3 |
| #627 | finance-tracker | `cluster/apps/finance-tracker/finance-tracker-app` | 2 |
| #628 | bmw | `cluster/apps/bmw/bmw-app/templates` | 2 |
| #629 | jenkins | `cluster/apps/jenkins/templates` | 2 |
| #630 | backrest | `cluster/apps/backrest/templates` | 2 |
| #631 | clash | `cluster/apps/clash/immich/templates` | 1 |
| #632 | forgejo | `cluster/apps/forgejo/forgejo-app/templates` | 4 |
| #633 | github-arc | `cluster/apps/github-arc/controller/templates` | 1 |
| #634 | guacamole | `cluster/apps/guacamole/templates` | 2 |
| #635 | openwebui | `cluster/apps/openwebui/app/templates` | 3 |
| #636 | xopenwebui | `cluster/apps/xopenwebui/app/templates` | 3 |
| #637 | paperless | `cluster/apps/paperless/app/templates` | 2 |
| #638 | coder | `cluster/platform/coder/app/templates` | 1 |
| #639 | dtrack | `cluster/platform/dtrack/app/templates` | 2 |
| #640 | kube-prometheus-stack | `cluster/monitoring/kube-prometheus-stack/kps/templates` | 2 |
| #641 | keycloak | `cluster/system/keycloak/templates` | 2 |
| #642 | oauth2-proxy | `cluster/system/oauth2-proxy/templates` | 2 |
| #643 | cert-manager | `cluster/system/cert-manager/templates` | 1 |
| #644 | cloudflare | `cluster/system/cloudflare/templates` | 2 |
| #645 | argocd | `cluster/bootstrap/argocd/templates` | 2 |

### Inaktive SealedSecrets (#622)

Diese SealedSecrets werden nicht migriert, weil keine aktive Application sie deployt:

- `s3-creds` in `cluster/apps/{bmw,clash,club20,club20-dev,finance-tracker,vocabolario,vocabolario-dev}/postgres/`
- `s3-creds` in `cluster/apps/{forgejo,openwebui,paperless,xopenwebui}/database/` und `cluster/platform/coder/database/`
- `cluster/apps/open-notebook/misc/open-notebook-secret.yaml`, `cluster/apps/open-notebook/misc/surrealdb-secret.yaml`, `cluster/apps/open-notebook/open-notbook/templates/open-notebook-secret.yaml`

Ob die Verzeichnisse entfernt werden, entscheidet #622. Wird eines davon später wieder aktiviert, bekommt es gleich ein ExternalSecret statt des SealedSecrets.

### Abschluss (#646)

Wenn alle Umstell-Issues erledigt sind:
- `ClusterSecretStore` `onepassword-push` und das SealedSecret `onepassword-push-service-account` entfernen
- Migrationsabschnitt der CLAUDE.md auf den Endzustand kürzen
- Der Mensch löscht den Push-Service-Account in 1Password.

## Akzeptanzkriterien

- [ ] Diese Spec liegt unter `docs/specs/620-sealedsecret-migration-rollout.md` und nennt Aufteilung, Wellen, Sonderfälle und die inaktiven SealedSecrets.
- [ ] Teil-Issues #621–#646 existieren und verweisen auf diese Spec. Die Abhängigkeiten stehen als `Blocked by` drin.
- [ ] Nach Abschluss aller Teil-Issues: Im Repo ist `onepassword-service-account` das einzige deployte SealedSecret, und es gibt kein `PushSecret` mehr.

## Nicht im Umfang

- Tokens der Secret-Stores: `onepassword-service-account` bleibt ein SealedSecret (Henne-Ei-Problem).
- Abbau des sealed-secrets-Controllers: Er wird für das Store-Token weiter gebraucht.
- Lückenlose Übernahme des Secrets (z. B. `Delete=false` plus `creationPolicy: Orphan`)
- Inhaltliche Änderungen an Secrets (Rotation, Umbenennen von Schlüsseln)

## Entscheidungen und Annahmen

- **Push gesammelt, Umstellen je App:** Schritt 1 ist ohne Wirkung auf den Cluster und lässt sich gefahrlos bündeln. Schritt 2 bleibt klein, damit jeder Merge (= Deploy) für sich prüfbar und rückbaubar ist.
- **Lücke beim Umstellen akzeptiert:** Laufende Pods behalten Env-Variablen und gemountete Inhalte. Kritisch ist nur ein Pod-Start in den wenigen Sekunden. Die Infrastruktur kommt deshalb in die letzte Welle und wird zu einem ruhigen Zeitpunkt gemergt. Ein lückenloses Verfahren wäre schwer per GitOps abzubilden.
- **Eintragsname `<namespace>#<secret-name>`:** wie im Piloten, eine 1:1-Zuordnung ohne Kollisionen. Gleichnamige Secrets in verschiedenen Namespaces (z. B. `externalregistry`, `db-secret`) bekommen getrennte Einträge.
- **Ein Issue pro App, auch bei Dev/Prod-Paaren:** Dev und Prod werden getrennt deployt und geprüft.
- **vocabolario-dev zuerst:** Dev-Umgebung, und sie deckt die Sonderfälle (`dockerconfigjson`, mehrzeilige Werte) ab, bevor Produktions-Apps folgen.
- **Inaktive SealedSecrets ausgeklammert:** Ohne deploytes Secret kann kein PushSecret schreiben, und ein ExternalSecret in einem nicht deployten Verzeichnis bringt nichts.
