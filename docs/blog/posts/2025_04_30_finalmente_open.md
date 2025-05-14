---
date: 2025-04-30
authors: [ildoc]
title: "Finalmente open!"
tags:
  - kubernetes
  - gitops
---
![Homelab 2025](/assets/images/homelab2025.jpg){ loading=lazy }

Circa a maggio 2020 in mezzo ai lockdown del COVID ho iniziato a tirarmi su un mediaserver con un semplice docker-compose e oggi, dopo quasi 5 anni di smarmellamenti, ho deciso di provare a rendere pubblico il repository del mio homelab.

Sostanzialmente è diviso in due grosse parti:

- [Ansible](https://github.com/ildoc/homelab/tree/main/ansible): per installare e configurare i servizi che stanno su delle VM o dei LXC sul cluster di Proxmox (Vault, Gitlab, PiHole)
- [Kubernetes](https://github.com/ildoc/homelab/tree/main/kubernetes): con entrypoint root-applications.yaml gestito tutto in modalità Gitops tramite ArgoCD, sia la parte di infrastruttura (cert-manager, traefik, rancher), sia quella di applicazioni.

Visto che avevo key e password versionate dappertutto, nelle ultime settimane ho provato a spostare tutto su Hashicorp Vault usando una [immagine docker custom](https://github.com/ildoc/ansible-vault) con vault-agent per poter lanciare i playbook Ansible che uso per deployare e configurare tutto.

Su Kubernetes invece ho integrato [External Secret Operator](https://external-secrets.io/latest/) sempre per poter recuperare i secret dal Vault e mi sono "divertito" a trovare un modo per deployarlo e configurarlo in modalità GitOps con ArgoCD.

![I'm learning Kubernetes](/assets/images/img_1.png){ loading=lazy }

E' rimasto ancora qualcosa fuori, per cui per ora ho un job nel gitlab-ci di questo repository che dà una ripulita prima di committare e pushare il tutto su un nuovo repo "pulito" che poi fa mirroring su Github.

Come ultima novità ho introdotto [MkDocs](https://squidfunk.github.io/mkdocs-material/) per cominciare a fare un po' di documentazione e gestire gli aggiornamenti di questo mini blog che verrà pubblicato sulle Github Pages da una Github Action sul repository mirrorato.

Di cose da fare ce ne sono un sacco...

- Voglio implementare Harbor per fare il caching delle immagini Docker di DockerHub in modo da non sforare i nuovi limiti di pull orari
- Vorrei approfondire Terraform/Opentofu per fare il provisioning delle vm su Proxmox in modo da poter collegare il tutto ai due playbook con cui faccio il setup del cluster Kubernetes e la sua configurazione iniziale
- Devo implementare il monitoring e le notifiche su tutti i servizi
- Vorrei un SSO centralizzato per tutto, tipo Autentik
- Mi piacerebbe scorporare dei roles Ansible per poterli distribuire in repository a sé stanti
- Vorrei documentare bene il tutto e magari provare a scrivere degli altri post su questo blog relativamente a problemi con cui mi scontro o cose che provo
- Vorrei man mano pulire bene il repository, sistemare le sync wave e gli hook di argocd, rivedere i roles di ansible, fare il linting di tutti gli yaml

Intanto rendere open questo repo è stata una bella sfida, adesso avanti con i prossimi step!
