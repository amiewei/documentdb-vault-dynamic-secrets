output "bastion_host_public_ip" {
  description = "Public IP of the Bastion Host"
  value       = aws_instance.bastion_host.public_ip
}

output "docdb_cluster_endpoint" {
  description = "Endpoint URL of the DocumentDB Cluster"
  value       = aws_docdb_cluster.docdb.endpoint
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.my_vpc.id
}

output "ssh_command" {
  description = "SSH tunnel for Bastion"
  value       = "ssh -L 27017:${aws_docdb_cluster.docdb.endpoint}:27017 ubuntu@${aws_instance.bastion_host.public_ip} -i ~/.ssh/id_rsa"
}
