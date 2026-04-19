output "instance_profile_name" {
  value = aws_iam_instance_profile.ssm_profile.name
}

output "instance_profile_arn" {
  value = aws_iam_instance_profile.ssm_profile.arn
}

output "role_name" {
  value = aws_iam_role.ssm_role.name
}