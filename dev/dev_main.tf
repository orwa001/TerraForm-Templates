## dev_main.tf

provider "aws" {
  alias = "eu-central-1"  
  region = "eu-central-1"
}

#####################################################
# variables

variable "dev_ami_id" {
  description = "AMI ID for the dev EC2 instance need to change"
  type        = string
  default     = "ami-09024b009ae9e7adf"
}

variable "kaypair" {
  description = "the kay pair for SSH need to change"
  type = string
  default = "example"  
}
variable "vpc_cidr" {
  description = "the cidr block for the dev VPC"
  type = string
  default = "10.2.0.0/16"
}
variable "public_sub_1_cidr" {
  description = "the cidr block for the public subnet 1"
  type = string
  default = "10.2.1.0/24"
}
variable "public_sub_2_cidr" {
  description = "the cidr block for the public subnet 2"
  type = string
  default = "10.2.2.0/24"
}

variable "private_sub_1_cidr" {
  description = "the cidr block for the private subnet 1"
  type = string
  default = "10.2.3.0/24"
}
variable "private_sub_2_cidr" {
  description = "the cidr block for the private subnet 1"
  type = string
  default = "10.2.4.0/24"
}

variable "Eip" {
  description = "the existing elastic IP allocation id need to change"
  type = string
  default = "eipalloc-08f5dac6963c399dc"
}



###############################
#resources:
###############################
######  VPC   #######

resource "aws_vpc" "devVpc" {
  provider = aws.eu-central-1
  cidr_block = "10.2.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "devVpc"
  }
}

##########################################################################################################
######  dev Subnets   #######
#Public sub 1
resource "aws_subnet" "dev_Public_Subnet_1" {
  depends_on = [ aws_vpc.devVpc ]
  vpc_id = aws_vpc.devVpc.id
  cidr_block = "10.2.1.0/24"
  availability_zone = "eu-central-1a"
  tags = {
      Name = "dev_Public_Subnet_1"
  }
}

#Public sub 2
resource "aws_subnet" "dev_Public_Subnet_2" {
  vpc_id = aws_vpc.devVpc.id
  depends_on = [ aws_vpc.devVpc ]
  cidr_block = "10.2.2.0/24"
  availability_zone = "eu-central-1b"
  tags = {
      Name = "dev_Public_Subnet_2"
  }
}

#Private sub 1
resource "aws_subnet" "dev_Private_Subnet_1" {
  vpc_id = aws_vpc.devVpc.id
  depends_on = [ aws_vpc.devVpc ]
  cidr_block = "10.2.3.0/24"
  availability_zone = "eu-central-1a"
  tags = {
      Name = "dev_Private_Subnet_1"
  }
}

#Private sub 2
resource "aws_subnet" "dev_Private_Subnet_2" {
  vpc_id = aws_vpc.devVpc.id
  depends_on = [ aws_vpc.devVpc ]
  cidr_block = "10.2.4.0/24"
  availability_zone = "eu-central-1b"
  tags = {
      Name = "dev_Private_Subnet_2"
  }
}

########################################################################################################
#######
#Internt Gateway 
#######

# IGW
resource "aws_internet_gateway" "dev_IGW" {
  vpc_id = aws_vpc.devVpc.id
  tags = {
    Name = "dev_IGW"
  }
}

# public route table
resource "aws_route_table" "dev_public_RT" {
  vpc_id = aws_vpc.devVpc.id
  tags = {
    Name = "dev_Public_RT"
  }
# route
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_IGW.id
  }
}
# associations
resource "aws_route_table_association" "dev_Public_Subnet_1" {
    subnet_id = aws_subnet.dev_Public_Subnet_1.id
    route_table_id = aws_route_table.dev_public_RT.id
}
resource "aws_route_table_association" "dev_Public_Subnet_2" {
    subnet_id = aws_subnet.dev_Public_Subnet_2.id
    route_table_id = aws_route_table.dev_public_RT.id
}

##########################################################################################################
###########
########### Eip & Nat Gatway
###########
# Eip
# resource "aws_eip" "dev_eip" {
#   domain = "vpc"
#   depends_on = [ aws_internet_gateway.dev_IGW ]
#   tags = {
#     Name = "dev_eip"
#   }
# }

# # Nat Gateway
# resource "aws_nat_gateway" "dev_NGW" {
#   allocation_id = aws_eip.dev_eip.id
#   subnet_id = aws_subnet.dev_Public_Subnet_1.id
#   tags = {
#     "Name" = "dev_NGW"
#   }
#     depends_on = [ aws_internet_gateway.dev_IGW ]
# }

# # route table
# resource "aws_route_table" "dev_private_RT" {
#   vpc_id = aws_vpc.devVpc.id
#   tags = {
#     "Name" = "dev_private_RT"
#   }
#   route {
#       cidr_block = "0.0.0.0/0"
#       gateway_id = aws_nat_gateway.dev_NGW.id
#   }
# }
# # association
# resource "aws_route_table_association" "dev_Private_RT_A1" {
#     subnet_id = aws_subnet.dev_Private_Subnet_1.id
#     route_table_id = aws_route_table.dev_private_RT.id
# }
# resource "aws_route_table_association" "dev_Private_RT_A2" {
#     subnet_id = aws_subnet.dev_Private_Subnet_2.id
#     route_table_id = aws_route_table.dev_private_RT.id
# }

#########################################################################################################
###################
# security groups
###############
resource "aws_security_group" "dev_Sg" {
  name = "dev_Sg"
  description = "dev securityGroup"
  vpc_id = aws_vpc.devVpc.id

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
    "Name" = "dev_Sg"
  }
}


#############
# Ec2s
###########
resource "aws_instance" "dev" {
  depends_on = [ aws_security_group.dev_Sg ]
  ami = var.dev_ami_id
  key_name = var.kaypair
  instance_type = "t2.micro"
  subnet_id = aws_subnet.dev_Public_Subnet_1.id
  vpc_security_group_ids =  [aws_security_group.dev_Sg.id]

  associate_public_ip_address = true

  tags = {
    "Name" = "PH dev" 
  }
}

# resource "aws_eip_association" "eip_EC2_a" {
#   allocation_id = var.Eip
#   instance_id = aws_instance.dev.id
# }













##################################################################################################################################################
################################
# outputs
################################
output "dev_Vpc_id" {
  value = aws_vpc.devVpc.id
}

# output "dev_eip_IP" {
#   value = aws_eip.dev_eip.public_ip
# }

output "dev_ec2_id" {
  value = aws_instance.dev.id
}

output "dev_ec2_public_ip" {
  value = aws_instance.dev.public_ip
  # should be empty
}