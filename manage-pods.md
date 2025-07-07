## 🔍 Kubernetes Pod Kommandoer

Her er en omfattende oversikt over kommandoer for å sjekke Pods i Kubernetes:

### 🔍 Grunnleggende Pod Status

#### Se alle Pods:

```bash
# Liste alle Pods
kubectl get pods

# Med mer informasjon
kubectl get pods -o wide

# Alle namespaces
kubectl get pods --all-namespaces
```

#### Se detaljert status:

```bash
# Detaljert informasjon om en spesifikk Pod
kubectl describe pod <pod-name>

# Eksempel:
kubectl describe pod postgres-abc123
```

### Pod Status Typer

#### Se Pod status:

```bash
# Se status på alle Pods
kubectl get pods

# Mulige statuser:
# - Running     ✅ Pod kjører
# - Pending     ⏳ Venter på ressurser
# - Failed      ❌ Pod feilet
# - Succeeded   ✅ Pod fullført (Job)
# - Unknown     ❓ Status ukjent
# - CrashLoopBackOff 🔄 Pod krasjer og restarter
```

#### Se Pod status med labels:

```bash
# Se Pods med spesifikk label
kubectl get pods -l app=postgres

# Se Pods med flere labels
kubectl get pods -l app=postgres,environment=production
```

### Detaljerte Sjekker

#### Se Pod events:

```bash
# Se events for en Pod
kubectl get events --field-selector involvedObject.name=<pod-name>

# Se alle events
kubectl get events --sort-by='.lastTimestamp'
```

#### Se Pod logs:

```bash
# Se logs fra en Pod
kubectl logs <pod-name>

# Se logs fra en container i multi-container Pod
kubectl logs <pod-name> -c <container-name>

# Følg logs i sanntid
kubectl logs -f <pod-name>

# Se logs fra siste 10 minutter
kubectl logs --since=10m <pod-name>
```

#### Se Pod ressursbruk:

```bash
# Se CPU og minne bruk
kubectl top pods

# Se ressursbruk for en spesifikk Pod
kubectl top pod <pod-name>
```

### Spesifikke Sjekker for Dette Prosjektet

#### Sjekk PostgreSQL Pod:

```bash
# Se PostgreSQL Pod status
kubectl get pods -l app=postgres

# Se PostgreSQL logs
kubectl logs -l app=postgres

# Test database tilkobling
kubectl exec -it $(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U cruise_user -d cruise_db
```

#### Sjekk API Pod:

```bash
# Se API Pod status
kubectl get pods -l app=planned-events-api

# Se API logs
kubectl logs -l app=planned-events-api

# Test API health
kubectl exec -it $(kubectl get pods -l app=planned-events-api -o jsonpath='{.items[0].metadata.name}') -- curl localhost:5001/healthz
```

#### Sjekk Prometheus Pod:

```bash
# Se Prometheus Pod status
kubectl get pods -l app=prometheus

# Se Prometheus logs
kubectl logs -l app=prometheus

# Test Prometheus metrics
kubectl exec -it $(kubectl get pods -l app=prometheus -o jsonpath='{.items[0].metadata.name}') -- curl localhost:9090/api/v1/targets
```

#### Sjekk Grafana Pod:

```bash
# Se Grafana Pod status
kubectl get pods -l app=grafana

# Se Grafana logs
kubectl logs -l app=grafana

# Test Grafana tilgjengelighet
kubectl exec -it $(kubectl get pods -l app=grafana -o jsonpath='{.items[0].metadata.name}') -- curl localhost:3000/api/health
```

### 🔄 Avanserte Sjekker

#### Se Pod readiness:

```bash
# Se readiness status
kubectl get pods -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready

# Se Pod conditions
kubectl get pods -o custom-columns=NAME:.metadata.name,PODSCHEDULED:.status.conditions[0].status,READY:.status.conditions[1].status
```

#### Se Pod restart count:

```bash
# Se hvor mange ganger Pod har restartet
kubectl get pods -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount

# Se Pods med mange restarts
kubectl get pods --field-selector=status.containerStatuses[0].restartCount>0
```

#### Se Pod age:

```bash
# Se når Pod ble opprettet
kubectl get pods -o custom-columns=NAME:.metadata.name,AGE:.metadata.creationTimestamp

# Se Pods eldre enn 1 time
kubectl get pods --field-selector=metadata.creationTimestamp<$(date -d '1 hour ago' -Iseconds)
```

### 🛠️ Troubleshooting Kommandoer

#### Se Pod ikke starter:

```bash
# Se detaljert status
kubectl describe pod <pod-name>

# Se events
kubectl get events --field-selector involvedObject.name=<pod-name>

# Se logs fra init containers
kubectl logs <pod-name> -c <init-container-name>
```

#### Se Pod krasjer:

```bash
# Se crash logs
kubectl logs <pod-name> --previous

# Se Pod status
kubectl get pod <pod-name> -o yaml

# Se container status
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].state}'
```

#### Se Pod nettverk:

```bash
# Se Pod IP
kubectl get pod <pod-name> -o jsonpath='{.status.podIP}'

# Test nettverk fra Pod
kubectl exec -it <pod-name> -- nslookup kubernetes.default

# Se Pod DNS
kubectl exec -it <pod-name> -- cat /etc/resolv.conf
```

### 📈 Monitoring Kommandoer

#### Se Pod metrics:

```bash
# Se CPU og minne bruk
kubectl top pods

# Se Pod metrics over tid
kubectl top pods --containers

# Se Pod resource limits
kubectl get pods -o custom-columns=NAME:.metadata.name,CPU:.spec.containers[0].resources.limits.cpu,MEMORY:.spec.containers[0].resources.limits.memory
```

#### Se Pod events over tid:

```bash
# Se events siste time
kubectl get events --since=1h

# Se events for en spesifikk Pod
kubectl get events --field-selector involvedObject.name=<pod-name> --since=1h
```

### 🎯 Praktiske Eksempler

#### Sjekk hele applikasjonen:

```bash
# Se status på alle komponenter
echo "=== POD STATUS ==="
kubectl get pods

echo "=== SERVICES ==="
kubectl get services

echo "=== EVENTS ==="
kubectl get events --since=5m
```

#### Sjekk spesifikk komponent:

```bash
# Sjekk PostgreSQL
echo "=== POSTGRESQL ==="
kubectl get pods -l app=postgres
kubectl logs -l app=postgres --tail=10

# Sjekk API
echo "=== API ==="
kubectl get pods -l app=planned-events-api
kubectl logs -l app=planned-events-api --tail=10
```

#### Sjekk monitoring:

```bash
# Sjekk Prometheus
echo "=== PROMETHEUS ==="
kubectl get pods -l app=prometheus
kubectl logs -l app=prometheus --tail=5

# Sjekk Grafana
echo "=== GRAFANA ==="
kubectl get pods -l app=grafana
kubectl logs -l app=grafana --tail=5
```

Disse kommandoene gir deg en komplett oversikt over Pod status og hjelper deg med troubleshooting!
