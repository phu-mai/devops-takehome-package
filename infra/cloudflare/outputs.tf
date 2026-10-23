output "quote_api_hostname" {
  description = "Proxied hostname"
  value       = "quote-api.example.com"
}

output "quote_api_record_id" {
  description = "Cloudflare record id (after apply)"
  value       = cloudflare_record.quote_api.id
}
