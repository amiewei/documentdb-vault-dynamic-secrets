output "bastion_host_public_ip" {
  description = "Public IP of the Bastion Host"
  value       = aws_instance.bastion_host.public_ip
}

output "docdb_cluster_endpoint" {
  description = "Endpoint URL of the DocumentDB Cluster"
  value       = aws_docdb_cluster.docdb.endpoint
}

output "ssh_command" {
  description = "SSH tunnel for Bastion"
  value       = "ssh -L 27017:${aws_docdb_cluster.docdb.endpoint}:27017 ubuntu@${aws_instance.bastion_host.public_ip} -i ~/.ssh/id_rsa"
}

output "ubuntu_ami_id" {
  value = data.aws_ami.ubuntu_ami.id
}

output "aws_vpc_id" {
  value = data.aws_vpc.my_vpc.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public_route_table.id
}
