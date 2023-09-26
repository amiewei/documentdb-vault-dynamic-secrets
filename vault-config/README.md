<h5>1. Build Docker Image</h5>

```
cd vault-config/
docker build -t db-configure-vault:latest .
```

<h5>2. Export Vault Environemnt Variables</h5>

```
export VAULT_ADDR=<vault-cluster-address>
export VAULT_NAMESPACE=<admin>
export VAULT_TOKEN=<very-secret-auth-token>
export DB_CLUSTER_ADDR=<addr-from-terraform-output>
```

<h5>3. Run container</h5>

```
docker run --name db-configure-vault --rm -e VAULT_ADDR -e VAULT_TOKEN -e VAULT_NAMESPACE -e DB_CLUSTER_ADDR db-configure-vault:latest
```

Note: with the --rm flag, container will be removed automatically once it stops running
