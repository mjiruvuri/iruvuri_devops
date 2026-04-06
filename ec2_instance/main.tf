# Get latest Amazon Linux 2 AMI
data "aws_ami" "rocky_latest" {
  most_recent = true
  owners      = ["451249155200"] # Official Rocky Linux AWS account

  filter {
    name   = "name"
    values = ["Rocky-9-*-x86_64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
# Security group for SSH (port 22)
resource "aws_security_group" "ec2_sg" {
  name        = "terraform-ec2-sg"
  description = "Security group for EC2 instances created by Terraform"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-ec2-sg"
  }
}

# EC2 instances
resource "aws_instance" "rke_nodes" {
  count                       = var.instance_count
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "terraform-ec2-${count.index}"
    Project = "home-lab"
  }
}
