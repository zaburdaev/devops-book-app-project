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
  region = "eu-central-1"
}

# Создаём и управляем key pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${path.module}/deployer.pub")
}

# ЧИТАЕМ уже существующую SG (НЕ создаём и НЕ удаляем)
data "aws_security_group" "books_sg" {
  id = "sg-0b2d5e7e09fb0ad38"
}

# EC2 сервер, привязанный к существующей SG
resource "aws_instance" "books_server" {
  ami           = "ami-0084a47cc718c111a"
  instance_type = "t3.small"
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [data.aws_security_group.books_sg.id]

  tags = {
    Name  = "BooksAppServer"
    Owner = "vitaliy"
  }
}

output "instance_public_ip" {
  value = aws_instance.books_server.public_ip
}