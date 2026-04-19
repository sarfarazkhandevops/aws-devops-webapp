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
user_data = <<EOF
#!/bin/bash
set -ex

# Log everything
exec > /var/log/user-data.log 2>&1

echo "Starting user-data script..."

#################### WAIT ####################
sleep 30

#################### SYSTEM UPDATE ####################
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

#################### INSTALL DEPENDENCIES ####################
echo "Installing dependencies..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release git wget unzip

#################### DOCKER SETUP ####################
echo "Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "Adding Docker repo..."
echo "deb [arch=\\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

# Wait for Docker
sleep 15

sudo usermod -aG docker ubuntu

#################### APP DEPLOY ####################
echo "Cloning repo..."
cd /home/ubuntu

if [ ! -d "aws-devops-webapp" ]; then
  sudo git clone https://github.com/sarfarazkhandevops/aws-devops-webapp.git
fi

cd aws-devops-webapp/webapp

echo "Building Docker image..."
sudo docker build -t webapp .

echo "Running container..."
sudo docker run -d -p 80:3000 --restart=always webapp || true

#################### CLOUDWATCH ####################
echo "Installing CloudWatch Agent..."

sudo wget -P /tmp https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb || sudo apt-get install -f -y

sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat <<EOT | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "\\$${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["/"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOT

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \\
  -a fetch-config \\
  -m ec2 \\
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \\
  -s

sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl restart amazon-cloudwatch-agent

#################### COLLECTD ####################
echo "Installing collectd..."
sudo apt-get install -y collectd

echo "✅ Deployment completed successfully!"
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



