# SSL



mkdir -p certs/ca
mkdir -p certs/grafana-certs
mkdir -p certs/server-certs



openssl genrsa -out certs/ca/ca.key 4096
openssl req -x509 -new -nodes -key certs/ca/ca.key -sha256 -days 3650 \
  -subj "/CN=PrometheusCA" \
  -out certs/ca/ca.crt



openssl genrsa -out certs/server-certs/server.key 2048
openssl req -new -key certs/server-certs/server.key -subj "/CN=prometheus-proxy" -out certs/server-certs/server.csr \
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
envsubst < nginx.conf > /etc/nginx/nginx.conf



# GRAFANA PROVISIONING



CERT_DIR="certs/grafana-certs"
CA_DIR="certs/ca"
OUTPUT_DIR="/usr/share/grafana/conf/provisioning/datasources"
OUTPUT_FILE="$OUTPUT_DIR/prometheus.yaml"



mkdir -p "$OUTPUT_DIR"



cat > "$OUTPUT_FILE" <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: https://prometheus-proxy:443
    jsonData:
      tlsAuth: true
      tlsAuthWithCACert: true
      tlsSkipVerify: false
    secureJsonData:
      tlsCACert: |
$(sed 's/^/        /' "$CA_DIR/ca.crt")
      tlsClientCert: |
$(sed 's/^/        /' "$CERT_DIR/grafana.crt")
      tlsClientKey: |
$(sed 's/^/        /' "$CERT_DIR/grafana.key")
EOF



nginx
