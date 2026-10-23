# Proxied DNS for quote-api.example.com
resource "cloudflare_record" "quote_api" {
  zone_id = var.zone_id
  name    = "quote-api"
  content = var.origin_ip
  type    = "A"
  proxied = true
  ttl     = 1 # auto when proxied
  comment = "quote-api origin (managed by Terraform)"
}

# Adopt a pre-existing manually-created record into Terraform state.
# Replace the import ID with the real zone_id/record_id before apply.
import {
  to = cloudflare_record.legacy_www
  id = "${var.zone_id}/00000000000000000000000000000001"
}

resource "cloudflare_record" "legacy_www" {
  zone_id = var.zone_id
  name    = "www"
  content = var.origin_ip
  type    = "A"
  proxied = true
  ttl     = 1
  comment = "Adopted from manual DNS via import block"
}

# Cache rules: bypass /api/*, cache static assets aggressively
resource "cloudflare_ruleset" "cache_rules" {
  zone_id     = var.zone_id
  name        = "quote-api-cache"
  description = "API bypass + aggressive static cache"
  kind        = "zone"
  phase       = "http_request_cache_settings"

  rules {
    action = "set_cache_settings"
    action_parameters {
      cache = false
    }
    expression  = "(starts_with(http.request.uri.path, \"/api/\"))"
    description = "Bypass cache for API"
    enabled     = true
  }

  rules {
    action = "set_cache_settings"
    action_parameters {
      cache = true
      edge_ttl {
        mode    = "override_origin"
        default = 86400
      }
      browser_ttl {
        mode    = "override_origin"
        default = 3600
      }
    }
    expression  = "(http.request.uri.path.extension in {\"css\" \"js\" \"png\" \"jpg\" \"jpeg\" \"gif\" \"svg\" \"woff\" \"woff2\"})"
    description = "Aggressive static asset cache"
    enabled     = true
  }
}
