cloudflared login

tunnel erstellen: 

cloudflared tunnel create k3s
Tunnel credentials written to /Users/ronny/.cloudflared/74c14a60-f8fa-4fd4-a4f8-df5a03a059f9.json. cloudflared chose this file based on where your origin certificate was found. Keep this file secret. To revoke these credentials, delete the tunnel.

Created tunnel k3s with id 74c14a60-f8fa-4fd4-a4f8-df5a03a059f9


secret erstellen:

apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: tunnel-credentials
data:
  {{- if eq .Values.tunnelSecrets.existingConfigJsonFileSecret.name "" }}
  credentials.json: {{ required "Base64 encoded config file string is required! Run base64 -b 0 -i ~/.cloudflared/*.json and add output to tunnelSecrets.base64EncodedConfigJsonFile in values.yaml file." .Values.tunnelSecrets.base64EncodedConfigJsonFile | quote }}
  {{- end }}
  {{- if eq .Values.tunnelSecrets.existingPemFileSecret.name "" }}
  cert.pem: {{ required "Base64 encoded certificate pem file string is required! Run base64 -b 0 -i ~/.cloudflared/cert.pem and add output to tunnelSecrets.base64EncodedPemFile in values.yaml file." .Values.tunnelSecrets.base64EncodedPemFile | quote }}
  {{- end }}

  