# -----------------------------
# 1. VPC MODULE
# -----------------------------
module "vpc" {
  source = "./modules/vpc"

  vpc_name            = var.vpc_name
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs
  public_subnet_cidr  = var.public_subnets
  private_subnet_cidr = var.private_subnets

  common_tags = {
    Project = "demo-app"
    Env     = "dev"
  }
}

# -----------------------------
# 2. IAM SSM MODULE
# -----------------------------
module "iam" {
  source = "./modules/iam"

  role_name             = "ec2-ssm-role"
  instance_profile_name = "ec2-ssm-profile"
  attach_cloudwatch     = true

  tags = {
    Project = "demo-app"
  }
}

# -----------------------------
# 3. SECURITY GROUPS (INLINE SIMPLE)
# -----------------------------
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# 4. ALB MODULE
# -----------------------------
module "alb" {
  source = "./modules/alb"

  alb_name           = "app-alb"
  tg_name            = "app-tg"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_sg_id          = aws_security_group.alb_sg.id
  target_port        = 80

  tags = {
    Project = "demo-app"
  }
}

# -----------------------------
# 5. ASG MODULE (PRIVATE SUBNET)
# -----------------------------
module "asg" {
  source = "./modules/asg"

  asg_name        = "app-asg"
  lt_name         = "app-lt"
  ami_id          = var.ami_id
  instance_type   = var.instance_type

  instance_profile_name = module.iam.instance_profile_name
  instance_sg_id        = aws_security_group.app_sg.id

  private_subnet_ids = module.vpc.private_subnet_ids
  target_group_arn   = module.alb.target_group_arn

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  user_data = <<EOF
!/bin/bash
user_data = <<EOF
#!/bin/bash
set -e

echo "Updating system packages..."
apt update -y
apt upgrade -y

echo "Installing dependencies..."
apt install -y ca-certificates curl gnupg lsb-release git wget unzip

#################### DOCKER SETUP ####################

echo "Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo "Adding Docker repo..."
echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" > /etc/apt/sources.list.d/docker.list

apt update -y

echo "Installing Docker..."
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu

#################### APP DEPLOY ####################

echo "Cloning repo..."

apt install git -y
cd /home/ubuntu
git clone https://github.com/sarfarazkhandevops/aws-devops-webapp.git

cd aws-devops-webapp

echo "Building Docker image..."
docker build -t webapp .

echo "Running container..."
docker run -d -p 80:3000 webapp

#################### CLOUDWATCH ####################

echo "Installing CloudWatch Agent..."

wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

dpkg -i amazon-cloudwatch-agent.deb || apt-get install -f -y

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat <<EOT > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "\$${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "/"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOT

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent

#################### COLLECTD ####################

apt install -y collectd

echo "Deployment completed successfully!"
EOF

  tags = {
    Project = "demo-app"
  }
}


provider "aws" {
  region = var.region
}

module "ecr" {
  source = "./modules/ecr"

  repository_name      = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  scan_on_push         = var.scan_on_push
  encryption_type      = var.encryption_type

  enable_lifecycle_policy = true

  lifecycle_policy = {
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  }

  tags = {
    Environment = "dev"
    Project     = "ecr-demo"
  }
}


