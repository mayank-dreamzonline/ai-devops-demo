output "db_instance_id" {
  value = aws_db_instance.main.id
}

output "db_instance_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "cloudwatch_alarm_name" {
  value = aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
