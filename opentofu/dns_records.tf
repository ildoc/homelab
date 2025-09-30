# Record DNS locali personalizzati

# Proxmox nodes
resource "pihole_dns_record" "pve01" {
  domain = "pve01"
  ip     = "192.168.0.10"
}

resource "pihole_dns_record" "pve02" {
  domain = "pve02"
  ip     = "192.168.0.11"
}

resource "pihole_dns_record" "pve03" {
  domain = "pve03"
  ip     = "192.168.0.12"
}

# Infrastructure services
resource "pihole_dns_record" "invidious" {
  domain = "invidious"
  ip     = "192.168.0.111"
}

resource "pihole_dns_record" "truenas" {
  domain = "truenas"
  ip     = "192.168.0.123"
}

resource "pihole_dns_record" "web" {
  domain = "web"
  ip     = "192.168.0.124"
}

resource "pihole_dns_record" "homeassistant" {
  domain = "homeassistant"
  ip     = "192.168.0.133"
}

resource "pihole_dns_record" "pihole" {
  domain = "pihole"
  ip     = "192.168.0.145"
}

resource "pihole_dns_record" "pihole2" {
  domain = "pihole2"
  ip     = "192.168.0.167"
}

resource "pihole_dns_record" "ubuntu" {
  domain = "ubuntu"
  ip     = "192.168.0.183"
}

# Database and backend services
resource "pihole_dns_record" "db" {
  domain = "db"
  ip     = "192.168.0.30"
}

resource "pihole_dns_record" "redis" {
  domain = "redis"
  ip     = "192.168.0.40"
}

resource "pihole_dns_record" "vault" {
  domain = "vault"
  ip     = "192.168.0.50"
}

# Kubernetes cluster services (192.168.0.80)
resource "pihole_dns_record" "argocd_local" {
  domain = "argocd.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "longhorn_local" {
  domain = "longhorn.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "rancher_local" {
  domain = "rancher.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "traefik_local" {
  domain = "traefik.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "sonarr_local" {
  domain = "sonarr.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "radarr_local" {
  domain = "radarr.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "bazarr_local" {
  domain = "bazarr.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "prowlarr_local" {
  domain = "prowlarr.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "jackett_local" {
  domain = "jackett.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "flaresolverr_local" {
  domain = "flaresolverr.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "pdf_local" {
  domain = "pdf.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "tools_local" {
  domain = "tools.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "change_local" {
  domain = "change.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "truenas_local" {
  domain = "truenas.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "mealie_local" {
  domain = "mealie.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "wg_local" {
  domain = "wg.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "uptime_local" {
  domain = "uptime.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "homepage_local" {
  domain = "homepage.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "speedtest_local" {
  domain = "speedtest.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "nut_local" {
  domain = "nut.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "romm_local" {
  domain = "romm.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "zipline_local" {
  domain = "zipline.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "invidious_local" {
  domain = "invidious.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "readarr_local" {
  domain = "readarr.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "bookbounty_local" {
  domain = "bookbounty.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "kestra_local" {
  domain = "kestra.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "paperless_local" {
  domain = "paperless.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "kitchenowl_local" {
  domain = "kitchenowl.local.ildoc.it"
  ip     = "192.168.0.80"
}

resource "pihole_dns_record" "audiobookshelf_local" {
  domain = "audiobookshelf.local.ildoc.it"
  ip     = "192.168.0.80"
}

# GitLab services (192.168.0.25)
resource "pihole_dns_record" "gitlab_local" {
  domain = "gitlab.local.ildoc.it"
  ip     = "192.168.0.25"
}

resource "pihole_dns_record" "registry_gitlab_local" {
  domain = "registry.gitlab.local.ildoc.it"
  ip     = "192.168.0.25"
}

# Secondary cluster services (192.168.0.100)
resource "pihole_dns_record" "argocd2_local" {
  domain = "argocd2.local.ildoc.it"
  ip     = "192.168.0.100"
}

resource "pihole_dns_record" "traefik2_local" {
  domain = "traefik2.local.ildoc.it"
  ip     = "192.168.0.100"
}

resource "pihole_dns_record" "rancher2_local" {
  domain = "rancher2.local.ildoc.it"
  ip     = "192.168.0.100"
}
