#-------Networking/outputs.tf ------------

output "vpc_id" {
  value = aws_vpc.hiba_vpc.id
}

# RDS outputs  

output "db_subnet_group_name" {
  value = aws_db_subnet_group.hiba_rds_subnetgroup.*.name
}

output "db_security_group" {
  value = aws_security_group.hiba_sg["rds"].id
}

output "public_sg" {
  value = aws_security_group.hiba_sg["public"].id
}

output "public_subnets" {
  value = aws_subnet.hiba_public_subnet.*.id
}