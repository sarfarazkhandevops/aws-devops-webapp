# IAM Role for EC2 to use SSM
resource "aws_iam_role" "ssm_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# Attach AWS Managed SSM Policy
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Optional (useful for logs/debugging)
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count      = var.attach_cloudwatch ? 1 : 0
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance Profile (THIS IS REQUIRED FOR EC2)
resource "aws_iam_instance_profile" "ssm_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.ssm_role.name
}