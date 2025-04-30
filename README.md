# Homelab

[![documentation](https://img.shields.io/website?label=document&logo=gitbook&logoColor=white&style=flat-square&url=https%3A%2F%2Fhomelab.ildoc.it)](https://homelab.ildoc.it)
[![license](https://img.shields.io/github/license/ildoc/homelab?style=flat-square&logo=gnu&logoColor=white)](https://www.gnu.org/licenses/gpl-3.0.html)

Questo progetto mira a utilizzare [Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_code) e [GitOps](https://www.weave.works/technologies/gitops) per automatizzare il più possibile l'installazione e la configurazione del software che gira sul mio Homelab.

Nel 2020 sono partito da un docker-compose e oggi sono messo così... è un work in progress continuo 😅

> **Che cos'è un homelab?**
>
> Un Homelab è un laboratorio casalingo dove si può fare self-hosting, sperimentare nuove tecnologie, fare pratica per certificazioni e così via.
>
> Per maggiori informazioni fare riferimento alla introduzione di [r/homelab](https://www.reddit.com/r/homelab/wiki/introduction) e alla community Discord [Home Operations](https://discord.gg/home-operations) (ex [k8s-at-home](https://k8s-at-home.com)).
>
> Un ottimo articolo è anche [What is a Homelab and Why Should You Have One?](https://linuxhandbook.com/homelab/) 


## Overview generale

Tutto l'Homelab gestito (principalmente) con playbook Ansible, ArgoCD e pipeline Gitlab.

**NOTA:** questo repository GitHub è un mirror del repository originale che si trova sulla mia istanza privata di GitLab

## Tech stack

<table>
    <tr>
        <th>Logo</th>
        <th>Nome</th>
        <th>Descrzione</th>
    </tr>
    <tr>
        <td><img width="32" src="https://simpleicons.org/icons/ansible.svg"></td>
        <td><a href="https://www.ansible.com">Ansible</a></td>
        <td>Automazione di deploy e configurazioni</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/30269780"></td>
        <td><a href="https://argoproj.github.io/cd">ArgoCD</a></td>
        <td>Tool GitOps per deployare su Kubernetes</td>
    </tr>
    <tr>
        <td><img width="32" src="https://github.com/jetstack/cert-manager/raw/master/logo/logo.png"></td>
        <td><a href="https://cert-manager.io">cert-manager</a></td>
        <td>Cloud native certificate management</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/21054566?s=200&v=4"></td>
        <td><a href="https://cilium.io">Cilium</a></td>
        <td>eBPF-based Networking, Observability e Security (CNI, Network Policy, ecc.)</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/314135?s=200&v=4"></td>
        <td><a href="https://www.cloudflare.com">Cloudflare</a></td>
        <td>Issuer dei certificati e Tunnel</td>
    </tr>
    <tr>
        <td><img width="32" src="https://www.docker.com/wp-content/uploads/2022/03/Moby-logo.png"></td>
        <td><a href="https://www.docker.com">Docker</a></td>
        <td>Orchestrazione di container con docker compose</td>
    </tr>
    <tr>
        <td><img width="32" src="https://images.ctfassets.net/xz1dnu24egyd/1IRkfXmxo8VP2RAE5jiS1Q/ea2086675d87911b0ce2d34c354b3711/gitlab-logo-500.png"></td>
        <td><a href="https://gitlab.com">GitLab</a></td>
        <td>Self-hosted Git</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/13991055?s=200&v=4"></td>
        <td><a href="https://www.hashicorp.com/en/products/vault">HashiCorp Vault</a></td>
        <td>Secrets management</td>
    </tr>
    <tr>
        <td><img width="32" src="https://helm.sh/img/helm.svg"></td>
        <td><a href="https://helm.sh">Helm</a></td>
        <td>Package manager per Kubernetes</td>
    </tr>
    <tr>
        <td><img width="32" src="https://kube-vip.io/images/kube-vip.png"></td>
        <td><a href="https://kube-vip.io">kube-vip</a></td>
        <td>Virtual IP e load balancer</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/13629408"></td>
        <td><a href="https://kubernetes.io">Kubernetes</a></td>
        <td>Container-orchestration system</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/1412239?s=200&v=4"></td>
        <td><a href="https://www.nginx.com">NGINX</a></td>
        <td>Reverse Proxy</td>
    </tr>
    <tr>
        <td><img width="32" src="https://wp-cdn.pi-hole.net/wp-content/uploads/2016/12/Vortex-R.png"></td>
        <td><a href="https://pi-hole.net/">Pi-hole</a></td>
        <td>Ad blocker, DNS e DHCP</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/13991055?s=200&v=4"></td>
        <td><a href="https://www.proxmox.com">Proxmox</a></td>
        <td>Virtualizzazione di VM e LXC</td>
    </tr>
    <tr>
        <td><img width="32" src="https://docs.renovatebot.com/assets/images/logo.png"></td>
        <td><a href="https://docs.renovatebot.com/">Renovate</a></td>
        <td>Update automatico delle dipendenze</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/14280338?s=200&v=4"></td>
        <td><a href="https://doc.traefik.io/traefik/">Traefik</a></td>
        <td>Kubernetes Ingress Controller</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/53482242?s=200&v=4"></td>
        <td><a href="https://www.truenas.com/">TrueNAS</a></td>
        <td>NFS share, Backup</td>
    </tr>
    <tr>
        <td><img width="32" src="https://upload.wikimedia.org/wikipedia/commons/1/16/Ubuntu_and_Ubuntu_Server_Icon.png"></td>
        <td><a href="https://ubuntu.com/server">Ubuntu Server</a></td>
        <td>Os di base per i nodi Kubernetes</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/13991055?s=200&v=4"></td>
        <td><a href="https://www.wireguard.com">Wireguard</a></td>
        <td>VPN tunnel</td>
    </tr>
</table>
