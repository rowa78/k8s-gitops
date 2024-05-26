1. Install secret with certificates

kubectl -n sealed-secrets create secret tls sealed-secrets-rwcloud-key --cert=sealed-secrets-rwcloud.crt --key=sealed-secrets-rwcloud.key

k -n sealed-secrets label secrets sealed-secrets-rwcloud-key sealedsecrets.bitnami.com/sealed-secrets-key=active