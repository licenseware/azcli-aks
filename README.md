<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [AZ CLI for AKS](#az-cli-for-aks)
  - [Usage](#usage)
  - [FAQ](#faq)
    - [Why not use the azure-cli docker image instead?](#why-not-use-the-azure-cli-docker-image-instead)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# AZ CLI for AKS

[![ghcr-size](https://ghcr-badge.egpl.dev/licenseware/azcli-aks/size)](https://github.com/orgs/licenseware/packages/container/package/azcli-aks)
[![ghcr-tags](https://ghcr-badge.egpl.dev/licenseware/azcli-aks/latest_tag?label=latest-tag)](https://github.com/orgs/licenseware/packages/container/package/azcli-aks)

This Docker image allows for a disposable container to run `kubectl` commands
against an AKS cluster. The image is based on the official [`mcr.microsoft.com/azure-cli`][AZ CLI Official Docker] image.

## Usage

```yaml
# deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox
spec:
  replicas: 1
  selector:
    matchLabels:
      app: busybox
  template:
    metadata:
        app: busybox
    spec:
      containers:
      - image: busybox
        name: busybox
        command:
        - sleep
        - infinity
```

```bash
# entrypoint.sh
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="12345678-0000-0000-0000-000000000000"
export ARM_TENANT_ID="10000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID="20000000-0000-0000-0000-000000000000"

export AKS_CLUSTER_NAME=something
export AKS_RESOURCE_GROUP_NAME=something-else

az login --service-principal \
  -u "${ARM_CLIENT_ID}" -p "${ARM_CLIENT_SECRET}" --tenant ${ARM_TENANT_ID}
az aks get-credentials \
  --name ${AKS_CLUSTER_NAME} --resource-group ${AKS_RESOURCE_GROUP_NAME}
az account set --subscription ${ARM_SUBSCRIPTION_ID}

kubectl apply -f deployment.yml
```

```bash
docker run --rm \
  --name azcli \
  -v $(pwd)/entrypoint.sh:/entrypoint.sh:ro \
  -v $(pwd)/deployment.yml:/deployment.yml:ro \
  ghcr.io/licenseware/azcli-aks:2.57.0 \
  bash -eux /entrypoint.sh
```


## FAQ

### Why not use the azure-cli docker image instead?

It does not have the `kubelogin` installed, which is the [authenticator extension][kubelogin extension]
that allows for all the `kubectl` commands to work.

Beside the official AZ CLI image doesn't have `kubectl` installed. This image
has both.

[kubelogin extension]: https://github.com/Azure/kubelogin
[AZ CLI Official Docker]: https://mcr.microsoft.com/en-us/product/azure-cli/tags
