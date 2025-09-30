# Domini bloccati personalizzati
resource "pihole_adlist" "steven_black" {
  url     = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
  comment = "Lista personalizzata di blocco"
  enabled = true
}
resource "pihole_adlist" "kad_hosts" {
  url     = "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
  comment = "Lista personalizzata di blocco"
  enabled = true
}
resource "pihole_adlist" "adguard_dns" {
  url     = "https://v.firebog.net/hosts/AdguardDNS.txt"
  comment = "Lista personalizzata di blocco"
  enabled = true
}
resource "pihole_adlist" "easy_privacy" {
  url     = "https://v.firebog.net/hosts/Easyprivacy.txt"
  comment = "Lista personalizzata di blocco"
  enabled = true
}
resource "pihole_adlist" "ads_and_tracking_extended" {
  url     = "https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"
  comment = "Lista personalizzata di blocco"
  enabled = true
}
resource "pihole_adlist" "spam_hosts" {
  url     = "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
  comment = "Lista personalizzata di blocco"
  enabled = true
}
resource "pihole_adlist" "ads_and_tracking_extended" {
  url     = "https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"
  comment = "Lista personalizzata di blocco"
  enabled = true
}
resource "pihole_adlist" "w3kbl" {
  url     = "https://v.firebog.net/hosts/static/w3kbl.txt"
  comment = "Lista personalizzata di blocco"
  enabled = true
}
resource "pihole_adlist" "prigent_ads" {
  url     = "https://v.firebog.net/hosts/Prigent-Ads.txt"
  comment = "Lista personalizzata di blocco"
  enabled = true
}
resource "pihole_adlist" "big_oisd" {
  url     = "https://big.oisd.nl"
  comment = "Lista personalizzata di blocco"
  enabled = true
}
