# Record DNS locali personalizzati

variable "dns_records" {
  description = "Tutti i record DNS da configurare in Pi-hole"
  type = map(object({
    ip      = string
    comment = string
  }))
  default = {
    # Nodi Proxmox
    pve01 = { ip = "192.168.0.10", comment = "Proxmox node 1" }
    pve02 = { ip = "192.168.0.11", comment = "Proxmox node 2" }
    pve03 = { ip = "192.168.0.12", comment = "Proxmox node 3" }
    
    # Servizi infrastrutturali
    invidious     = { ip = "192.168.0.111", comment = "YouTube frontend" }
    truenas       = { ip = "192.168.0.123", comment = "NAS storage" }
    web           = { ip = "192.168.0.124", comment = "Web server" }
    homeassistant = { ip = "192.168.0.133", comment = "Home automation" }
    pihole        = { ip = "192.168.0.145", comment = "Pi-hole primario" }
    pihole2       = { ip = "192.168.0.167", comment = "Pi-hole secondario" }
    ubuntu        = { ip = "192.168.0.183", comment = "Server Ubuntu" }
    db            = { ip = "192.168.0.30", comment = "Database server" }
    redis         = { ip = "192.168.0.40", comment = "Redis cache" }
    vault         = { ip = "192.168.0.50", comment = "HashiCorp Vault" }
    
    # Servizi cluster Kubernetes principale (192.168.0.80)
    "argocd.local.ildoc.it"         = { ip = "192.168.0.80", comment = "ArgoCD GitOps" }
    "longhorn.local.ildoc.it"       = { ip = "192.168.0.80", comment = "Longhorn storage" }
    "rancher.local.ildoc.it"        = { ip = "192.168.0.80", comment = "Rancher management" }
    "traefik.local.ildoc.it"        = { ip = "192.168.0.80", comment = "Traefik ingress" }
    "sonarr.local.ildoc.it"         = { ip = "192.168.0.80", comment = "Sonarr TV shows" }
    "radarr.local.ildoc.it"         = { ip = "192.168.0.80", comment = "Radarr movies" }
    "bazarr.local.ildoc.it"         = { ip = "192.168.0.80", comment = "Bazarr subtitles" }
    "prowlarr.local.ildoc.it"       = { ip = "192.168.0.80", comment = "Prowlarr indexer" }
    "jackett.local.ildoc.it"        = { ip = "192.168.0.80", comment = "Jackett proxy" }
    "flaresolverr.local.ildoc.it"   = { ip = "192.168.0.80", comment = "FlareSolverr CloudFlare" }
    "pdf.local.ildoc.it"            = { ip = "192.168.0.80", comment = "PDF tools" }
    "tools.local.ildoc.it"          = { ip = "192.168.0.80", comment = "Various tools" }
    "change.local.ildoc.it"         = { ip = "192.168.0.80", comment = "Change detection" }
    "truenas.local.ildoc.it"        = { ip = "192.168.0.80", comment = "TrueNAS dashboard" }
    "mealie.local.ildoc.it"         = { ip = "192.168.0.80", comment = "Mealie recipes" }
    "wg.local.ildoc.it"             = { ip = "192.168.0.80", comment = "WireGuard UI" }
    "uptime.local.ildoc.it"         = { ip = "192.168.0.80", comment = "Uptime monitoring" }
    "homepage.local.ildoc.it"       = { ip = "192.168.0.80", comment = "Homepage dashboard" }
    "speedtest.local.ildoc.it"      = { ip = "192.168.0.80", comment = "Speed test" }
    "nut.local.ildoc.it"            = { ip = "192.168.0.80", comment = "NUT UPS monitor" }
    "romm.local.ildoc.it"           = { ip = "192.168.0.80", comment = "ROM manager" }
    "zipline.local.ildoc.it"        = { ip = "192.168.0.80", comment = "File sharing" }
    "invidious.local.ildoc.it"      = { ip = "192.168.0.80", comment = "Invidious YouTube" }
    "readarr.local.ildoc.it"        = { ip = "192.168.0.80", comment = "Readarr ebooks" }
    "bookbounty.local.ildoc.it"     = { ip = "192.168.0.80", comment = "Book bounty" }
    "kestra.local.ildoc.it"         = { ip = "192.168.0.80", comment = "Kestra workflow" }
    "paperless.local.ildoc.it"      = { ip = "192.168.0.80", comment = "Paperless documents" }
    "kitchenowl.local.ildoc.it"     = { ip = "192.168.0.80", comment = "Kitchen management" }
    "audiobookshelf.local.ildoc.it" = { ip = "192.168.0.80", comment = "Audiobook server" }
    
    # Servizi GitLab (192.168.0.25)
    "gitlab.local.ildoc.it"          = { ip = "192.168.0.25", comment = "GitLab CE" }
    "registry.gitlab.local.ildoc.it" = { ip = "192.168.0.25", comment = "GitLab Container Registry" }
    
    # Servizi cluster secondario (192.168.0.100)
    "argocd2.local.ildoc.it"  = { ip = "192.168.0.100", comment = "ArgoCD cluster 2" }
    "traefik2.local.ildoc.it" = { ip = "192.168.0.100", comment = "Traefik cluster 2" }
    "rancher2.local.ildoc.it" = { ip = "192.168.0.100", comment = "Rancher cluster 2" }
  }
}

# Creazione di tutti i record DNS con un singolo for_each
resource "pihole_dns_record" "all" {
  for_each = var.dns_records
  
  domain = each.key
  ip     = each.value.ip
}
