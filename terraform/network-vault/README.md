Export HCP Service Principal secrets into your shell

```
export HCP_CLIENT_ID=
export HCP_CLIENT_SECRET=
```

<h3>To deploy the AWS networking layer + HCP Vault:</h3>
Export AWS credentials

```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
...
```

Deploy infra using Terraform

```
cd network-vault/
terraform init
terraform plan
terraform apply --auto-approve
```
