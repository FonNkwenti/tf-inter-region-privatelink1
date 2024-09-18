
# #####################################################
# ## EC2 roles for Session Manager
# #####################################################

# resource "aws_iam_role" "ec2_exec_role" {
#   name = "ec2-exec-role"

#   assume_role_policy = jsonencode(
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# })

#   tags = merge(local.common_tags, {
#     tag-key = "ec2-exec-role"
#   })
# }


# resource "aws_iam_policy_attachment" "ssm_manager_attachment" {
#   name       = "ec2-exec-attachement"
#   roles      = [aws_iam_role.ec2_exec_role.name]
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "ec2_instance_profile" {
#   name = "ec2-instance-profile"
#   role = aws_iam_role.ec2_exec_role.name
# }


# #######################################################
# ##  EC2 PrivateLink Service Consumer
# #######################################################


# resource "aws_instance" "privateLink_consumer" {
#   ami                    = local.ami
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.pri_sn1_az1.id
#   associate_public_ip_address = false
#   key_name = "default-euw1"
#   vpc_security_group_ids = [aws_security_group.ssm_client.id]
#   iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

#   tags = merge(local.common_tags, {
#     Name = "main-test"
#   })
# }
