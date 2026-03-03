terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "vitaliy-terraform-state-books-app"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1" # Франкфурт
}

# Используем уже существующий key pair (не создаём заново)
data "aws_key_pair" "deployer" {
  key_name = "deployer-key"
}

# Используем уже существующую security group (не создаём заново)
data "aws_security_group" "books_sg" {
  id = "sg-0b2d5e7e09fb0ad38"
}

# Создаем сервер EC2
resource "aws_instance" "books_server" {
  ami           = "ami-0084a47cc718c111a" # Ubuntu 22.04 LTS
  instance_type = "t3.small"
  key_name      = data.aws_key_pair.deployer.key_name

  vpc_security_group_ids = [data.aws_security_group.books_sg.id]

  tags = {
    Name  = "BooksAppServer"
    Owner = "vitaliy"
  }
}

# Выводим IP сервера
output "instance_public_ip" {
  value = aws_instance.books_server.public_ip
}