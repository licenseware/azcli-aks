<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [AZ CLI for AKS](#az-cli-for-aks)
  - [Service Principal Creation](#service-principal-creation)
  - [Usage](#usage)
  - [FAQ](#faq)
    - [Why not use the azure-cli docker image instead?](#why-not-use-the-azure-cli-docker-image-instead)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# AZ CLI for AKS

[![ghcr-size](https://ghcr-badge.egpl.dev/licenseware/azcli-aks/size)](https://github.com/orgs/licenseware/packages/container/package/azcli-aks)
[![ghcr-tags](https://ghcr-badge.egpl.dev/licenseware/azcli-aks/latest_tag?label=latest-tag)](https://github.com/orgs/licenseware/packages/container/package/azcli-aks)

This Docker image allows for a disposable container to run `kubectl` commands
against an AKS cluster. The image is based on the official [`mcr.microsoft.com/azure-cli`][AZ CLI Official Docker] image.

## Service Principal Creation

If you want to see the TF code that created the Service Principal, expand the
details below.

<details>
<summary>Expand for details</summary>

```terraform
data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "azurerm_kubernetes_cluster" "this" {
  name                = "my-aks-cluster"
  resource_group_name = "my-rg"
}


resource "azuread_application" "this" {
  display_name = "my-aks-app"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "this" {
  app_role_assignment_required = false
  client_id                    = azuread_application.this.client_id
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "time_rotating" "this" {
  rotation_days = 7
}

resource "azuread_service_principal_password" "this" {
  service_principal_id = azuread_service_principal.this.object_id
  rotate_when_changed = {
    rotation = time_rotating.this.id
  }
}

resource "azurerm_role_assignment" "aks_rbac" {
  principal_id         = azuread_service_principal.this.object_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  scope                = data.azurerm_kubernetes_cluster.this.id
}

output "client_id" {
  value = azuread_service_principal.this.client_id
}

output "client_secret" {
  value     = azuread_service_principal_password.this.value
  sensitive = true
}
```

</details>

## Usage

```bash
# entrypoint.sh
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="12345678-0000-0000-0000-000000000000"
export ARM_TENANT_ID="10000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID="20000000-0000-0000-0000-000000000000"

export AKS_CLUSTER_NAME=something
export AKS_RESOURCE_GROUP_NAME=something-else

az login --service-principal \
  -u "${ARM_CLIENT_ID}" \
  -p "${ARM_CLIENT_SECRET}" \
  --tenant ${ARM_TENANT_ID}
az aks get-credentials \
  --name ${AKS_CLUSTER_NAME} \
  --resource-group ${AKS_RESOURCE_GROUP_NAME}
az account set --subscription ${ARM_SUBSCRIPTION_ID}

kubelogin convert-kubeconfig \
  --context ${AKS_CLUSTER_NAME} \
  --client-id "${ARM_CLIENT_ID}" \
  --tenant-id "${ARM_TENANT_ID}" \
  --client-secret "${ARM_CLIENT_SECRET}" \
  -l spn # <-- service principal

# This requires sufficient Kubernetes RBAC
kubectl get pods
```

```bash
docker run --rm \
  --name azcli \
  -v $(pwd):/app:ro \
  ghcr.io/licenseware/azcli-aks:2.57.0 \
  bash -eux /app/entrypoint.sh
```

## FAQ

### Why not use the azure-cli docker image instead?

It does not have the `kubelogin` installed, which is the [authenticator extension][kubelogin extension]
that allows for all the `kubectl` commands to work.

Beside the official AZ CLI image doesn't have `kubectl` installed. This image
has both.

[kubelogin extension]: https://github.com/Azure/kubelogin
[AZ CLI Official Docker]: https://mcr.microsoft.com/en-us/product/azure-cli/tags
