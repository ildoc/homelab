---
date: 2025-05-15
authors: [ildoc]
title: "External Secrets Operator, Vault e ArgoCD: The (quasi) GitOps Way"
tags:
  - kubernetes
  - gitops
  - argocd
draft: true
---
![Gitops con ArgoCD](/assets/images/gitops_argocd.png){ loading=lazy }

Quando ho deciso di provare a passare i servizi che hostavo con docker-compose su un cluster Kubernetes, ho deciso di farlo in modalità GitOps, ossia mantenere un repository con i manifest e lasciare ad un tool il compito di monitorare i cambiamenti e applicarli al cluster.

In questo modo posso scrivere in maniera dichiarativa (e versionare) tutte le configurazioni ed avere la certezza che se qualcosa non è presente sul repo, allora non esiste sul cluster.
<!-- more -->
Una delle cose che volevo correggere nel mio repo era la gestione delle password, o meglio, la loro NON-gestione 😅

Quindi ho scelto di cominciare a utilizzare [HashiCorp Vault](https://www.hashicorp.com/products/vault) per gestire tutte le credenziali che avevo sparso in giro in chiaro.
