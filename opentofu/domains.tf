variable "whitelisted_domains" {
  description = "Domini in whitelist"
  type = map(object({
    domain  = string
    comment = string
  }))
  default = {
    eventbrite = {
      domain  = "clicks.eventbrite.com"
      comment = "Eventbrite - necessario per email notifications"
    }
    discord = {
      domain  = "click.discord.com"
      comment = "Discord - necessario per email e notifiche"
    }
    external_secrets = {
      domain  = "oci.external-secrets.io"
      comment = "External Secrets Operator - Kubernetes"
    }
  }
}

# NOTE: Il provider ryanwholey/pihole non supporta pihole_domain
# Configura manualmente whitelist/blacklist nell'interfaccia Pi-hole

/*
resource "pihole_domain" "whitelist" {
  for_each = var.whitelisted_domains
  
  domain  = each.value.domain
  kind    = "white"
  comment = each.value.comment
}
*/

variable "blacklisted_domains" {
  description = "Domini in blacklist"
  type = map(object({
    domain  = string
    comment = string
  }))
  default = {
    # Aggiungi qui eventuali domini da bloccare esplicitamente
    # example = {
    #   domain  = "ads.example.com"
    #   comment = "Dominio pubblicitario da bloccare"
    # }
  }
}
