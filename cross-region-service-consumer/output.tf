# output "interface_endpoint_dns_name" {
#     value = aws_vpc_endpoint.privateLink_service.dns_entry[0].dns_name
# }

# output "session_manager_link" {
#   value = "https://console.aws.amazon.com/systems-manager/session-manager/${aws_instance.privateLink_consumer.id}"
# }