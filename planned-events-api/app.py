from flask import Flask, jsonify
import psycopg2
import os
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Definerer metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency')

# Registrerer metrics for healthz endpoint
@app.route("/healthz")
def healthz():
    REQUEST_COUNT.labels(method='GET', endpoint='/healthz', status='200').inc()
    return "OK", 200

@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route("/v1/events")
@REQUEST_LATENCY.time()
def get_events():
    try:
        conn = psycopg2.connect(
            dbname=os.getenv('DB_NAME', 'cruise_db'),
            user=os.getenv('DB_USER', 'cruise_user'),
            password=os.getenv('DB_PASSWORD', 'cruise_pass'),
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', 5433))
        )
        cur = conn.cursor()
        cur.execute("SELECT voyage_id, vessel_id, from_date, to_date, event FROM planned_events_tab")
        events = [
            {
                "voyageId": row[0],
                "vesselId": row[1],
                "fromUtc": row[2].isoformat(),
                "toUtc": row[3].isoformat(),
                "event": row[4]
            }
            for row in cur.fetchall()
        ]
        cur.close()
        conn.close()
        # Registrerer metrics for successful API calls
        REQUEST_COUNT.labels(method='GET', endpoint='/v1/events', status='200').inc()
        return jsonify(events), 200
    except Exception as e:
        status = '503' if 'connection' in str(e).lower() else '500'
        # Registrerer metrics for failed API calls
        REQUEST_COUNT.labels(method='GET', endpoint='/v1/events', status=status).inc()
        return jsonify({"error": str(e)}), int(status)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)