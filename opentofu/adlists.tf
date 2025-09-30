variable "adlists" {
  description = "Liste di blocco pubblicitarie"
  type = map(object({
    url     = string
    comment = string
    enabled = bool
  }))
  default = {
    steven_black = {
      url     = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
      comment = "Steven Black unified hosts (ads + malware)"
      enabled = true
    }
    kad_hosts = {
      url     = "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
      comment = "KAD hosts - ads and tracking"
      enabled = true
    }
    adguard_dns = {
      url     = "https://v.firebog.net/hosts/AdguardDNS.txt"
      comment = "AdGuard DNS filter"
      enabled = true
    }
    easy_privacy = {
      url     = "https://v.firebog.net/hosts/Easyprivacy.txt"
      comment = "EasyPrivacy - tracking protection"
      enabled = true
    }
    ads_tracking_extended = {
      url     = "https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"
      comment = "DeveloperDan ads and tracking extended"
      enabled = true
    }
    spam_hosts = {
      url     = "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
      comment = "FadeMind spam hosts"
      enabled = true
    }
    w3kbl = {
      url     = "https://v.firebog.net/hosts/static/w3kbl.txt"
      comment = "W3KBL - malware domains"
      enabled = true
    }
    prigent_ads = {
      url     = "https://v.firebog.net/hosts/Prigent-Ads.txt"
      comment = "Prigent advertising domains"
      enabled = true
    }
    big_oisd = {
      url     = "https://big.oisd.nl"
      comment = "OISD big list - comprehensive blocking"
      enabled = true
    }
  }
}

# NOTE: Il provider ryanwholey/pihole non supporta pihole_adlist
# Configura manualmente queste adlist nell'interfaccia Pi-hole

/*
resource "pihole_adlist" "lists" {
  for_each = var.adlists
  
  url     = each.value.url
  comment = each.value.comment
  enabled = each.value.enabled
}
*/
