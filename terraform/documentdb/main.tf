# Reference the VPC that was created in the networking layer
data "aws_vpc" "my_vpc" {
  filter {
    name   = "tag:Name"
    values = ["my-vpc"]
  }
}

# Create public and private subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.my_vpc.id
  cidr_block              = "10.0.100.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnets)

  vpc_id                  = data.aws_vpc.my_vpc.id
  cidr_block              = var.private_subnets[count.index].cidr_block
  availability_zone       = "${var.aws_region}${var.private_subnets[count.index].availability_zone}"
  map_public_ip_on_launch = false
  tags = {
    Name = var.private_subnets[count.index].name
  }
}

# Create Internet Gateway and Route Table
resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.my_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = data.aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}


# Create DocumentDB and security group (Deploy DocumentDB inside the private subnet)
resource "aws_security_group" "docdb_sg" {
  vpc_id      = data.aws_vpc.my_vpc.id
  name        = "DocumentDB Security Group"
  description = "Security group for DocumentDB"

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # Allow traffic from the bastion security group
  }

  # Add new rule to allow traffic from HVN for Vault
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.hvn_cidr] # your HVN CIDR block - see HCP console
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create DocumentDB cluster with 2 nodes spanning 2 AZs
resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = "my-docdb-cluster"
  master_username         = "root"
  master_password         = "rootpassword" #for testing only! do not hardcode username and password in terraform config for prod
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.docdb_sg.id]
  db_subnet_group_name    = aws_docdb_subnet_group.my_docdb_subnet_group.name
}

resource "aws_docdb_cluster_instance" "docdb_node" {
  count              = 2
  identifier         = "docdb-node-${count.index}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = "db.t3.medium"
  tags = {
    name         = format("%s_docdb_node_%d", var.project_name, count.index)
    project_name = var.project_name
  }
}


# Create DocumentDB subnet group
resource "aws_docdb_subnet_group" "my_docdb_subnet_group" {
  name       = "my-docdb-subnet-group"
  subnet_ids = aws_subnet.private_subnet[*].id

  tags = {
    Name = "my-docdb-subnet-group"
  }
}

# Create Bastion host in public subnet
resource "aws_security_group" "bastion_sg" {
  vpc_id      = data.aws_vpc.my_vpc.id
  name        = "Bastion Security Group"
  description = "Security group for Bastion host"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # This allows SSH access from anywhere. Modify as per your requirements.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion_host" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = aws_subnet.public_subnet.id

  user_data = <<-EOF
              #!/bin/bash

              # Update system
              apt-get update

              # install web server
              apt-get install -y apache2
              echo "Hi from ec2" > /var/www/html/index.html
              systemctl start apache2
              systemctl enable apache2

              # install gnupg and curl
              apt-get install -y gnupg curl wget

              # Install Mongosh Shell for Ubuntu Focal
              # https://www.mongodb.com/docs/mongodb-shell/install/

              # Create the /etc/apt/sources.list.d/mongodb-org-7.0.list file for Ubuntu 20.04 (Focal)
              wget -qO- https://www.mongodb.org/static/pgp/server-7.0.asc | sudo tee /etc/apt/trusted.gpg.d/server-7.0.asc
              echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

              # Reload local package and install mongosh
              apt-get update
              apt-get install -y mongodb-mongosh

              # Check mongosh version
              mongosh --version

              # download pem for AWS SSL/TLS
              cd /home/ubuntu
              wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

              EOF
  tags = {
    Name = "Bastion Host"
  }
}

# Create public key for ssh. Run ssh keygen to generate key first
resource "aws_key_pair" "ssh" {
  key_name   = "ssh-key"
  public_key = file("~/.ssh/id_rsa.pub") # ensure you have the public key at this location or modify the path.
}
