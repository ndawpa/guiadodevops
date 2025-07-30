# Velero Azure Configuration

This directory contains the configuration for Velero backup and restore solution using Azure as the storage backend.

## Prerequisites

1. **Azure Storage Account**: You need an Azure Storage Account with a container for storing Velero backups
2. **Azure Credentials**: Service Principal or Storage Account credentials for authentication
3. **Vault Configuration**: The Azure credentials should be stored in Vault for secure access

## Configuration Steps

### 1. Azure Storage Setup

Create an Azure Storage Account and container:

```bash
# Create resource group (if not exists)
az group create --name velero-rg --location eastus

# Create storage account
az storage account create \
  --name velerostorage \
  --resource-group velero-rg \
  --location eastus \
  --sku Standard_LRS \
  --encryption-services blob

# Create container for backups
az storage container create \
  --name velero-backups \
  --account-name velerostorage
```

### 2. Azure Credentials

You have two options for authentication:

#### Option A: Storage Account Key (Simpler)
```bash
# Get storage account key
az storage account keys list \
  --account-name velerostorage \
  --resource-group velero-rg \
  --query '[0].value' \
  --output tsv
```

#### Option B: Service Principal (Recommended for production)
```bash
# Create service principal
az ad sp create-for-rbac \
  --name velero-sp \
  --role contributor \
  --scopes /subscriptions/your-subscription-id/resourceGroups/velero-rg
```

### 3. Vault Configuration

Store the credentials in Vault under the key `velero-azure-credentials` with the following structure:

For Storage Account Key:
```json
{
  "cloud": "[default]\nazure_storage_account_name=velerostorage\nazure_storage_account_key=your-storage-account-key"
}
```

For Service Principal:
```json
{
  "cloud": "[default]\nazure_client_id=your-client-id\nazure_client_secret=your-client-secret\nazure_subscription_id=your-subscription-id\nazure_tenant_id=your-tenant-id"
}
```

### 4. Update Configuration

Update the following values in `kubernetes/argocd/applications/core-tools/velero.yaml`:

- `bucket`: Your Azure storage container name
- `resourceGroup`: Your Azure resource group name
- `storageAccount`: Your Azure storage account name
- `subscriptionId`: Your Azure subscription ID (if different from cluster subscription)

## Files

- `external-secret-velero-azure-credentials.yaml`: External Secret configuration for Azure credentials
- `README.md`: This documentation file

## Verification

After deployment, verify that Velero is working correctly:

```bash
# Check Velero pods
kubectl get pods -n security -l app.kubernetes.io/name=velero

# Check backup storage location
kubectl get backupstoragelocation -n security

# Check volume snapshot location
kubectl get volumesnapshotlocation -n security

# Test backup
velero backup create test-backup --include-namespaces default
```

## Troubleshooting

### Common Issues

1. **Provider field missing**: Ensure the `provider: azure` is set in both backup and volume snapshot locations
2. **Credentials not found**: Verify the External Secret is created and the Vault key exists
3. **Storage account access**: Ensure the credentials have proper permissions to the storage account
4. **Resource group access**: Ensure the credentials have access to the specified resource group

### Logs

Check Velero logs for detailed error information:

```bash
kubectl logs -n security -l app.kubernetes.io/name=velero
``` 