# 🚢 Cruise Ship App - Lokal Oppstart Guide

Dette er en steg-for-steg guide for å kjøre Cruise Ship App lokalt på din maskin. Applikasjonen består av en Python API, PostgreSQL database, og et monitoring-stack med Prometheus og Grafana.

## 📋 Forutsetninger

### 1. Operativsystem

- **macOS** (anbefalt)
- **Linux** (Ubuntu/Debian)
- **Windows** (med WSL2 anbefalt)

### 2. Nødvendige verktøy

#### Docker Desktop

```bash
# macOS (med Homebrew)
brew install --cask docker

# Eller last ned fra: https://www.docker.com/products/docker-desktop/
```

#### Minikube

```bash
# macOS
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Windows (med Chocolatey)
choco install minikube
```

#### kubectl

```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows (med Chocolatey)
choco install kubernetes-cli
```

#### Homebrew (kun macOS)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 🚀 Installasjon og Oppstart

### Steg 1: Verifiser installasjoner

```bash
# Sjekk at Docker kjører
docker --version
docker ps

# Sjekk minikube
minikube version

# Sjekk kubectl
kubectl version --client
```

### Steg 2: Start Minikube

```bash
# Start minikube med nødvendige ressurser
minikube start --memory=4096 --cpus=2 --disk-size=20g

# Verifiser at cluster kjører
kubectl cluster-info
```

### Steg 3: Klone prosjektet

```bash
# Hvis du ikke allerede har gjort det
git clone <repository-url>
cd KD-Cruise-Ship-App
```

### Steg 4: Kjør applikasjonen

```bash
# Gjør start-skriptet kjørbart
chmod +x start.sh

# Start applikasjonen
./start.sh
```

## 📊 Hva skjer når du kjører start.sh?

Skriptet vil:

1. **Rydde opp** - Stoppe eksisterende prosesser
2. **Sjekke minikube** - Starte hvis nødvendig
3. **Deploye PostgreSQL** - Database med testdata
4. **Deploye API** - Python Flask-applikasjon
5. **Deploye Prometheus** - Metrics collection
6. **Deploye Grafana** - Dashboard og visualisering
7. **Sette opp port-forwarding** - Gjøre tjenester tilgjengelige lokalt
8. **Generere testdata** - Legge til eksempel cruise events

## 🌐 Tilgang til applikasjonen

Etter at start.sh er ferdig, kan du aksessere:

### API Endpoints

- **API Base URL**: http://localhost:8080
- **Health Check**: http://localhost:8080/healthz
- **Events Endpoint**: http://localhost:8080/v1/events
- **Metrics**: http://localhost:8080/metrics

### Monitoring Dashboards

- **Grafana**: http://localhost:3001
  - Brukernavn: `admin`
  - Passord: `admin123`
- **Prometheus**: http://localhost:9090

## 🧪 Teste applikasjonen

### Test API

```bash
# Health check
curl http://localhost:8080/healthz

# Hent events
curl http://localhost:8080/v1/events

# Se metrics
curl http://localhost:8080/metrics
```

### Test Grafana Dashboard

1. Gå til http://localhost:3001
2. Logg inn med `admin` / `admin123`
3. Naviger til dashboards for å se metrics

## 🔧 Feilsøking

### Vanlige problemer og løsninger

#### Minikube starter ikke

```bash
# Sjekk Docker
docker ps

# Restart minikube
minikube stop
minikube start

# Sjekk status
minikube status
```

#### Port-forwarding fungerer ikke

```bash
# Sjekk at pods kjører
kubectl get pods

# Restart port-forwarding
kubectl port-forward svc/planned-events-api 8080:80 &
kubectl port-forward svc/grafana 3001:80 &
kubectl port-forward svc/prometheus 9090:9090 &
```

#### API svarer ikke

```bash
# Sjekk API pod status
kubectl get pods -l app=planned-events-api

# Se logs
kubectl logs -l app=planned-events-api

# Sjekk database tilkobling
kubectl logs -l app=postgres
```

#### Grafana viser ingen data

1. Sjekk at Prometheus er tilgjengelig
2. Verifiser datasource i Grafana (http://localhost:3001/datasources)
3. Sjekk at API metrics endpoint fungerer

## 🛑 Stoppe applikasjonen

```bash
# Stopp port-forwarding
pkill -f "kubectl port-forward"

# Stopp minikube (valgfritt)
minikube stop

# Eller slett cluster (start på nytt)
minikube delete
```

## 📁 Prosjektstruktur

```
KD-Cruise-Ship-App/
├── k8s/                          # Kubernetes konfigurasjoner
│   ├── monitoring/               # Prometheus og Grafana
│   ├── planned-events-api/      # API deployment
│   └── postgres/                # Database deployment
├── planned-events-api/          # Python API kode
│   ├── app.py                   # Flask applikasjon
│   └── requirements.txt         # Python dependencies
├── start.sh                     # Oppstart script
└── README.md                    # Prosjekt dokumentasjon
```

## 🔍 Monitoring og Observability

### Metrics som samles inn:

- **HTTP requests** - Antall og varighet
- **Database connections** - Tilkoblingsstatus
- **Error rates** - Feil og exceptions
- **Response times** - API ytelse

### Grafana Dashboards:

- **API Performance** - Request rates og latens
- **Database Health** - Connection pools og query performance
- **System Overview** - Overall system status

## 🚀 Utvikling

### Lokal utvikling av API

```bash
# Installer Python dependencies
cd planned-events-api
pip install -r requirements.txt

# Kjør API lokalt
python app.py
```

### Oppdatere kode

```bash
# Etter endringer i app.py
kubectl create configmap planned-events-api-code --from-file=app.py=planned-events-api/app.py --from-file=requirements.txt=planned-events-api/requirements.txt --dry-run=client -o yaml | kubectl apply -f -

# Restart API pod
kubectl rollout restart deployment/planned-events-api
```

## 📚 Ytterligere ressurser

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**Hjelp?** Hvis du støter på problemer, sjekk først feilsøkingsseksjonen ovenfor. For ytterligere hjelp, opprett en issue i prosjektet.
