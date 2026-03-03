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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCvlQAaODAFUihRcSxb5Ej9RNetIA9n4cj6FU2Ub6/goKt78xNAV//3G/ZinA1SPv3JdVh027oKrWA8+r8KVacgP4RHmy21OSE7QWCLmaUxguGhE55XFBU5MsflS6/Gs4Qh6ww08esOo71ox/fUicGebFfuCo33G6xMPwFicHIsGBoK1vKUMHrNc+nNHhl0PdGQ9eJHGWVm7Odg0nDUXLedtvBDuN3bQdGeUuzKCG7UZjWJeXNMiCMMvk14/6mFg8NUVCTGJykHAWkqiBY/qByj8/lE6C0K5+313YViJ0TWpMKIH6PSAkTorDxvR38EQAmLiSRaXhQUJqQne7xw37icyKtRSuhxIxcLBHHtjRZ3OBuRSwLY+la5vtVjYeyf4kC4BK/g6uq6YdsaN9v+HmdpPjNxMc1cPx4UV2ufBaNRgcjykEJ0YD04RgQ7e3/KrKNfQ4Yc7KvE2ZEVatRVOtCmN+CpydYYOoi7F4yi74PzXCrpJZFTTrGwR5MtyRfqG++Bul4Kmp/8OWHqJd5AMInROXomnxWmNxwsyOYYIh+dfMQzJQ+rO8i4IMXTp3mO/fsY3Qrad75d+3YLUfHJS84AtJMYTxUDTB8HVNwAKzpNDviuhi7mA4Uf7Se5/OXnjuUw+bK76C+puxCZDlYHlaf8sk10xIVzVHO65S1p+QkjvQ== vitaliyzaburdaev@MacBook-Air-Vitaliy-6.local
"
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