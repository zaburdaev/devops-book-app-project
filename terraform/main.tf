terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${path.module}/deployer.pub")
}
provider "aws" {
  region = "eu-central-1" # Франкфурт
}

# Группа безопасности (открываем порты)
resource "aws_security_group" "books_sg" {
  name        = "books-app-sg-vitaliy"
  description = "Allow SSH and Web traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Создаем сервер EC2
resource "aws_instance" "books_server" {
  ami           = "ami-0084a47cc718c111a" # Ubuntu 22.04 LTS
  instance_type = "t3.small"             #t3.small
  key_name      = aws_key_pair.deployer.key_name 

  vpc_security_group_ids = [aws_security_group.books_sg.id]

  tags = {
    Name = "BooksAppServer"
  }
}

# Выводим IP сервера
output "instance_public_ip" {
  value = aws_instance.books_server.public_ip
}
