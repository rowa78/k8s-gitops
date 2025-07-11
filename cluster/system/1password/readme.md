Initale installation der secrets:

cat 1password-credentials.json| base64

Dieser base64 string muss ins secret:

k -n 1password create secret generic op-credentials --from-literal=1password-credentials.json=<base64>



und der token:

k -n 1password create secret generic onepassword-token --from-literal=token=<the_token>



Anlegen eines Secrets:



apiVersion: onepassword.com/v1
kind: OnePasswordItem
metadata:
  name: foo
spec:
  itemPath: "vaults/k8s/items/foo"