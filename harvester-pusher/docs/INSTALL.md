# Guida all'Installazione

Questa guida descrive i passaggi per installare il **Prometheus Pushgateway** e il **Harvester Metrics Pusher** su un cluster Kubernetes tramite Helm.

## Prerequisiti

-   `helm` installato e configurato per il tuo cluster.
-   `docker` installato e configurato per eseguire il build e il push di immagini su un container registry.
-   Accesso a un cluster Kubernetes e al namespace di destinazione (in questa guida, `cattle-monitoring-system`).

---

## 1. Installazione del Prometheus Pushgateway

Il Pushgateway viene utilizzato come destinazione per le metriche inviate da job di breve durata.

### Configurazione

Il file `pushgateway-values.yaml` è pre-configurato per abilitare l'integrazione con l'operatore Prometheus tramite un `ServiceMonitor`. In particolare:

-   `serviceMonitor.enabled: true`: Abilita la creazione della risorsa `ServiceMonitor`.
-   `serviceMonitor.labels`: Aggiunge le etichette necessarie affinché Prometheus scopra il ServiceMonitor.
-   `serviceMonitor.matchLabels`: Seleziona l'istanza corretta del servizio Pushgateway da monitorare.

### Comandi di Installazione

1.  **Aggiungi il repository Helm di Prometheus Community:**
    ```sh
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    ```

2.  **Installa o aggiorna il Pushgateway:**
    Esegui il comando seguente, assicurandoti di trovarti nella root del progetto dove risiede il file `pushgateway-values.yaml`.

    ```sh
    helm upgrade --install my-pushgateway prometheus-community/prometheus-pushgateway \
      --namespace cattle-monitoring-system \
      -f pushgateway-values.yaml
    ```
    > **Nota:** Il nome del release (`my-pushgateway`) e il namespace (`cattle-monitoring-system`) possono essere personalizzati secondo le tue esigenze.

---

## 2. Installazione del Harvester Metrics Pusher

Questo componente è un `CronJob` che recupera periodicamente le metriche di stato delle VM da un'istanza Harvester e le invia al Pushgateway.

### Passaggio 1: Build e Push dell'Immagine Docker

Lo script che recupera le metriche viene eseguito all'interno di un container. È necessario costruire l'immagine e caricarla su un registry accessibile dal tuo cluster Kubernetes.

1.  **Esegui il build dell'immagine:**
    Dalla root del progetto, esegui il comando seguente. Sostituisci `1.1.2` con la versione desiderata.

    ```sh
    docker build -t docker-nivola.ecosis.csi.it/harvester-metrics-pusher:1.1.2 harvester-pusher/
    ```

2.  **Esegui il push dell'immagine:**
    ```sh
    docker push docker-nivola.ecosis.csi.it/harvester-metrics-pusher:1.1.2
    ```
    > **Importante:** Assicurati che il repository (`docker-nivola.ecosis.csi.it/harvester-metrics-pusher`) corrisponda a quello specificato nel file `values.yaml` del chart.

### Passaggio 2: Installazione tramite Helm Chart

Il deploy viene gestito tramite il chart Helm presente in `harvester-pusher/harvester-pusher-chart`.

1.  **Controlla la configurazione:**
    Apri il file `harvester-pusher/harvester-pusher-chart/values.yaml` e assicurati che i seguenti valori siano corretti per il tuo ambiente:
    -   `image.repository`
    -   `image.tag`
    -   `credentials.endpoint` (l'URL del tuo Harvester)
    -   `credentials.username`

2.  **Installa o aggiorna il chart:**
    Esegui il comando seguente, **sostituendo `YOUR_REAL_PASSWORD` con la password corretta** per l'utente Harvester.

    ```sh
    helm upgrade --install harvester-pusher harvester-pusher/harvester-pusher-chart \
      --namespace cattle-monitoring-system \
      --set image.tag=1.1.2 \
      --set credentials.password='YOUR_REAL_PASSWORD'
    ```

Una volta completato, il `CronJob` verrà creato e inizierà a inviare le metriche all'intervallo di tempo specificato (`schedule` nel `values.yaml`).
