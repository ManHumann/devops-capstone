provider "aws" {
  region  = "ap-south-1"
  profile = "isak"
}

#Creating VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id

}

#Creating Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

module "jenkins_security_group" {
  source = "./modules/security_groups"

  name        = "jenkins-sg"
  description = "SG for jenkins EC2"
  vpc_id      = aws_vpc.main.id

  ingress_rules = {
    ssh = {
      description = "SSH from admin"
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }

    jenkins_ui = {
      description = "Jenkins web UI"
      from_port   = 8080
      to_port     = 8080
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  egress_rules = {
    ssh = {
      description = "SSH out of jenkins to deployment server"
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.1.8/32" #deployment_server private ip
    }

    promtail = {
      description = "Logs sending to loki"
      from_port   = 3100
      to_port     = 3100
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.1.10/32" #monitoring_server private ip
    }

    internet = {
      description = "internet access"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0" #Internet access
    }

  }

}

module "deployment_security_group" {
  source = "./modules/security_groups"

  name        = "deployment-sg"
  description = "SG for Deployment EC2"
  vpc_id      = aws_vpc.main.id

  ingress_rules = {
    jenkins_ssh_into = {
      description                  = "SSH from Jenkins server"
      from_port                    = 22
      to_port                      = 22
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.jenkins_security_group.security_group_id
    }

    app_ui = {
      description = "Exposing nginX port to internet"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    
    admin_ssh = {
    description = "SSH from administrator workstation"
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr_ipv4   = "0.0.0.0/0"
  }
  }
  egress_rules = {
    promtail = {
      description = "Logs sending to loki"
      from_port   = 3100
      to_port     = 3100
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.1.10/32" #monitoring_server private ip
    }

    internet = {
      description = "internet access"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0" #Internet access
    }
  }
}


module "monitoring_security_group" {
  source = "./modules/security_groups"

  name        = "monitoring-sg"
  description = "SG for Deployment EC2"
  vpc_id      = aws_vpc.main.id

  ingress_rules = {
    ssh = {
      description = "SSH into server"
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    grafana_ui = {
      description = "Accessing Grafana UI"
      from_port   = 3000
      to_port     = 3000
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }


    logs_from_deployment = {
      description                  = "Logs from deployment server"
      from_port                    = 3100
      to_port                      = 3100
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.deployment_security_group.security_group_id
    }

    logs_from_jenkins = {
      description                  = "Logs from Jenkins server"
      from_port                    = 3100
      to_port                      = 3100
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.jenkins_security_group.security_group_id
    }
  }

  egress_rules = {
    internet = {
      description = "internet access"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0" #Internet access
    }

  }

}

#Creating key_pair for EC2
resource "aws_key_pair" "final-project-key" {
  key_name   = "final-project-key"
  public_key = file(".ssh/my-key.pub")
}

#Creating RSA key pair for jenkins to connect to deployment server
resource "tls_private_key" "jenkins_deploy" {
  algorithm = "ED25519" #creates public_key_openssh and private_key_openssh
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

locals {

  monitoring_ip    = cidrhost(aws_subnet.public.cidr_block, 10) # 10.0.1.10
  static_deploy_ip = cidrhost(aws_subnet.public.cidr_block, 8)  # 10.0.1.8

  instances = {
    jenkins = {
      name = "Jenkins EC2"
      user_data = templatefile("${path.module}/scripts/jenkins.sh",
        {
          monitoring_ip = local.monitoring_ip
        }
      )
      security_groups = [module.jenkins_security_group.security_group_id] #For changing to dedicated later
    }

    deployment = {
      name = "Deployment EC2"
      user_data = templatefile("${path.module}/scripts/deployment.sh",
        {
          compose_file       = file("${path.module}/../../CRUD-Nodejs-PostgreSQL/docker-compose.yml")
          jenkins_public_key = tls_private_key.jenkins_deploy.public_key_openssh
          env_file           = file("${path.module}/../../CRUD-Nodejs-PostgreSQL/.env") #sending env file to run compose file
          init_sql_file      = file("${path.module}/../../CRUD-Nodejs-PostgreSQL/db/init.sql")
          nginx_conf         = file("${path.module}/../../node-app.conf")
          monitoring_ip      = local.monitoring_ip
        }
      )
      security_groups = [module.deployment_security_group.security_group_id] #For changing to dedicated later
    }

    monitoring = {
      name            = "Monitoring EC2"
      user_data       = file("${path.module}/scripts/monitoring.sh")
      security_groups = [module.monitoring_security_group.security_group_id] #For changing to dedicated later
    }
  }
}

resource "aws_instance" "final_project_instances" {
  for_each = local.instances
  ami      = data.aws_ami.ubuntu.id

  instance_type          = "t3.micro"
  key_name               = aws_key_pair.final-project-key.key_name
  vpc_security_group_ids = each.value.security_groups
  subnet_id              = aws_subnet.public.id
  user_data              = each.value.user_data

  # Only monitoring gets a pinned IP; the others get one from DHCP
  private_ip = (
    each.key == "monitoring" ? local.monitoring_ip :
    each.key == "deployment" ? local.static_deploy_ip :
    null
  )

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = each.value.name
  }


}