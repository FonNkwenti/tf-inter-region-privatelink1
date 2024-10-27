# output "interface_endpoint_dns_name" {
#     value = aws_vpc_endpoint.privateLink_service.dns_entry[0].dns_name
# }


output "cli_cmd" { 
    description = "The AWS cli command to connect to your EC2 instance through the connect point"
    value = "aws ec2-instance-connect ssh --instance-id ${module.ec2_instance.id} --os-user ec2-user --connection-type eice --region ${var.main_region}"
}

output "instance_id" {
  value = module.ec2_instance.id
}
output "instance_private_ip" {
  value = module.ec2_instance.private_ip
}