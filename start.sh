#!/bin/bash

echo "🚢 Cruise Ship App - Enkel Startup med Testdata"
echo "================================================"

# Stopp eksisterende prosesser
echo "🧹 Rydder opp..."
pkill -f "kubectl port-forward" 2>/dev/null || true
pkill -f "generate-test-data.sh" 2>/dev/null || true
sleep 3

# Sjekk minikube
echo "🔍 Sjekker minikube..."
if kubectl cluster-info >/dev/null 2>&1; then
    echo "✅ Minikube kjører"
else
    echo "⚠️  Starter minikube..."
    minikube start
fi

# Opprett ConfigMap for API-koden
echo "📦 Oppretter ConfigMap for API-koden..."
kubectl create configmap planned-events-api-code --from-file=app.py=planned-events-api/app.py --from-file=requirements.txt=planned-events-api/requirements.txt 2>/dev/null || echo "✅ ConfigMap finnes allerede"

# Sjekk om postgres allerede kjører
POSTGRES_RUNNING=$(kubectl get pods -l app=postgres --no-headers 2>/dev/null | grep Running | wc -l)
if [ "$POSTGRES_RUNNING" -gt 0 ]; then
    echo "✅ PostgreSQL kjører allerede, hopper over deploy."
else
    echo "🚀 Deployer PostgreSQL..."
    kubectl apply -f k8s/postgres/ 2>/dev/null || echo "⚠️  PostgreSQL allerede deployet"
fi

# Deploy bare de nødvendige komponentene
echo "🚀 Deployer nødvendige komponenter..."
kubectl apply -f k8s/planned-events-api/ 2>/dev/null || echo "⚠️  API allerede deployet"

# Deploy enkel Prometheus (uten kube-prometheus-stack)
echo "📈 Deployer enkel Prometheus..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'planned-events-api'
        static_configs:
          - targets: ['planned-events-api:80']
        metrics_path: /metrics
      - job_name: 'postgres-exporter'
        static_configs:
          - targets: ['postgres-exporter:9187']
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
spec:
  type: ClusterIP
  ports:
  - port: 9090
    targetPort: 9090
  selector:
    app: prometheus
EOF

# Deploy enkel Grafana
echo "📊 Deployer enkel Grafana..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus:9090
      access: proxy
      isDefault: true
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: admin
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: admin123
        volumeMounts:
        - name: datasources
          mountPath: /etc/grafana/provisioning/datasources
      volumes:
      - name: datasources
        configMap:
          name: grafana-datasources
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 3000
  selector:
    app: grafana
EOF

# Vent på at pods er klare
echo "⏳ Venter på at pods er klare..."
echo "   - Venter på PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s 2>/dev/null || echo "⚠️  PostgreSQL venting feilet"

echo "   - Venter på API..."
kubectl wait --for=condition=ready pod -l app=planned-events-api --timeout=300s 2>/dev/null || echo "⚠️  API venting feilet"

echo "   - Venter på Prometheus..."
kubectl wait --for=condition=ready pod -l app=prometheus --timeout=300s 2>/dev/null || echo "⚠️  Prometheus venting feilet"

echo "   - Venter på Grafana..."
kubectl wait --for=condition=ready pod -l app=grafana --timeout=300s 2>/dev/null || echo "⚠️  Grafana venting feilet"

# Start port-forwarding
echo "🌐 Starter port-forwarding..."
kubectl port-forward svc/grafana 3001:80 > /dev/null 2>&1 &
GRAFANA_PID=$!
echo "📊 Grafana: http://localhost:3001"

kubectl port-forward svc/prometheus 9090:9090 > /dev/null 2>&1 &
PROMETHEUS_PID=$!
echo "📈 Prometheus: http://localhost:9090"

kubectl port-forward svc/planned-events-api 8080:80 > /dev/null 2>&1 &
API_PID=$!
echo "🔌 API: http://localhost:8080/v1/events"

# Test at API er tilgjengelig
echo "🔍 Tester API-tilgjengelighet..."
sleep 10
if curl -s http://localhost:8080/healthz >/dev/null 2>&1; then
    echo "✅ API er tilgjengelig"
else
    echo "⚠️  API er ikke tilgjengelig ennå"
