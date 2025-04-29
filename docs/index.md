![I'm learning Kubernetes](assets/images/img_1.png){ loading=lazy }

## Intro

Homelab gestito (principalmente) con playbook Ansible, ArgoCD e pipeline Gitlab

[What is a Homelab and Why Should You Have One?](https://linuxhandbook.com/homelab/) 

## Prerequisiti

- Istanza di Hashicorp Vault, per storare i secret
- Istanza di GitLab, per storare il codice del repository e far eseguire le pipeline
- 3 vm da usare come Control Plane per il cluster Kubernetes
- (opzionale) altre 3 vm per un cluster di test
- kubectl installato localmente


## Startup

- Una volta fatto il setup del vault
- Tramite l'immagine custom ansible-vault eseguire il playbook kubernetes.yaml per fare il setup del cluster
- copiare localmente il kubeconfig da uno dei 3 nodi
- Tramite l'immagine custom ansible-vault eseguire il playbook argocd.yaml per fare il setup dell'infrastruttura e delle applicazioni
