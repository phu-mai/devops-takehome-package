provider "cloudflare" {
  # Validate-only: no live credentials required for terraform validate.
  # For apply, set CLOUDFLARE_API_TOKEN (never commit tokens).
  api_token = var.cloudflare_api_token
}