fi

# Integrert testdata-generering
echo "📊 Starter integrert testdata-generering..."

# Funksjon for å vente litt
wait_a_bit() {
    echo "⏳ Venter $1 sekunder..."
    sleep $1
}

# Funksjon for å sjekke om API er tilgjengelig
check_api_availability() {
    echo "🔍 Sjekker API-tilgjengelighet..."
    for i in {1..10}; do
        if curl -s http://localhost:8080/healthz >/dev/null 2>&1; then
            echo "✅ API er tilgjengelig"
            return 0
        else
            echo "⏳ Venter på API... (forsøk $i/10)"
            sleep 5
        fi
    done
    echo "❌ API er ikke tilgjengelig etter 10 forsøk"
    return 1
}

# Funksjon for å gjøre API-kall
make_api_call() {
    local endpoint=$1
    local expected_status=$2
    local description=$3
    
    echo "📡 Kaller $endpoint - Forventer status $expected_status"
    response=$(curl -s -w "%{http_code}" -o /tmp/response.json "http://localhost:8080$endpoint" 2>/dev/null)
    status_code=${response: -3}
    
    if [ "$status_code" = "$expected_status" ]; then
        echo "✅ $description - Status: $status_code"
        return 0
    else
        echo "❌ $description - Status: $status_code (forventet $expected_status)"
        return 1
    fi
}

# Funksjon for å legge til data i PostgreSQL
add_postgres_data() {
    echo "🗄️  Legger til testdata i PostgreSQL..."
    
    # Finn PostgreSQL pod
    POSTGRES_POD=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$POSTGRES_POD" ]; then
        echo "❌ Kunne ikke finne PostgreSQL pod"
        return 1
    fi
    
    echo "📦 Bruker PostgreSQL pod: $POSTGRES_POD"
    
    # Sjekk om testdata allerede finnes
    EXISTS=$(kubectl exec -it "$POSTGRES_POD" -- psql -U cruise_user -d cruise_db -tAc "SELECT COUNT(*) FROM planned_events_tab WHERE voyage_id = 'VOY006' AND vessel_id = 'VESSEL003' AND from_date = '2025-07-06 10:00:00';" 2>/dev/null | tr -d '[:space:]')
    if [ "$EXISTS" = "0" ]; then
        # Koble til PostgreSQL og legg til testdata
        kubectl exec -it "$POSTGRES_POD" -- psql -U cruise_user -d cruise_db -c "
        INSERT INTO planned_events_tab (voyage_id, vessel_id, from_date, to_date, event) VALUES 
        ('VOY006', 'VESSEL003', '2025-07-06 10:00:00', '2025-07-06 12:00:00', 'Test Event 1'),
        ('VOY007', 'VESSEL004', '2025-07-06 14:00:00', '2025-07-06 16:00:00', 'Test Event 2'),
        ('VOY008', 'VESSEL005', '2025-07-06 18:00:00', '2025-07-06 20:00:00', 'Test Event 3'),
        ('VOY009', 'VESSEL006', '2025-07-07 08:00:00', '2025-07-07 10:00:00', 'Test Event 4'),
        ('VOY010', 'VESSEL007', '2025-07-07 12:00:00', '2025-07-07 14:00:00', 'Test Event 5');
        " 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ Testdata lagt til i PostgreSQL"
            return 0
        else
            echo "❌ Kunne ikke legge til data i PostgreSQL"
            return 1
        fi
    else
        echo "ℹ️  Testdata finnes allerede i PostgreSQL, hopper over innsetting."
        return 0
    fi
}

# Sjekk at API er tilgjengelig først
if ! check_api_availability; then
    echo "❌ Kan ikke generere testdata - API er ikke tilgjengelig"
    echo "💡 Sørg for at applikasjonen er startet"
fi

echo "📊 Dette vil skape trafikk som vises i dashboardet:"
echo "   - Success requests (2xx)"
echo "   - Failed requests (4xx)" 
echo "   - PostgreSQL disk space endringer"

