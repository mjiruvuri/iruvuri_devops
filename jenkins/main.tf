data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "jenkins" {
  name        = "jenkins-sg"
  description = "Jenkins EC2 security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ebs_volume" "jenkins_data" {
  availability_zone = var.jenkins_data_volume_az
  size              = var.jenkins_data_volume_size_gb
  type              = "gp3"

  tags = {
    Name = "jenkins-data"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "jenkins_data" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.jenkins_data.id
  instance_id  = aws_instance.jenkins.id
  force_detach = true
}

resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name
  key_name               = var.key_name

  root_block_device {
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data                   = file("${path.module}/userdata.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "jenkins"
  }
}
