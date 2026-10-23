variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token (placeholder for validate-only)"
  default     = "placeholder-not-a-real-token"
  sensitive   = true
}

variable "zone_id" {
  type        = string
  description = "Cloudflare zone ID for example.com"
  default     = "00000000000000000000000000000000"
}

variable "account_id" {
  type        = string
  description = "Cloudflare account ID"
  default     = "00000000000000000000000000000000"
}

variable "origin_ip" {
  type        = string
  description = "Origin IP for quote-api (placeholder)"
  default     = "203.0.113.10"
}