# Fase 1: Generer vellykkede requests (2xx)
echo ""
echo "🟢 Fase 1: Genererer vellykkede requests (2xx)..."
success_count=0
for i in {1..20}; do
    if make_api_call "/v1/events" "200" "Vellykket API-kall $i"; then
        ((success_count++))
    fi
    wait_a_bit 2
done

echo "✅ Vellykkede requests: $success_count/20"

wait_a_bit 5

# Fase 2: Generer feilede requests (4xx)
echo ""
echo "🔴 Fase 2: Genererer feilede requests (4xx)..."
failed_count=0
for i in {1..5}; do
    if make_api_call "/nonexistent-endpoint" "404" "Feilet API-kall $i"; then
        ((failed_count++))
    fi
    wait_a_bit 1
done

for i in {1..3}; do
    if make_api_call "/invalid-path" "404" "Ugyldig path $i"; then
        ((failed_count++))
    fi
    wait_a_bit 1
done

echo "✅ Feilede requests: $failed_count/8"

wait_a_bit 5

# Fase 3: Legg til data i PostgreSQL
echo ""
echo "🗄️  Fase 3: Legger til data i PostgreSQL..."
if add_postgres_data; then
    echo "✅ PostgreSQL data lagt til"
else
    echo "⚠️  Kunne ikke legge til PostgreSQL data, fortsetter..."
fi

wait_a_bit 5

# Fase 4: Generer mer trafikk etter database-endringer
echo ""
echo "🔄 Fase 4: Genererer mer trafikk etter database-endringer..."
post_success_count=0
for i in {1..15}; do
    if make_api_call "/v1/events" "200" "Post-database API-kall $i"; then
        ((post_success_count++))
    fi
    wait_a_bit 3
done

echo "✅ Post-database requests: $post_success_count/15"

# Fase 5: Kontinuerlig trafikk (kjør i bakgrunnen)
echo ""
echo "🔄 Fase 5: Starter kontinuerlig trafikk-generering..."
(
    while true; do
        # Vellykket kall
        curl -s "http://localhost:8080/v1/events" > /dev/null 2>&1
        sleep 10
        
        # Health check
        curl -s "http://localhost:8080/healthz" > /dev/null 2>&1
        sleep 10
        
        # Metrics endpoint
        curl -s "http://localhost:8080/metrics" > /dev/null 2>&1
        sleep 10
    done
) &
CONTINUOUS_PID=$!

echo "✅ Kontinuerlig trafikk startet (PID: $CONTINUOUS_PID)"

# Lagre PIDs
echo "$GRAFANA_PID $PROMETHEUS_PID $API_PID $CONTINUOUS_PID" > .running_pids

echo ""
echo "🎉 Cruise Ship App startet (Enkel versjon med testdata)!"
echo "========================================================"
echo "📊 Dashboards:"
echo "   Grafana:     http://localhost:3001 (admin/admin123)"
echo "   Prometheus:  http://localhost:9090"
echo "   API:         http://localhost:8080/v1/events"
echo ""
echo "💡 Denne versjonen kjører bare de nødvendige komponentene:"
echo "   - PostgreSQL database"
echo "   - Planned Events API"
echo "   - Enkel Prometheus (uten kube-prometheus-stack)"
echo "   - Enkel Grafana"
echo "   - Automatisk testdata-generering"
echo ""
echo "📈 Metrics som nå skal vises:"
echo "   - Success requests (2xx): Vellykkede API-kall"
echo "   - Failed requests (4xx): Feilede API-kall" 
echo "   - PostgreSQL disk space: Endringer i database-størrelse"
echo ""
echo "💡 Tips:"
echo "   - Vent 1-2 minutter før du sjekker Grafana"
echo "   - Oppdater dashboardet hvis data ikke vises umiddelbart"
echo "   - Bruk Prometheus UI (http://localhost:9090) for å verifisere metrics"
echo ""
echo "🛑 For å stoppe:"
echo "   ./stop-app.sh"
echo ""
echo "✅ Applikasjonen kjører nå!"

# Vent på bruker-input
echo ""
echo "Trykk Ctrl+C for å stoppe..."
trap 'echo -e "\nStopper..."; kill $GRAFANA_PID $PROMETHEUS_PID $API_PID $CONTINUOUS_PID 2>/dev/null; rm -f .running_pids; exit' INT
wait 