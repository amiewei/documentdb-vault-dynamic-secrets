import os
import urllib.request
import hvac
import json

# Export vault address and token to your shell
vault_address = os.environ.get("VAULT_ADDR")
vault_token = os.environ.get("VAULT_TOKEN")
vault_namespace = os.environ.get("VAULT_NAMESPACE")
db_cluster_address = os.environ.get("DB_CLUSTER_ADDR")

connection_name = "my-documentdb"
pem_file_path = "./global-bundle.pem"
pem_url = "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem"

# Create a client instance for Vault
client = hvac.Client(url=vault_address, token=vault_token, namespace=vault_namespace)

# Check if the database secrets engine is enabled and enable as needed
enabled_secrets_engines = client.sys.list_mounted_secrets_engines()

if "database/" in enabled_secrets_engines["data"]:
    print("Database secrets engine is already enabled.")
else:
    client.sys.enable_secrets_engine("database")
    print("Database secrets engine enabled")

# Grants read only access to the database we created; Grants userAdmin access which allows listing of all users.
creation_statements = [
    json.dumps({
        "db": "admin",
        "roles": [{"role": "read"}, {"role": "read", "db": "testdb"}, {"role": "userAdmin", "db": "admin"}]
    })
]

# Create a new role for the db connection
client.secrets.database.create_role(
    name='docdb-read-only-role',
    db_name=connection_name,
    creation_statements=creation_statements,
    default_ttl='2h',
    max_ttl='24h'
)

# Check if .pem file exists
if not os.path.exists(pem_file_path):
    print("Downloading .pem file")
    urllib.request.urlretrieve(pem_url, pem_file_path)

# Read the .pem content
with open(pem_file_path, "r") as file:
    pem_content = file.read()

# Configure the database using hvac with the MongoDB database plugin
response = client.secrets.database.configure(
    name=connection_name,
    plugin_name='mongodb-database-plugin',
    allowed_roles='docdb-read-only-role',
    connection_url=f'mongodb://{{{{username}}}}:{{{{password}}}}@{db_cluster_address}:27017/admin',
    username='root',
    password='rootpassword',
    tls_ca=pem_content
)

print("Creating DB connection...")
if response:
    print(response)
else:
    print("Failed to create DB connection")
