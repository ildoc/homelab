# Domini in whitelist (permessi anche se bloccati)
resource "pihole_domain" "eventbrite" {
  domain  = "clicks.eventbrite.com"
  kind    = "white"
  comment = "Necessario per il funzionamento di alcuni servizi"
}
resource "pihole_domain" "discord" {
  domain  = "click.discord.com"
  kind    = "white"
  comment = "Necessario per il funzionamento di alcuni servizi"
}
resource "pihole_domain" "external_secrets" {
  domain  = "oci.external-secrets.io"
  kind    = "white"
  comment = "Necessario per il funzionamento di alcuni servizi"
}

# # Domini in blacklist (sempre bloccati)
# resource "pihole_domain" "blocked_domain" {
#   domain  = "ads.example.com"
#   kind    = "black"
#   comment = "Dominio pubblicitario da bloccare"
# }
