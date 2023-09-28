<h1 align="center"> Access AWS DocumentDB using Dynamic Secrets with HashiCorp Vault </h1>

---

<h3> Summary</h3>

What is AWS DocumentDB
What is HashiCorp Vault
What is Terraform Cloud

<h5> Why this is important?</h5>

With the HashiCorp's Database Secrets Engine, applications can get just-in-time secrets with role-specific permissions, ensuring they only access the data they need in DocumentDB. This reduces the risk of data breaches and adheres to the principle of least privilege.

<h5> What we will deploy? </h5>

-   DocumentDB cluster with Bastion Host in a AWS VPC
-   HCP Vault in AWS
-   VPC peering between the two VPCs to allow Vault access DocumentDB to generate just in time secrets

    ![diagram](architecture_diagram.png)

---

<h3> Prerequisites</h3>

Have the following readily accessible:

✅ Terraform Cloud \
✅ HCP Vault deployed in AWS \
✅ Terraform CLI \
✅ Vault CLI \
✅ AWS Account with permission to create resources such as DocumentDB, EC2 and networking components \
✅ Docker

Click [HERE](https://www.hashicorp.com/cloud) to sign up for HashiCorp Cloud Platform (HCP) and access Terraform Cloud and HCP Vault for free.

---

<h3> Act 1 - Deploy DocumentDB Cluster with Bastion Host</h3>

<h5> 1.1 Generate SSH key pair </h5>

Generate SSH key pair and save your key pair locally. You will be prompted to enter filepath in which to save the key (/Users/yourusername/.ssh/id_rsa). Press "Enter" to accept the default location (~/.ssh/id_rsa).

```
ssh-keygen -t rsa -b 4096
```

[optional] change its permission to be read-only for your user

```
chmod 400 ~/.ssh/id_rsa
```

<h5> 1.2. Update terraform.tf </h5>

In the terraform.tf file inside the terraform directory, update the cloud block with your Terraform Cloud organization ID and workspace name so Terraform Cloud can manage the lifecycle of your infrastructure and keep your statefile secure and versioned.

```
cloud {
    organization = "your-tfc-org"


    workspaces {
    name = "aws-documentdb"
    }
}
```

<h5> 1.3. Run terraform commands to deploy infrastructure to AWS </h5>

```
cd terraform/
terraform init
terraform plan
terraform apply --auto-approve
```

<h5> 1.4. Get the ssh command from the terraform output</h5>

```
# example Terraform Output:
ssh_command = "ssh -L 27017:my-docdb-cluster.cluster-abcdefg.us-east-1.docdb.amazonaws.com:27017 ubuntu@23.123.123.123 -i ~/.ssh/id_rsa"
```

The command is constructed using the documentdb cluster address and the bastion host public ip. Update the path to your ssh private key depending on where you stored it.

⚠️ You need to run terraform locally to reference the ssh key stored locally. If you choose remote execution in Terraform Cloud, you will need to handle storing/passing the ssh key securely to Terraform Cloud.

---

<h3> Act 2 - Connect to DocumentDB and Insert Records</h3>

<h5> 2.1. Access the bastion host and establish ssh tunnel</h5>

```
ssh -L 27017:<documentdb-cluster-address>:27017 ubuntu@<bastion-public-ip> -i path/to/your/ssh-private-key

# example:
ssh -L 27017:my-docdb-cluster.cluster-abcdefg.us-east-1.docdb.amazonaws.com:27017 ubuntu@23.123.123.123 -i ~/.ssh/id_rsa
```

<h5> 2.2. Connect to DocumentDB using mongosh</h5>

Mongosh is a mongodb shell that can be used with DocumentDB. Although DocumentDB has MongoDB compatibility, not all functionalities of MongoDB and the Mongosh shell is available for use.

```
mongosh "mongodb://username:password@<documentdb-cluster-address>:27017/?ssl=true&retryWrites=false" --tls --tlsCAFile=<path/to/global-bundle.pem>

# example:
mongosh "mongodb://root:rootpassword@my-docdb-cluster.cluster-abcdefg.us-east-1.docdb.amazonaws.com:27017/?ssl=true&retryWrites=false" --tls --tlsCAFile=global-bundle.pem
```

⚠️ Use `retryWrites=false` as Retryable writes are not supported in documentDB

<h5> 2.3. Once connected using mongosh, create a collection and insert a document</h5>

```
# create a new database named 'testdb'
use testdb


# create a new collection named 'collaboration'
db.createCollection('collaboration')


# see what collections already exist
db.getCollectionNames()


# Insert a document into the collection
db.collaboration.insertOne({'partners':'HashiCorp & AWS'})


# see what documents are in the collection named 'testdb'
db.collaboration.find()
```

---

<h3> Act 3 - Configure Vault and Setup Dynamic Secrets using the MongoDB plugin</h3>

<h5> 3.1. VPC Peering with HashiCorp Virtual Network (HVN)</h5>

Using the HCP Vault console, initiate the peering connection. Peering allows your database and HCP vault to connect with each other to create/retrieve secrets.

See [HashiCorp developer docs for the HVN Quick Peering guide](https://developer.hashicorp.com/vault/tutorials/cloud-ops/amazon-peering-hcp?in=vault/cloud-ops) for steps. (This Quick Peering guide setup only took around 5 minutes for me!)

You will need to input the vpc id for the vpc created by terraform. (See value from Terraform ouput)

⚠️ During the peering process, make sure you select the correct region where your vpc is deployed to locate your vpc

<h5> 3.2. Add a route to allow Vault to access DocumentDB which is deployed in a private subnet</h5>

Find your HVN CIDR block and update the ingress rule for the DocumentDB Security Group in main.tf in the terraform directory

```
# DocumentDB and security group (Deploy DocumentDB inside the private subnet)


resource "aws_security_group" "docdb_sg" {
    vpc_id = aws_vpc.my_vpc.id
    name = "DocumentDB Security Group"
    description = "Security group for DocumentDB"


ingress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # Allow traffic from the bastion security group
}


# Add new rule to allow traffic from HVN for Vault
ingress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["172.25.16.0/20"] # ❗️Replace with your HVN CIDR block - see HCP console
}


egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}


```

Run Terraform commands again to deploy the change to AWS

```
cd terraform/
terraform init
terraform plan
terraform apply --auto-approve
```

<h5> 3.3. Export Vault environment variables to shell</h5>

```
export VAULT_ADDR=<vault-address>
export VAULT_TOKEN=<token>
export VAULT_NAMESPACE="admin"
```

<h5> 3.4. Enable the database secrets engine in Vault and create a dynamic read-only role for DocumentDB</h5>

```
chmod +x vault-config/db-init.sh
./vault-config/db-init.sh
```

⚠️ The last step in db-init.sh calls out to config.py to create the database connection string. The reason for doing this separately using python is due to the limit in size of the .pem file that can be processed by the shell script.

<h5> 3.5 Test your new credentials!</h5>

Generate username and password from the dynamic role from Vault

```
vault read database/creds/docdb-read-only-role
```

Go to your ssh tunnel, and login into documentdb using your new credentials

```
mongosh "mongodb://<username>:<password>
@<documentdb-cluster-address>:27017/admin?ssl=true&retryWrites=false" --tls --tlsCAFile=global-bundle.pem
```

Once connected, see all users, including the new user that was created

```
db.getUsers()
```

Read the collection and document that was inserted

```
use testdb
db.collaboration.find()
```

Attempt to delete a document in testdb. Spoiler alert, you won't be allowed as the role does not have permission

```
db.collaboration.deleteOne({})
```

---

<h3> Curtain Close</h3>

<h5>Clean Up</h5>

-   Exit out of any SSH and db connections
-   Delete HVN connection via the HCP Vault console
-   Run `terraform destroy` \
    Note - deleting DocumentDB resources may take a few minutes

---

<h3> Other Helpful Materials</h3>

-   AWS docs
-   Terraform docs
-   Vault docs

---

<br>

<h5 align="center">🙅🏻‍♀️DEMO ONLY - REPO NOT FOR PROD USE🙅🏻‍♀️</h5>
