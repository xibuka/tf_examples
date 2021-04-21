provider "aws" {
  region     = var.region
  access_key = var.access_key 
  secret_key = var.secret_key 
}

## resource "aws_vpc" "tf_vpc" {
##   cidr_block = "10.0.0.0/16"
## 
##   tags = {
##     Name = "tf-vpc"
##   }
## }
## 
## resource "aws_subnet" "tf_subnet" {
##   vpc_id            = aws_vpc.tf_vpc.id
##   cidr_block        = "10.0.0.0/24"
##   availability_zone = "ap-northeast-1a"
##   map_public_ip_on_launch = true
## }

resource "aws_instance" "squid_proxy" {
  ami                         = "ami-0ef85cf6e604e5650"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.openall.id]
  key_name                    = aws_key_pair.auth.id
##  subnet_id                   = aws_subnet.tf_subnet.id

  tags = {
    Name = "squid_proxy"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install squid -y && sudo sed -i -r 's/^http_access deny all/http_access allow all/' /etc/squid/squid.conf",
      "sudo systemctl start squid",
    ]
  }
 
  connection {
    type        = "ssh"
    user        = "ubuntu"
    password    = ""
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }
}

output "squid_public_dns" {
  value = aws_instance.squid_proxy.public_ip
  #value = aws_instance.squid_proxy.public_dns
}

resource "aws_security_group" "openall" {
  name           = "OpenAll"
  #vpc_id         = aws_vpc.tf_vpc.id

  ingress {
    from_port    = 0
    to_port      = 0 
    protocol     = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    from_port    = 0
    to_port      = 0 
    protocol     = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "auth" {
  public_key = file(var.public_key_path)
}
