<h3>To deploy a DocumentDB cluster and a bastion host in an AWS VPC:</h3>
Export AWS credentials
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
...
```

Deploy infra using Terraform

```
cd documentdb/
terraform init
terraform plan
terraform apply --auto-approve
```
