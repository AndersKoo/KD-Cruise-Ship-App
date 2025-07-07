# 🚢 Cruise Ship App - System Oversikt

Dette er en komplett cruise ship applikasjon med monitoring og observability. Systemet består av en Python API, PostgreSQL database, og et omfattende monitoring-stack med Prometheus og Grafana.

## 📁 Prosjektstruktur

```
KD-Cruise-Ship-App/
├── k8s/                          # Kubernetes konfigurasjoner
│   ├── monitoring/               # Prometheus og Grafana
│   │   ├── grafana-deployment.yaml
│   │   ├── prometheus.yaml
│   │   ├── prometheus-service.yaml
│   │   └── planned-events-api-servicemonitor.yaml
│   ├── planned-events-api/      # API deployment
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── postgres/                # Database deployment
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   └── init.sql
│   └── planned-events-dashboard.json  # Grafana dashboard konfigurasjon
├── planned-events-api/          # Python API kode
│   ├── app.py                   # Flask applikasjon
│   └── requirements.txt         # Python dependencies
├── start.sh                     # Automatisk oppstart script
├── grafana-password-fix.sh      # Script for å fikse Grafana passord
├── instructions.md              # Detaljert oppstart guide
└── README.md                    # Denne filen
```

## 🏗️ Systemkomponenter

### 1. **API Server (planned-events-api)**

- **Teknologi**: Python Flask
- **Port**: 5001 (intern), 80 (ekstern)
- **Endpoints**:
  - `/healthz` - Health check
  - `/v1/events` - Hent cruise events
  - `/metrics` - Prometheus metrics
- **Metrics**: Automatisk metrics collection for requests og latens

### 2. **Database (PostgreSQL)**

- **Versjon**: PostgreSQL 14
- **Database**: cruise_db
- **Bruker**: cruise_user
- **Storage**: Persistent volume (1Gi)
- **Init**: Automatisk opprettelse av tabeller og testdata

### 3. **Monitoring Stack**

#### Prometheus (Metrics Collection)

- **Rolle**: Samler metrics fra alle komponenter
- **Storage**: Persistent volume (10Gi)
- **Service Discovery**: Automatisk oppdaging av metrics endpoints
- **Metrics Sources**:
  - API server (`/metrics` endpoint)
  - PostgreSQL (via postgres-exporter)

#### Grafana (Visualisering)

- **Rolle**: Dashboard og visualisering
- **Port**: 3000 (intern), 80 (ekstern)
- **Brukernavn**: admin
- **Passord**: admin123
- **Storage**: Persistent volume (10Gi)
- **Dashboard**: Pre-konfigurert dashboard for API og database monitoring

## 📊 Monitoring og Observability

### Metrics som samles inn:

- **HTTP Requests**: Antall, status koder, varighet
- **Database Performance**: Disk bruk, connection pools
- **API Performance**: Response times, error rates
- **System Health**: Pod status, resource usage

### Grafana Dashboard Features:

- **Success/Failed Requests**: Real-time request rates
- **PostgreSQL Disk Usage**: Database storage monitoring
- **API Response Times**: 95th percentile latens
- **Request Distribution**: Pie chart av endpoints
- **Time Series Graphs**: Historisk data over tid

## 🚀 Oppstart

### Automatisk oppstart:

```bash
./start.sh
```

### Manuel oppstart:

```bash
# Start minikube
minikube start --memory=4096 --cpus=2 --disk-size=20g

# Deploy komponenter
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/planned-events-api/
kubectl apply -f k8s/monitoring/

# Start port-forwarding
kubectl port-forward svc/planned-events-api 8080:80 &
kubectl port-forward svc/grafana 3001:80 &
kubectl port-forward svc/prometheus 9090:9090 &
```

## 🌐 Tilgang til applikasjonen

### API Endpoints:

- **Base URL**: http://localhost:8080
- **Health Check**: http://localhost:8080/healthz
- **Events**: http://localhost:8080/v1/events
- **Metrics**: http://localhost:8080/metrics

### Monitoring Dashboards:

- **Grafana**: http://localhost:3001 (admin/admin123)
- **Prometheus**: http://localhost:9090

## 🔧 Verktøy og Scripts

### start.sh

- Automatisk deployment av alle komponenter
- Port-forwarding setup
- Testdata generering
- Health checks

### grafana-password-fix.sh

- Fikser Grafana admin passord
- Resetter til admin123
- Starter port-forwarding for Grafana

### instructions.md

- Detaljert steg-for-steg guide
- Installasjonsinstruksjoner
- Feilsøking
- Utviklingsinstruksjoner

## 🧪 Testing

### API Testing:

```bash
# Health check
curl http://localhost:8080/healthz

# Hent events
curl http://localhost:8080/v1/events

# Se metrics
curl http://localhost:8080/metrics
```

### Dashboard Testing:

1. Gå til http://localhost:3001
2. Logg inn med admin/admin123
3. Naviger til dashboards for å se metrics

## 🛑 Stoppe applikasjonen

```bash
# Stopp port-forwarding
pkill -f "kubectl port-forward"

# Stopp minikube
minikube stop

# Eller slett cluster
minikube delete
```

## 📈 Dashboard Metrics

Grafana dashboardet viser:

1. **Success Requests (2xx)** - Antall vellykkede requests per minutt
2. **Failed Requests (4xx)** - Antall feilede requests per minutt
3. **PostgreSQL Disk Space** - Database størrelse og disk bruk
4. **API Response Time** - 95th percentile response time
5. **Request Distribution** - Fordeling av requests på endpoints
6. **Time Series Graphs** - Historisk data over tid

## 🔍 Feilsøking

### Vanlige problemer:

- **Grafana passord reset**: Kjør `./grafana-password-fix.sh`
- **Port-forwarding feiler**: Sjekk at pods kjører med `kubectl get pods`
- **API svarer ikke**: Sjekk logs med `kubectl logs -l app=planned-events-api`

## 📚 Ytterligere dokumentasjon

- **Detaljert guide**: Se `instructions.md` for komplett oppstart guide
- **API dokumentasjon**: Se `planned-events-api/app.py` for endpoint detaljer
- **Monitoring setup**: Se `k8s/monitoring/` for Prometheus/Grafana konfigurasjon

---

**Hjelp?** Start med `instructions.md` for detaljert guide, eller sjekk feilsøkingsseksjonen ovenfor.
