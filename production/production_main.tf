##poduction main.tf

provider "aws" {
  alias = "eu-central-1"  
  region = "eu-central-1"
}

#####################################################
# variables

variable "production_ami_id" {
  description = "AMI ID for the production EC2 instance need to change"
  type        = string
  default     = "ami-09024b009ae9e7adf"
}
variable "ec2_type" {
  description = "the type of the Ec2 we want. need change"
  type = string
  default = "t2.micro"
}

variable "kaypair" {
  description = "the kay pair for SSH need to change"
  type = string
  default = "example"  
}
variable "vpc_cidr" {
  description = "the cidr block for the production VPC"
  type = string
  default = "10.1.0.0/16"
}
variable "public_sub_1_cidr" {
  description = "the cidr block for the public subnet 1"
  type = string
  default = "10.1.1.0/24"
}
variable "public_sub_2_cidr" {
  description = "the cidr block for the public subnet 2"
  type = string
  default = "10.1.2.0/24"
}

variable "private_sub_1_cidr" {
  description = "the cidr block for the private subnet 1"
  type = string
  default = "10.1.3.0/24"
}
variable "private_sub_2_cidr" {
  description = "the cidr block for the private subnet 1"
  type = string
  default = "10.1.4.0/24"
}

variable "Eip" {
  description = "the existing elastic IP allocation id need to change"
  type = string
  default = "eipalloc-05d53e6ce9da39924"
}

###############################
#resources:
###############################
######  VPC   #######

resource "aws_vpc" "productionVpc" {
  provider = aws.eu-central-1
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "productionVpc"
  }
}

########### subnets ###########
#Public sub 1
resource "aws_subnet" "production_Public_Subnet_1" {
  depends_on = [ aws_vpc.productionVpc ]
  vpc_id = aws_vpc.productionVpc.id
  cidr_block = var.public_sub_1_cidr
  availability_zone = "eu-central-1a"
  tags = {
      Name = "production_Public_Subnet_1"
  }
}

#Public sub 2
resource "aws_subnet" "production_Public_Subnet_2" {
  vpc_id = aws_vpc.productionVpc.id
  depends_on = [ aws_vpc.productionVpc ]
  cidr_block = var.public_sub_2_cidr
  availability_zone = "eu-central-1b"
  tags = {
      Name = "production_Public_Subnet_2"
  }
}

#Private sub 1
resource "aws_subnet" "production_Private_Subnet_1" {
  vpc_id = aws_vpc.productionVpc.id
  depends_on = [ aws_vpc.productionVpc ]
  cidr_block = var.private_sub_1_cidr
  availability_zone = "eu-central-1a"
  tags = {
      Name = "production_Private_Subnet_1"
  }
}

#Private sub 2
resource "aws_subnet" "production_Private_Subnet_2" {
  vpc_id = aws_vpc.productionVpc.id
  depends_on = [ aws_vpc.productionVpc ]
  cidr_block = var.private_sub_2_cidr
  availability_zone = "eu-central-1b"
  tags = {
      Name = "production_Private_Subnet_2"
  }
}

########################################################################################################
#######
#Internt Gateway & route table
#######
# IGW
resource "aws_internet_gateway" "production_IGW" {
    vpc_id = aws_vpc.productionVpc.id

    tags = {
      Name = "production_IGW"
    }
}
# public route table
resource "aws_route_table" "production_public_RT" {
  vpc_id = aws_vpc.productionVpc.id
  tags = {
    Name = "production_Public_RT"
  }
# route
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.production_IGW.id
  }
}
# associations
resource "aws_route_table_association" "production_Public_Subnet_1" {
    subnet_id = aws_subnet.production_Public_Subnet_1.id
    route_table_id = aws_route_table.production_public_RT.id
}
resource "aws_route_table_association" "production_Public_Subnet_2" {
    subnet_id = aws_subnet.production_Public_Subnet_2.id
    route_table_id = aws_route_table.production_public_RT.id
}

##########################################################################################################
###########
########### Eip & Nat Gatway
###########
# Eip
# resource "aws_eip" "production_eip" {
#   domain = "vpc"
#   depends_on = [ aws_internet_gateway.production_IGW ]
#   tags = {
#     Name = "production_eip"
#   }
# }


# # production Nat Gateway
# resource "aws_nat_gateway" "production_NGW" {
#   allocation_id = aws_eip.production_eip.id
#   subnet_id = aws_subnet.production_Public_Subnet_1.id
#   tags = {
#     "Name" = "production_NGW"
#   }
#     depends_on = [ aws_internet_gateway.production_IGW ]
# }

# # route table
# resource "aws_route_table" "production_private_RT" {
#   vpc_id = aws_vpc.productionVpc.id
#   tags = {
#     "Name" = "production_private_RT"
#   }
#   route {
#       cidr_block = "0.0.0.0/0"
#       gateway_id = aws_nat_gateway.production_NGW.id
#   }
# }
# # association
# resource "aws_route_table_association" "production_Private_RT_A1" {
#     subnet_id = aws_subnet.production_Private_Subnet_1.id
#     route_table_id = aws_route_table.production_private_RT.id
# }
# resource "aws_route_table_association" "production_Private_RT_A2" {
#     subnet_id = aws_subnet.production_Private_Subnet_2.id
#     route_table_id = aws_route_table.production_private_RT.id
# }

#########################################################################################################
###################
# security groups
###############
resource "aws_security_group" "production_Sg" {
  name = "production_Sg"
  description = "production securityGroup"
  vpc_id = aws_vpc.productionVpc.id

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }
  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }
  ingress {
    description = "SHH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
    description = "Custom TCP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
    description = "Custom TCP"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "production_Sg"
  }
}


#############
# Ec2s
###########
resource "aws_instance" "production" {
  depends_on = [ aws_security_group.production_Sg ]
  ami = var.production_ami_id
  key_name = var.kaypair
  instance_type = var.ec2_type
  subnet_id = aws_subnet.production_Public_Subnet_1.id
  vpc_security_group_ids =  [aws_security_group.production_Sg.id]
  disable_api_termination = true
  associate_public_ip_address = false

  tags = {
    "Name" = "PH production" 
  }
}

# resource "aws_eip_association" "eip_EC2_a" {
#   allocation_id = var.Eip
#   instance_id = aws_instance.production.id
# }















##################################################################################################################################################
################################
# outputs
################################
output "production_Vpc_id" {
  value = aws_vpc.productionVpc.id
}

# output "production_eip_IP" {
#   value = aws_eip.production_eip.public_ip
# }

output "production_ec2_id" {
  value = aws_instance.production.id
}
