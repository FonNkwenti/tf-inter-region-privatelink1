
# output "private_nlb_dns" {
#   value = aws_lb.private_nlb.dns_name
# }

# output "privateLink_service_name" {
#   value = aws_vpc_endpoint_service.this.service_name
# }


output "main_tgw_route_to_region_attachment_id" {
  value = aws_ec2_transit_gateway_route.main_to_region_route.transit_gateway_attachment_id
}
output "main_tgw_route_to_region_id" {
  value = aws_ec2_transit_gateway_route.main_to_region_route.id
}
output "main_tgw_route_to_region_cidr" {
  value = aws_ec2_transit_gateway_route.main_to_region_route.destination_cidr_block
}
output "main_tgw_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.main_tgw_route_table.id
}