# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create SSH key pair named "1PU"
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "1PU"  # This creates the key named "1PU"
  public_key = tls_private_key.jenkins_key.public_key_openssh

  tags = {
    Name        = "${var.project_name}-jenkins-key"
    Environment = var.environment
  }
}

# Jenkins Master EC2 Instance
resource "aws_instance" "jenkins_master" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.jenkins_key.key_name  # References "1PU"

  vpc_security_group_ids = [aws_security_group.jenkins.id]
  subnet_id              = aws_subnet.public[0].id

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "Jenkins Master"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Elastic IP for Jenkins Master
resource "aws_eip" "jenkins_master" {
  instance = aws_instance.jenkins_master.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-jenkins-master-eip"
    Environment = var.environment
  }
}

# Output the private key so you can SSH
output "jenkins_private_key" {
  description = "Private key for Jenkins server"
  value       = tls_private_key.jenkins_key.private_key_pem
  sensitive   = true
}

output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = aws_eip.jenkins_master.public_ip
}