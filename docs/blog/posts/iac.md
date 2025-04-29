---
date: 2025-01-22
authors: [ildoc]
title: "HaC: Homelab as Code"
description: >
    prova descrizione
tags:
  - kubernetes
  - gitops

draft: true
---
![I'm learning Kubernetes](/assets/images/img_1.png){ loading=lazy }

## Concept
L'idea è quella di ottenere un cluster Kubernetes su Proxmox per hostare le mie applicazioni tutto in modalità completamente GitOps con un repository sufficientemente pulito e customizzabile da poter essere reso pubblico su GitHub

### Target
Un cluster di 3 VM di cui 1 control-plane e 2 worker. Traefik e cert-manager, SSO con Autentik, ArgoCD per il deploy di tutto.

### Prerequisiti necessari
- Un'istanza di Gitea che conterrà la source of truth
- Un'istanza di HashiCorp Vault che conterrà tutti i vari secret

## Provisioning
Il primo step è creare 3 virtual con Ubuntu 24.04

### Packer

### Terraform



### CI/CD

## Configurazione
### Installazione Kubernetes con Ansible

## Apply del manifest d'inizio e GitOps con ArgoCD
