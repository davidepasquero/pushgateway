# Installazione di Harvester-Pusher su Kubernetes

Questo documento descrive i passaggi per installare l'applicazione `harvester-pusher` su un cluster Kubernetes utilizzando Helm, prelevando la chart da Artifactory.

`harvester-pusher` è un CronJob che raccoglie metriche sullo stato delle VM da Harvester e le invia a un Prometheus Pushgateway per il monitoraggio.

## Prerequisiti

*   Un cluster Kubernetes funzionante.
*   Helm v3 installato e configurato.
*   Accesso al registry Docker `docker-nivola.ecosis.csi.it` (per il pull dell'immagine).
*   Accesso al repository Helm `https://repo.ecosis.csi.it/artifactory/helm-nivola` (per il pull della chart).

## Passaggi di Installazione

Seguire i seguenti passaggi per deployare `harvester-pusher`.

### 1. Aggiungere il Repository Helm di Nivola

Per prima cosa, aggiungi il repository Helm di Nivola al tuo client Helm:

```bash
helm repo add nivola https://repo.ecosis.csi.it/artifactory/helm-nivola
```

### 2. Aggiornare i Repository Helm

Aggiorna i tuoi repository Helm per assicurarti di avere le ultime versioni delle chart disponibili, inclusa quella di `harvester-pusher`:

```bash
helm repo update
```

### 3. Installare o Aggiornare la Chart Harvester-Pusher

Utilizza il comando `helm upgrade --install` per deployare `harvester-pusher`. Questo comando installerà la chart se non è già presente, o la aggiornerà se esiste.

**Parametri importanti da configurare:**

*   `--namespace cattle-monitoring-system`: Specifica il namespace in cui verrà deployato il CronJob e il Secret. Assicurati che questo namespace esista nel tuo cluster.
*   `--version 1.1.2`: Specifica la versione esatta della chart da installare. Assicurati che corrisponda alla versione che hai caricato su Artifactory.
*   `--set image.tag=1.1.2`: Imposta il tag dell'immagine Docker che il CronJob utilizzerà. Assicurati che questa immagine sia stata precedentemente pushata al registry Docker configurato.
*   `--set credentials.password='LA_TUA_PASSWORD_REALE'`: **OBBLIGATORIO**. Sostituisci `LA_TUA_PASSWORD_REALE` con la password effettiva per l'autenticazione all'API di Harvester. È fondamentale che questa password sia corretta.
*   `--set credentials.endpoint='https://vip-harvester-prod.r01az01.nivolapiemonte.it'`: (Opzionale, se diverso dal default) Imposta l'endpoint dell'API di Harvester. Il valore di default è già configurato nella chart, ma puoi sovrascriverlo qui se necessario.

Esegui il seguente comando:

```bash
helm upgrade --install harvester-pusher nivola/harvester-pusher-chart \
  --namespace cattle-monitoring-system \
  --version 1.1.2 \
  --set image.tag=1.1.2 \
  --set credentials.password='Cs1$harvester!2025' \
  --set credentials.endpoint='https://vip-harvester-prod.r01az01.nivolapiemonte.it'
```

**Nota:** La password `Cs1$harvester!2025` è stata usata come esempio. Assicurati di usare la password corretta per il tuo ambiente.

## Verifica dell'Installazione

Dopo l'installazione, puoi verificare lo stato del CronJob e dei Job eseguiti:

```bash
kubectl get cronjob -n cattle-monitoring-system harvester-pusher
kubectl get jobs -n cattle-monitoring-system -l app.kubernetes.io/name=harvester-pusher
kubectl get pods -n cattle-monitoring-system -l app.kubernetes.io/name=harvester-pusher
```

Per visualizzare i log di un Job specifico (utile per il debug):

```bash
# Trova il nome del pod più recente
POD_NAME=$(kubectl get pods -n cattle-monitoring-system -l app.kubernetes.io/name=harvester-pusher -o jsonpath='{.items[0].metadata.name}')

# Visualizza i log del pod
kubectl logs -n cattle-monitoring-system $POD_NAME
```

I log ti mostreranno i passaggi dello script `fetch-and-push.sh`, inclusi i tentativi di autenticazione, il recupero delle metriche e l'invio al Pushgateway.
