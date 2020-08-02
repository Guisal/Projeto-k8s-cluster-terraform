
provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "$HOME/.aws/credentials"
  profile                 = "default"
}

data "http" "external-ip" {
  url = "http://icanhazip.com"
}

resource "aws_default_vpc" "main" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_subnet_ids" "default_subnets" {
    vpc_id = aws_default_vpc.main.id
}

resource "aws_security_group" "sggiropops" {
  name        = "giropops"
  description = "SG giropops"
  vpc_id      = aws_default_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block, "${chomp(data.http.external-ip.body)}/32"]
  }
  ingress {
    description = "etcd server API"
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  }

  ingress {
    description = "kube-apiserver"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  }

  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  }  

  ingress {
    description = "kube-scheduler"
    from_port   = 10251
    to_port     = 10251
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  }  

  ingress {
    description = "kube-controller-manager"
    from_port   = 10252
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  }  

  ingress {
    description = "kube-controller-manager"
    from_port   = 10255
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  }  

 ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  }  

 ingress {
    description = "Acesso metricas exportadas prometheus"
    from_port   = 32111
    to_port     = 32111
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  } 
 
 ingress {
    description = "Acesso a app"
    from_port   = 32222
    to_port     = 32222
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  } 

 ingress {
    description = "WeaveNet"
    from_port   = 6783
    to_port     = 6783
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  }   

 ingress {
    description = "Weavenet"
    from_port   = 6783
    to_port     = 6783
    protocol    = "udp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  } 
 ingress {
    description = "Weavenet"
    from_port   = 6784
    to_port     = 6784
    protocol    = "udp"
    cidr_blocks = [aws_default_vpc.main.cidr_block]
  } 

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "giropops"
  }
}  

resource "aws_instance" "server" {
  count = 3
  #for_each = data.aws_subnet_ids.default_subnets.ids
  subnet_id =  flatten( data.aws_subnet_ids.default_subnets.ids)[count.index]
  ami = "ami-085925f297f89fce1"
  associate_public_ip_address = true
  instance_type = "t2.medium"
  #instance_type = "t2.micro"
  #subnet_id = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.sggiropops.id]
  key_name      = "ansible-virginia-key2"
  tags = {
    Name = "ansible-${count.index}"
  }
}

resource "local_file" "k8s-config"{
  content = <<EOF
[k8s-master]
${aws_instance.server.0.public_ip}

[k8s-workers]
%{ for ip in range(1, length(aws_instance.server))  ~}
${aws_instance.server[ip].public_ip}
%{ endfor ~}

[k8s-workers:vars]
K8S_MASTER_NODE_IP= ${aws_instance.server.0.private_ip}
K8S_API_SECURE_PORT=6443
EOF
  filename = "../install_k8s/hosts"
}

#data "template_file" "set-k8s-config"{
#  template = fileexists("k8s-config") ? file("k8s-config") : local.default_content
#  vars = {
#    aws_instance.example.*.private_ip
#  }
#}
#fazer o mesmo passar para os outros do ansible 