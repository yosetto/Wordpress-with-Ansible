provider "aws" {
   access_key = var.aws_access_key
   secret_key = var.aws_secret_key
   token = var.aws_api_token
   region = var.aws_region
   skip_credentials_validation = true
}

resource "aws_security_group" "allow_ports" {
   name        = "allow_ssh_http"
   description = "Allow inbound SSH traffic and http from any IP"
   vpc_id      = "${module.vpc.vpc_id}"

   #ssh access for remote-exec provisioner
   ingress {
       from_port   = 22
       to_port     = 22
       protocol    = "tcp"
       # Restrict ingress to necessary IPs/ports.
       cidr_blocks = ["0.0.0.0/0"]
   }

   # HTTP access for apache2 which hosts wordpress
   ingress {
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       # Restrict ingress to necessary IPs/ports.
       cidr_blocks = ["0.0.0.0/0"]
   }

   egress {
       from_port   = 0
       to_port     = 0
       protocol    = "-1"
       cidr_blocks = ["0.0.0.0/0"]
   }
}

resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.generated_key_name
  public_key = tls_private_key.dev_key.public_key_openssh

  provisioner "local-exec" {    # Generate "terraform-key-pair.pem"
    command = "echo '${tls_private_key.dev_key.private_key_pem}' > ./'${var.generated_key_name}'.pem"
  }

  provisioner "local-exec" {
    command = "chmod 400 ./'${var.generated_key_name}'.pem"
  }
}


resource "aws_instance" "wordpress" {
   instance_type          = "${var.instance_type}"
   ami                    = "${lookup(var.aws_amis, var.aws_region)}"
   count                  = "${var.instance_count}"
   key_name               = aws_key_pair.generated_key.key_name
   vpc_security_group_ids = ["${aws_security_group.allow_ports.id}"]
   subnet_id              = "${element(module.vpc.public_subnets,count.index)}"
   
   provisioner "local-exec" {
     command = "echo ${self.public_ip} ansible_user=${var.ssh_user} > '../ansible/hosts'"
   }

  provisioner "local-exec" {
    command = "ansible-playbook -i ../ansible/hosts --user ${var.ssh_user} --private-key ./${var.generated_key_name}.pem ../ansible/playbook.yml"
  }
}
