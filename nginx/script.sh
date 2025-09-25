# SSL



mkdir -p certs/ca
mkdir -p certs/grafana-certs
mkdir -p certs/server-certs



openssl genrsa -out certs/ca/ca.key 4096
openssl req -x509 -new -nodes -key certs/ca/ca.key -sha256 -days 3650 \
  -subj "/CN=PrometheusCA" \
  -out certs/ca/ca.crt



openssl genrsa -out certs/server-certs/server.key 2048
openssl req -new -key certs/server-certs/server.key -subj "/CN=nginx" -out certs/server-certs/server.csr \
-config openssl.cnf



openssl x509 -req -in certs/server-certs/server.csr \
  -CA certs/ca/ca.crt -CAkey certs/ca/ca.key -CAcreateserial \
  -out certs/server-certs/server.crt -days 365 -sha256 \
  -extfile openssl.cnf -extensions req_ext



openssl genrsa -out certs/grafana-certs/grafana.key 2048
openssl req -new -key certs/grafana-certs/grafana.key -subj "/CN=GrafanaClient" -out certs/grafana-certs/grafana.csr



openssl x509 -req -in certs/grafana-certs/grafana.csr -CA certs/ca/ca.crt -CAkey certs/ca/ca.key \
  -CAcreateserial -out certs/grafana-certs/grafana.crt -days 365 -sha256



rm certs/ca/ca.key
# envsubst < nginx.conf > /etc/nginx/nginx.conf


# create prometheus data_source


echo "Waiting for Grafana to start..."
until curl -s "http://grafana:3000/api/health" | grep -q '"database": "ok"'; do
  sleep 3
done



CA_CERT=$(awk '{printf "%s\\n", $0}' certs/ca/ca.crt)
CLIENT_CERT=$(awk '{printf "%s\\n", $0}' certs/grafana-certs/grafana.crt)
CLIENT_KEY=$(awk '{printf "%s\\n", $0}' certs/grafana-certs/grafana.key)

curl -X POST http://${GRAFANA_USER}:${GRAFANA_PASSWORD}@grafana:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Prometheus\",
    \"type\": \"prometheus\",
    \"url\": \"https://nginx:9090\",
    \"access\": \"proxy\",
    \"jsonData\": {
      \"tlsAuth\": true,
      \"tlsAuthWithCACert\": true,
      \"tlsSkipVerify\": false
    },
    \"secureJsonData\": {
      \"tlsCACert\": \"$CA_CERT\",
      \"tlsClientCert\": \"$CLIENT_CERT\",
      \"tlsClientKey\": \"$CLIENT_KEY\"
    }
  }"


curl -X POST http://${GRAFANA_USER}:${GRAFANA_PASSWORD}@grafana:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @Server-Health-Dashboard.json

curl -X POST http://${GRAFANA_USER}:${GRAFANA_PASSWORD}@grafana:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @Docker-Monitoring.json


nginx
