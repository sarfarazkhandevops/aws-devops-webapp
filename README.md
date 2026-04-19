# 🚀 Infrastructure & CI/CD Setup

This project demonstrates a complete Infrastructure as Code (IaC), CI/CD pipeline, and monitoring setup on AWS.

---

## 📌 Overview

The infrastructure is designed using Terraform and follows best practices:

- Private application deployment
- Secure access via SSM (no SSH)
- Auto Scaling & Load Balancing
- CI/CD with GitHub Actions
- Monitoring with CloudWatch
- ECR for storing docker images


---

# 🧱 PART 1: INFRASTRUCTURE AS CODE (IaC)

## 🔧 Tools Used
- Terraform
- AWS (VPC, EC2, ALB, ASG, IAM, SSM, ECR)

## 🏗️ Infrastructure Details

- Created a **VPC** with:
  - Public Subnet
  - Private Subnet

- EC2 Instances:
  - Application runs in **Private Subnet**
  - Access via **SSM Session Manager (No SSH)**

- Configured:
  - Application Load Balancer (ALB)
  - Auto Scaling Group:
    - Min: 1
    - Max: 2

- Security:
  - IAM Roles
  - Security Groups

-ECR:
  - To store the docker images 

---

## ▶️ How to Run Terraform

### 1. Configure AWS CLI

```bash
aws configure --profile <your-profile-name>
```

Provide:
- Access Key
- Secret Access Key
- Region (e.g. `us-east-1`)

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan

```bash
terraform plan
```

### 4. Apply

```bash
terraform apply
```

---

## ⚠️ Important Notes

- Remote state is configured using **S3 + DynamoDB locking**
- You must **manually create** the following in your AWS account **before running Terraform**:
  - S3 bucket for Terraform state
  - DynamoDB table for state locking
- Ensure the **region matches** the Terraform code. Example: `us-east-1`

---

# 🔁 PART 2: CI/CD PIPELINE

## ⚙️ Tools Used
- GitHub Actions (Self-hosted Runner)

## 🔄 Workflow

- **Trigger:** Push to `main` branch
- **Steps:**
  1. Build application (Node.js)
  2. Deploy to EC2 instances

## 🚨 Important Setup

- Application runs in **Private Subnet**
- Using a **Self-hosted GitHub Actions Runner**

### Steps to Configure Runner:

- To setup runner follow this [docs](https://medium.com/@yonatan.kr/how-to-use-github-actions-self-hosted-runners-1508873db68c)

## 🎯 Goal

- Fully automated deployment pipeline on `git push` to `main`

---

# 📊 PART 3: MONITORING

## 🔍 Services Used
- CloudWatch Logs
- CloudWatch Alarms


## 📈 Monitoring Setup

- EC2 logs pushed to **CloudWatch**
- Metrics tracked:
  - CPU Usage
  - Memory Usage
  - Disk Usage
- Alerts configured via **CloudWatch Alarms**
- Optional email alerts using **SNS**

## ⚙️ Installation

- CloudWatch Agent installed via **User Data script**
- Fully automated during EC2 launch
- To Setup cloud watch alarm please check "Setup cloudwatch alarm" docs  [Download PDF](https://docs.google.com/document/d/1N-wS--8iVZJT_JnvLByRCYY2szXnkxjlbrKXjVaV0T4/edit?usp=sharing)


---

# 📦 DELIVERABLES

This repository contains:

| Item | Status |
|------|--------|
| Terraform code (`terraform/`) | DONE
| Application code ( webapp/ ) | DONE
| CI/CD configuration (GitHub Actions) | Done
| Monitoring setup (AWS CloudWatch Docs) | DONE
| README documentation | DONE

---

# 🔐 Security Best Practices

- ❌ No SSH access — **SSM Session Manager only**
- ✅ IAM roles used instead of hardcoded credentials
- ✅ Application layer deployed in **Private Subnet**

---

# 🎉 Conclusion

A complete cloud setup that brings together infrastructure, deployment automation, and monitoring into a single, efficient system.
