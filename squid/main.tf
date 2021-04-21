provider "aws" {
  region     = var.region
  access_key = var.access_key 
  secret_key = var.secret_key 
}

resource "aws_vpc" "tf_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tf-vpc"
  }
}

resource "aws_subnet" "tf_public_subnet" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_network_interface" "public" {
  subnet_id         = aws_subnet.tf_public_subnet.id
  security_groups   = [aws_security_group.openall.id]
}

resource "aws_subnet" "tf_internal_subnet" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_network_interface" "internal_proxy" {
  subnet_id         = aws_subnet.tf_internal_subnet.id
  security_groups   = [aws_security_group.openall.id]
}

resource "aws_network_interface" "internal_custom" {
  subnet_id         = aws_subnet.tf_internal_subnet.id
  security_groups   = [aws_security_group.openall.id]
}

resource "aws_instance" "squid_proxy" {
  ami                         = "ami-0ef85cf6e604e5650"
  instance_type               = "t2.micro"
  #vpc_security_group_ids      = [aws_security_group.openall.id]
  key_name                    = aws_key_pair.auth.id
  #subnet_id                   = aws_subnet.tf_subnet.id
  #subnet_id                   = each.value

  tags = {
    Name = "squid_proxy"
  }

  network_interface {
    network_interface_id = aws_network_interface.public.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.internal_proxy.id
    device_index         = 1
  }

##   provisioner "remote-exec" {
##     inline = [
##       "sudo apt update",
##       "sudo apt install squid -y && sudo sed -i -r 's/^http_access deny all/http_access allow all/' /etc/squid/squid.conf",
##       "sudo systemctl start squid",
##     ]
##   }
## 
##   provisioner "file" {
##     source      = var.private_key_path
##     destination = "~/.ssh/id_rsa"
##   }
## 
##   connection {
##     type        = "ssh"
##     user        = "ubuntu"
##     password    = ""
##     private_key = file(var.private_key_path)
##     host        = self.public_ip
##   }
}

resource "aws_instance" "custom_node" {
  ami                         = "ami-0ef85cf6e604e5650"
  instance_type               = "t2.large"
  #vpc_security_group_ids      = [aws_security_group.openall.id]
  key_name                    = aws_key_pair.auth.id
  #subnet_id                   = aws_subnet.tf_internal_subnet.id

  tags = {
    Name = "custom_node"
  }

  ## provisioner "remote-exec" {
  ##   inline = [
  ##     "sudo apt update && sudo apt install docker.io -y"
  ##   ]
  ## }

  ## connection {
  ##   type        = "ssh"
  ##   user        = "ubuntu"
  ##   password    = ""
  ##   private_key = file(var.private_key_path)
  ##   host        = self.public_ip
  ## }

  network_interface {
    network_interface_id = aws_network_interface.internal_custom.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 20
  }
}

#output "squid_public_dns" {
  #value = aws_instance.squid_proxy.public_ip
#  value = aws_instance.squid_proxy.public_ip
#}

output "custom_node_private_ip" {
  value = aws_instance.custom_node.private_ip
}

resource "aws_security_group" "openall" {
  name           = "OpenAll"
  vpc_id         = aws_vpc.tf_vpc.id

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
