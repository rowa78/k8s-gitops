# Postfix Helm Chart

This Helm chart deploys a Postfix mail server on a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.12+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (if persistence is enabled)

## Installing the Chart

To install the chart with the release name `postfix`:

```bash
helm install postfix .
```

## Configuration

The following table lists the configurable parameters of the Postfix chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `replicaCount`           | Number of replicas      | `1`            |
| `image.repository`       | Image repository        | `registry.rwcloud.org/postfix` |
| `image.tag`              | Image tag (overrides Chart.appVersion if set) | `""` (uses Chart.appVersion) |
| `image.pullPolicy`       | Image pull policy       | `IfNotPresent` |
| `image.pullSecrets`      | List of image pull secrets | `[]` |
| `service.type`           | Service type            | `ClusterIP`    |
| `service.port`           | Service port            | `25`           |
| `persistence.enabled`    | Enable persistence      | `true`         |
| `persistence.storageClass`| Storage class          | `""`           |
| `persistence.accessMode` | Access mode             | `ReadWriteOnce`|
| `persistence.size`       | Storage size            | `1Gi`          |
| `resources`              | CPU/Memory resource requests/limits | `{}` |
| `securityContext.runAsUser` | User ID to run the container | `100` (postfix) |
| `securityContext.runAsGroup` | Group ID to run the container | `101` (postfix) |
| `securityContext.fsGroup` | File system group ID for volumes | `101` (postfix) |
| `securityContext.supplementalGroups` | Additional groups for the container | `[12]` (mail) |
| `nodeSelector`           | Node labels for pod assignment | `{}`    |
| `tolerations`            | Tolerations for pod assignment | `[]`    |
| `affinity`               | Affinity for pod assignment | `{}`       |
| `postfix.config`         | Postfix configuration   | `{}`           |
| `certificates.secretName` | Name of existing secret containing certificates | `""` |
| `certificates.createSecret` | Whether to create a secret from provided certificate data | `false` |
| `certificates.data`     | Certificate data to include in the secret | `{}` |
| `additionalSecrets.existingSecrets` | List of existing secrets to mount to /etc/postfix/custom/ | `[]` |
| `additionalSecrets.createSecret` | Whether to create a secret from provided data | `false` |
| `additionalSecrets.data` | Secret data to include in the created secret | `{}` |
| `probes.liveness.enabled` | Enable liveness probe | `true` |
| `probes.liveness.*` | Liveness probe configuration | See values.yaml |
| `probes.readiness.enabled` | Enable readiness probe | `true` |
| `probes.readiness.*` | Readiness probe configuration | See values.yaml |
| `probes.startup.enabled` | Enable startup probe | `true` |
| `probes.startup.*` | Startup probe configuration | See values.yaml |

## Persistence

This chart mounts a Persistent Volume at `/var/lib/postfix`. The volume is created using dynamic volume provisioning.

## Customization

### Configuration via values.yaml

To customize the Postfix configuration through values.yaml, modify the `postfix.config` section.

### Custom Configuration Files

You can add custom configuration files by placing them in the `files/` directory. These files will be mounted to `/etc/postfix/custom/` in the container.

Example usage:

1. Place your configuration files in the `files/` directory
2. The files will be automatically added to a ConfigMap
3. The ConfigMap will be mounted to `/etc/postfix/custom/` in the container
4. Reference these files in your Postfix configuration

### Additional Secrets

You can mount additional secrets to the `/etc/postfix/custom/` directory in two ways:

#### Using Existing Secrets

Specify existing secrets to mount in the `additionalSecrets.existingSecrets` list:

```yaml
additionalSecrets:
  existingSecrets:
    - name: my-postfix-secret
      items: # Optional, if not specified all keys from the secret will be mounted
        - key: secret-key-1
          path: filename-in-custom-dir-1
        - key: secret-key-2
          path: filename-in-custom-dir-2
```

Each secret will be mounted to `/etc/postfix/custom/<secret-name>/`.

#### Creating a New Secret

You can also create a new secret with data specified in the values file:

```yaml
additionalSecrets:
  createSecret: true
  data:
    username: myusername
    password: mypassword
```

This secret will be mounted to `/etc/postfix/custom/secrets/`.

These secrets can be used for sensitive configuration like SASL authentication, relay passwords, etc.
