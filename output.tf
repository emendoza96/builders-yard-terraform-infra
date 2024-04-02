output "bastion_public_ip" {
  value = aws_instance.bastion_host.public_ip
}

output "ec2_private_ip" {
  value = aws_instance.ec2_private_server.private_ip
}