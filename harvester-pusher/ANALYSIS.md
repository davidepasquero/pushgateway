# Analisi Comparativa degli Script: `app.sh` vs `app01.sh`

Questo documento analizza le differenze tra due versioni di uno script (`app.sh` e `app01.sh`) progettato per inviare metriche da Harvester a un Prometheus Pushgateway.

## Tabella Riassuntiva

| Caratteristica | `harvester-pusher/app.sh` (Originale) | `harvester-pusher/app01.sh` (Soluzione Proposta) | Impatto e Vantaggi della Soluzione Proposta |
| :--- | :--- | :--- | :--- |
| **Strategia di Push** | **Bulk Push**: Tutte le metriche di tutte le VM vengono inviate in un'unica richiesta `curl`. | **Push Individuale**: Esegue un ciclo (`while`) per inviare le metriche di ogni VM con una richiesta `curl` separata. | **Maggiore Resilienza**: Se una singola metrica è malformata, solo il push per quella specifica VM fallirà, non l'intero batch. |
| **Grouping delle Metriche** | **Gruppo Unico**: Tutte le metriche vengono inviate all'endpoint `/metrics/job/harvester-vm-status`. Questo le raggruppa tutte sotto un'unica etichetta `job`. | **Gruppi Separati per Istanza**: Ogni metrica viene inviata a un URL univoco: `/metrics/job/harvester-vm-health/instance/<vm_name>`. | **Conformità e Gestibilità**: Questo è l'approccio **raccomandato dalla documentazione**. Permette di gestire (es. visualizzare o cancellare) le metriche di ogni VM in modo indipendente, evitando conflitti. |
| **Struttura dello Script** | Script compatto, quasi un "one-liner", che concatena i comandi con `|`. | Script più strutturato e leggibile, che separa la logica di parsing (`jq`) da quella di invio (`while` loop). | **Migliore Manutenibilità**: Lo script è più facile da capire, debuggare e modificare in futuro. |
| **Autenticazione** | Non mostra come viene ottenuto il token (`$TOKEN` è presupposto). | Include l'intero flusso di autenticazione: legge le credenziali dai secret e richiede un token a Harvester. | **Completezza**: Lo script è autonomo e pronto all'uso, senza dipendenze esterne per l'autenticazione. |
| **Endpoint del Pushgateway** | Punta a `http://127.0.0.1:9091`, suggerendo un'esecuzione locale o con port-forwarding. | Punta a `http://pushgateway.cattle-monitoring-system.svc.cluster.local:9091`, l'indirizzo corretto per un servizio in-cluster Kubernetes. | **Correttezza**: Utilizza il DNS interno di Kubernetes, rendendolo funzionante all'interno del cluster dove è deployato il CronJob. |

## Conclusione

La differenza più significativa risiede nel **modello di grouping delle metriche**. La soluzione proposta (`app01.sh`) adotta la best practice di creare un gruppo di metriche distinto per ogni "istanza" (in questo caso, ogni VM), rendendo l'integrazione con Prometheus robusta, scalabile e gestibile. La versione originale, al contrario, accumulava tutte le metriche in un unico gruppo, una pratica che la documentazione ufficiale del Pushgateway sconsiglia attivamente perché rende difficile la gestione e la pulizia delle metriche obsolete.
