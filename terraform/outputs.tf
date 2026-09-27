output "web_public_ips" {
  description = "Public IPs of web servers (consumed by Jenkins to build the Ansible inventory)"
  value       = aws_instance.web[*].public_ip
}

output "web_urls" {
  description = "URLs to open in your browser"
  value       = [for ip in aws_instance.web[*].public_ip : "http://${ip}"]
}

output "vpc_id" {
  value = aws_vpc.main.id
}
