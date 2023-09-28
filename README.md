<h1 align="center"> Access AWS DocumentDB using Dynamic Secrets with HashiCorp Vault </h1>

---

<h3> Summary</h3>
This repo demonstrates an example of using HashiCorp Vault's MongoDB plugin for the database secrets engine to generate dynamic secrets for Amazon DocumentDB. DocumentDB is a fully managed NoSQL database service that has compatibility with MongoDB, which allows users to use the same MongoDB drivers, applications and tools with Amazon DocumentDB with little or no change.

<h3> Why is this important?</h3>

With the HashiCorp's Database Secrets Engine, applications can retrieve just-in-time secrets with role-specific permissions, ensuring they only access the data they need in DocumentDB. This reduces the risk of data breaches and adheres to the principle of least privilege.

<h3> What will we create?</h3>

To demonstrate generating dynamic secrets for DocumentDB, we will be performing the following:

-   Deploy networking and HCP Vault in AWS
-   Deploy DocumentDB with bastion host
-   Insert sample record into DocumentDB
-   Configure Vault to generate just-in-time secrets

![AWS & Vault Architecture Diagram](architecture_diagram.png)

---

<h3> Prerequisites</h3>

Have the following readily accessible. See links for free sign up.

✅ [HashiCorp Cloud Platform\*](https://www.hashicorp.com/cloud) \
✅ [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) \
✅ [Vault CLI](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install) \
✅ [AWS Account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html) \
✅ [Docker](https://docs.docker.com/engine/install/)

_\*HashiCorp Cloud Platform (HCP) enables access to Terraform Cloud and HCP Vault._

---

<h3> Act 1 - Deploy Networking Layer and HCP Vault</h3>

<h5> We will be deploying the following networking and Vault resources using Terraform Cloud (TFC)</h5>

-   HashiCorp Virtual Network (HVN) and HashiCorp Platform (HCP) Vault cluster in AWS
-   AWS VPC - for later use to deploy our DocumentDB cluster and bastion host
-   VPC peering between HVN and AWS VPC

<h5> 1.1. Update terraform config </h5>

In the terraform.tf file inside the terraform/network-vault directory, update the cloud block with your Terraform Cloud organization and workspace name.

Terraform Cloud can manage the lifecycle of your infrastructure and keep your statefile secure and versioned.

```.hcl
...

  cloud {
    organization = "your-tfc-org-name"

    workspaces {
      name = "aws-network-hcp-vault"
    }
  }

...
```

<h5> 1.2. Run terraform commands to deploy infrastructure to AWS</h5>

Export your AWS access keys and [HCP Service Principal keys](https://developer.hashicorp.com/hcp/docs/hcp/admin/iam/service-principals#create-a-service-principal):

```
export HCP_CLIENT_ID=
export HCP_CLIENT_SECRET=

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
...
```

Run Terraform commands to deploy the infrastructure:

```
cd terraform/network-vault
terraform init
terraform plan
terraform apply --auto-approve
```

<h5> 1.3 VPC Peering with HashiCorp Virtual Network (HVN)</h5>

View the HCP Vault console to see that the peering connection has been created. Peering allows your database and HCP vault to connect with each other to create/retrieve secrets.

For manual steps, see [HashiCorp developer docs for the HVN Quick Peering guide](https://developer.hashicorp.com/vault/tutorials/cloud-ops/amazon-peering-hcp?in=vault/cloud-ops)

⚠️ During the peering process, make sure you select the correct region where your AWS VPC is deployed.

<h3> Act 2 - Deploy DocumentDB Cluster with Bastion Host</h3>

<h5> 2.1 Generate SSH key pair</h5>

Generate SSH key pair and save your key pair locally. You will be prompted to enter file path to save the key (/Users/yourusername/.ssh/id_rsa). Press "Enter" to accept the default location (~/.ssh/id_rsa).

```
ssh-keygen -t rsa -b 4096
```

<h5> 2.2. Update terraform.tf</h5>

In the terraform.tf file inside the terraform/documentdb directory, update the cloud block with your Terraform Cloud organization ID and workspace name.

We will be managing this set of infrastructure in a separate TFC workspace to keep our design and state modular to promote better change management.

```.hcl
...

  cloud {
    organization = "your-tfc-org-name"

    workspaces {
      name = "aws-documentdb"
    }
  }

...
```

<h5> 2.3. Run terraform commands to deploy infrastructure to AWS</h5>

```
cd terraform/documentdb
terraform init
terraform plan
terraform apply --auto-approve
```

<h5> 2.4. Get the ssh command from the terraform output</h5>

```
# Example Terraform Output:
ssh_command = "ssh -L 27017:my-docdb-cluster.cluster-abcdefg.us-east-1.docdb.amazonaws.com:27017 ubuntu@1.123.123.123 -i ~/.ssh/id_rsa"
```

The command is constructed using the documentdb cluster address and the bastion host public ip. Update the path to your ssh private key depending on where you stored it.

⚠️ You need to run terraform locally to reference the ssh key stored locally. If you choose remote execution in Terraform Cloud, you will need to handle storing/passing the ssh key securely to Terraform Cloud.

---

<h3> Act 3 - Connect to DocumentDB and Insert Records</h3>

<h5> 3.1. Access the bastion host and establish ssh tunnel</h5>
Use the previous Terraform output from the above step.

```
ssh -L 27017:<documentdb-cluster-address>:27017 ubuntu@<bastion-public-ip> -i <path-to-your-ssh-private-key>
```

<h5> 3.2. Connect to DocumentDB using mongosh</h5>

Mongosh is a MongoDB shell that can be used with DocumentDB. Please note that although DocumentDB has MongoDB compatibility, not all functionalities of MongoDB and the Mongosh shell is available for use.

```
mongosh "mongodb://<username>:<password>@<documentdb-cluster-address>:27017/?ssl=true&retryWrites=false" --tls --tlsCAFile=<path/to/global-bundle.pem>

# Example:
mongosh "mongodb://root:rootpassword@my-docdb-cluster.cluster-abcdefg.us-east-1.docdb.amazonaws.com:27017/?ssl=true&retryWrites=false" --tls --tlsCAFile=global-bundle.pem
```

⚠️ Use `retryWrites=false` as Retryable writes are not supported in documentDB as of Oct 2023.

<h5> 3.3. Once connected using mongosh, create a collection and insert a document</h5>

```
# Create a new database named 'testdb'
use testdb

# Create a new collection named 'collaboration'
db.createCollection('collaboration')

# See what collections have been created
db.getCollectionNames()

# Insert a document into the collection
db.collaboration.insertOne({'partners':'HashiCorp & AWS'})

# See what documents are in the collection named 'testdb'
db.collaboration.find()
```

---

<h3> Act 4 - Configure the Vault Database Secrets Engine </h3>

Enable the database secrets engine in Vault and create a dynamic read-only role for DocumentDB using [hvac](https://github.com/hvac/hvac) which is a Python client library for Vault.

<h5>4.1 Build Docker Image</h5>

```
cd vault-config/
docker build -t db-configure-vault:latest .
```

<h5>4.2. Export Vault Environment Variables and DocumentDB Cluster Address</h5>
You can find the vault environment from the HCP Vault console.

```
export VAULT_ADDR=<vault-cluster-address>
export VAULT_NAMESPACE=<admin>
export VAULT_TOKEN=<very-secret-auth-token>
export DB_CLUSTER_ADDR=<endpoint-from-terraform-output>
```

<h5>4.3. Run container</h5>

```
docker run --name db-configure-vault --rm -e VAULT_ADDR -e VAULT_TOKEN -e VAULT_NAMESPACE -e DB_CLUSTER_ADDR db-configure-vault:latest
```

⚠️ With the --rm flag, the container will be removed automatically once it stops running.

<h5> 4.4. Test Your New Credentials!</h5>

Generate username and password from the dynamic role from Vault.

```
vault read database/creds/docdb-read-only-role
```

Within the established ssh tunnel, and login into DocumentDB using your new credentials.

```
mongosh "mongodb://<username>:<password>
@<documentdb-cluster-endpoint>:27017/admin?ssl=true&retryWrites=false" --tls --tlsCAFile=global-bundle.pem

# example
mongosh "mongodb://v-token-hcp-root-docdb-read-only-ABCDE-1234567:abcdefgHIJK@my-docdb-cluster.cluster-abcdefg.us-east-1.docdb.amazonaws.com:27017/admin?ssl=true&retryWrites=false" --tls --tlsCAFile=global-bundle.pem
```

Once connected, see all users, including the new user that was created by Vault.

```
db.getUsers()
```

Read the collection and document that was inserted.

```
use testdb
db.collaboration.find()
```

Attempt to delete a document in testdb. Spoiler alert, you won't be allowed as the role does not have permission.

```
db.collaboration.deleteOne({})
```

---

<h3> Curtain Close </h3>

<h5> 5.1. Clean Up</h5>

-   Exit out of any SSH and db connections
-   Run `terraform destroy` from the terraform/documentdb/ and subsequently terraform/network-vault/ directories
-   Note: deleting the DocumentDB cluster may take ~10 minutes depending on cluster size

---

<h3>Other Helpful Materials </h3>

-   [Get Started with AWS DocumentDB](https://docs.aws.amazon.com/documentdb/latest/developerguide/get-started-guide.html)
-   [Terraform Cloud Quick Start Tutorial](https://developer.hashicorp.com/terraform/tutorials/cloud-get-started)
-   [HCP Vault Quick Start Tutorial](https://developer.hashicorp.com/vault/tutorials/cloud)
-   [Vault Database Secrets Engine Developer Docs](https://developer.hashicorp.com/vault/docs/secrets/databases)
-   [MongoDB Plugin for the Vault Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases/mongodb)
-   [hvac Python Client Library Database Engine docs](https://hvac.readthedocs.io/en/stable/usage/secrets_engines/database.html#)

---

<br>

<h5 align="center">🙅🏻‍♀️DEMO ONLY - REPO NOT FOR PROD USE🙅🏻‍♀️</h5>
