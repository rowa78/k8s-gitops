# SealedSecret-Migration nach External Secrets – Pilot renovate-rwcloud

Issue: #616 (Schritt 1), #617 (Schritt 2)

## Ziel

Die SealedSecrets sollen schrittweise durch ExternalSecrets aus 1Password ersetzt werden, ohne Werte von Hand zu übertragen. Der Pilot in `renovate-rwcloud` erprobt den Ablauf; danach dient er als Muster für die übrigen Apps.

## Kontext

- Im Repo liegen rund 77 SealedSecrets in etwa 25 Apps.
- Der External Secrets Operator ist eingerichtet (`cluster/system/external-secrets`). Der `ClusterSecretStore` `onepassword` (Provider `onepasswordSDK`, Tresor `k8s`) nutzt einen nur lesenden Service-Account. Dessen Token liegt als SealedSecret im Repo.
- `renovate-rwcloud` hat genau ein SealedSecret (`renovate`, Schlüssel `RENOVATE_TOKEN` und `RENOVATE_GITHUB_COM_TOKEN`). Renovate läuft als CronJob, eine kurze Lücke beim Umstellen ist unkritisch. Deshalb eignet sich die App als Pilot.
- Der Provider `onepasswordSDK` unterstützt `PushSecret`. `remoteRef.property` ist der Feldname im Eintrag.

## Lösungsansatz

Zwei getrennte Merges (Merge = Deploy). Schritt 2 startet erst, wenn der Eintrag im Tresor nachweislich existiert.

### Schritt 1 (#616): Push-Store und PushSecret

1. **Vorarbeit durch den Menschen:**
   - In 1Password einen zweiten Service-Account mit Schreibrecht auf den Tresor `k8s` anlegen.
   - Den Token mit `kubeseal` als SealedSecret `onepassword-push-service-account` versiegeln: Namespace `external-secrets`, Schlüssel `token`, Datei `cluster/system/external-secrets/templates/onepassword-push-service-account.yaml`.
   - Die Datei in den PR-Branch committen.
   - Der Build-Agent bereitet den genauen Befehl unter „Für dich zu tun" im PR vor.
2. In `cluster/system/external-secrets/templates/` einen neuen `ClusterSecretStore` `onepassword-push` anlegen: Provider `onepasswordSDK`, Tresor `k8s`, Auth über das Secret `onepassword-push-service-account`/`token`, Sync-Welle wie beim bestehenden Store.
3. In `cluster/system/renovate-rwcloud/templates/` ein `PushSecret` anlegen:
   - `secretStoreRefs`: `ClusterSecretStore` `onepassword-push`
   - `selector.secret.name`: `renovate`
   - je Schlüssel ein Eintrag in `data`: `match.secretKey` = Schlüssel, `remoteRef.remoteKey` = `renovate-rwcloud#renovate`, `remoteRef.property` = Schlüssel
   - `deletionPolicy: None` (Standard, ausdrücklich gesetzt), damit das Entfernen in Schritt 2 den Eintrag nicht löscht
   - `refreshInterval: 1h`

### Schritt 2 (#617): Umstellen und dokumentieren

1. `cluster/system/renovate-rwcloud/templates/secret.yaml` (SealedSecret) und das PushSecret entfernen.
2. `ExternalSecret` `renovate` anlegen: Store `onepassword`, `target.name: renovate`, `dataFrom.extract.key: renovate-rwcloud#renovate`. Trägt der Eintrag Zusatzfelder ins Secret, stattdessen `data` mit den zwei Schlüsseln verwenden.
3. In der CLAUDE.md unter „Konventionen" ergänzen:
   - den Migrationsablauf als Muster (PushSecret → prüfen → umstellen)
   - die Regel: SealedSecrets nur noch für die Tokens der Secret-Stores (Henne-Ei-Problem), sonst ExternalSecret.

### Ablauf beim Umstellen

Das Kubernetes-Secret gehört dem SealedSecret (ownerReference). Prunt Argo CD das SealedSecret, löscht die Garbage Collection das Secret mit. Danach legt ESO es neu an. Für einige Sekunden fehlt das Secret. Das ist für diese App akzeptiert.

## Akzeptanzkriterien

### Schritt 1 (#616)

- [ ] `ClusterSecretStore` `onepassword-push` liegt in `cluster/system/external-secrets/templates/` und verweist auf das Secret `onepassword-push-service-account` (Schlüssel `token`) im Namespace `external-secrets`.
- [ ] Der bestehende Store `onepassword` bleibt unverändert.
- [ ] `PushSecret` in `renovate-rwcloud` überträgt `RENOVATE_TOKEN` und `RENOVATE_GITHUB_COM_TOKEN` als gleichnamige Felder in den Eintrag `renovate-rwcloud#renovate`. `deletionPolicy: None`.
- [ ] Das SealedSecret `renovate` bleibt unverändert.
- [ ] Im PR steht unter „Für dich zu tun" der genaue `kubeseal`-Befehl für den Push-Token.
- [ ] Pflicht-Prüfungen grün. Außer dem Push-Token kommt kein neues SealedSecret dazu.
- [ ] Nach Deploy (prüft der Mensch): Store `onepassword-push` Ready, PushSecret synced, Eintrag mit beiden Feldern im Tresor `k8s`.

### Schritt 2 (#617)

- [ ] SealedSecret `renovate` und PushSecret sind entfernt.
- [ ] `ExternalSecret` `renovate` über Store `onepassword` mit `dataFrom.extract` auf `renovate-rwcloud#renovate`.
- [ ] Nach Deploy (prüft der Mensch): Das Secret `renovate` gehört dem ExternalSecret und enthält genau die zwei Schlüssel, der nächste Renovate-Lauf klappt.
- [ ] CLAUDE.md enthält den Migrationsablauf und die Regel zu SealedSecrets.
- [ ] Pflicht-Prüfungen grün.

## Nicht im Umfang

- Migration der übrigen SealedSecrets (eigene Issues je App/Namespace)
- Abbau des Push-Stores und des Push-Service-Accounts (erst, wenn alles migriert ist)
- Anpassung von #611

## Entscheidungen und Annahmen

- **Eigener Schreib-Store statt Schreibrecht für den bestehenden Account:** Der normale Store bleibt nur lesend. Der Schreibzugriff existiert nur während der Migration und lässt sich danach entfernen.
- **Push-Token als SealedSecret:** Wie beim bestehenden Store-Token gibt es ein Henne-Ei-Problem. SealedSecrets bleiben deshalb für Store-Tokens erlaubt.
- **Eintrag pro Secret, Name `<namespace>#<secret-name>`:** Die Zuordnung ist 1:1, gleiche Schlüssel in verschiedenen Secrets kollidieren nicht, und `dataFrom.extract` funktioniert ohne Umbenennen. Bei Apps mit genau einem Secret entspricht das der bisherigen Konvention `<namespace>#<app>`.
- **Zwei Issues statt eines:** Die Factory macht einen PR pro Issue, die Schritte müssen aber getrennt deployt werden.
- **Kurze Lücke beim Umstellen akzeptiert:** Für Apps, bei denen ein fehlendes Secret für einige Sekunden kritisch ist, wird das bei der jeweiligen Migration neu bewertet.
