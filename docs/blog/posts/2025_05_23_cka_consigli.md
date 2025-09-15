---
date: 2025-05-15
authors: [ildoc]
title: "Certified Kubernetes Administrator (CKA): come funziona e consigli"
tags:
  - kubernetes
draft: true
---
![Certified Kubernetes Administrator (CKA)](https://training.linuxfoundation.org/wp-content/uploads/2018/06/logo_cka_whitetext.png){ loading=lazy }

L'esame è di tipo pratico, si tratta di circa 16 quesiti (il numero è variabile) da svolgere in due ore di tempo.

Ogni domanda è da svolgersi collegandosi in ssh su un host diverso, quindi scriversi alias complessi è tempo perso

- Leggere bene il testo della domanda prima di cominciare a risolvere il problema
- Non c'è una validazione delle risposte, prima di concludere la prova meglio tenersi un po' di tempo per fare un giro su tutte le domande e ricontrollare le risposte date
- Se una domanda risulta troppo impegnativa non ha senso continuare a perderci tempo, è possibile sfruttare la funzionalità di flag per marcarla e poterci poi ritornare in un secondo momento
- è molto importante fare tanta pratica con la sintassi imperativa di kubectl e i suoi switch, perchè fa risparmiare molto tempo
- in molti casi ci si può aiutare con la sintassi imperativa per creare lo yaml di base di un manifest da poi continuare a editare dopo (es `k run --image=nginx --dry-run=client -o yaml > pod.yaml`)

- durante l'esame è possibile consultare la documentazione di https://kubernetes.io, https://etcd.io e https://helm.sh. All'inizio di ogni domanda ci sono link diretti alle pagine degli argomenti trattati nel quesito
- è quindi importante saper navigare bene nella documentazione per recuperare facilmente informazioni e pezzi di codice già scritti
- il flag `--help` dei vari comandi di kubectl è fondamentale
- `kubectl explain` è utilissimo se si hanno dei dubbi sulla struttura degli oggetti che si stanno creando/modificando, specialmente con il flag --recursive

- l'alias `k=kubectl` è già presente su tutti gli ambienti
- NON è NECESSARIO CONOSCERE VI, si può benissimo usare nano esportandosi di volta in volta la variabile `KUBE_EDITOR=nano` oppure anteponendola ai comandi di edit

- alcune domande sono composte da più step. gli step vengono valutati singolarmente, quindi anche se la domanda non viene completata del tutto è possibile comunque che faccia punteggio
- ci sono sicuramente un paio di domande che prendono molto tempo anche se si sa cosa c'è da fare per completarle, meglio tenersele per ultime

- `k replace -f manifest.yaml --force` è più veloce che eliminare prima la risorsa per poi ricrearla

- quando si affronta una nuova domanda, fare un `clear` appena ci si collega al nuovo host può aiutare a staccare con la domanda precedente
- fare attenzione a creare le risorse nei namespace corretti
- fare attenzione ai nomi che si danno alle risorse, specialmente quelle che se lo autogenerano come i servizi o gli horizontalpodautoscaler


## Il giorno dell'esame
- L'esame si svogle tramite un browser apposito disponibile da scaricare da dentro il portale. In teoria è dato per compatibile anche con Ubuntu, ma non sono riuscito a farlo funzionare e mi sono arreso ad usare Windows.
- Questo browser controlla anche l'attività dei programmi durante l'esame, quindi meglio eseguirlo su un pc privato, in modo da evitare sorprese tipo programmi lanciati da policy aziendali.
- Meglio cercare di fissare l'esame di mattina, quando si è più freschi
- La stanza e la scrivania devono essere pulite e in ordine
- L'esame comincia con una fase di verifica da parte del tutor in cui viene richiesto di mostrare l'ambiente circostante tramite la webcam. Possono essere richiesti dei cambiamenti (es. spostare cose, togliere dei quadri) per cui meglio accedere all'esame una mezz'oretta prima dell'orario fissato
- durante l'esame ci dev'essere silenzio, se si ragiona ad alta voce si viene subito ammoniti

