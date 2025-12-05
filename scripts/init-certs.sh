#!/bin/bash
set -e

# Sertifika dizini (Proje içinde yerel)
CERTS_DIR="./certs"
mkdir -p "$CERTS_DIR"

echo "🔐 Sertifika Kurulumu Başlatılıyor..."

if [ -f "$CERTS_DIR/ca.key" ]; then
    echo "✅ Sertifikalar zaten mevcut. Atlanıyor."
    exit 0
fi

echo "⚙️ CA (Otorite) oluşturuluyor..."
# CA Private Key & Certificate
openssl genrsa -out "$CERTS_DIR/ca.key" 4096
openssl req -x509 -new -nodes -key "$CERTS_DIR/ca.key" -sha256 -days 3650 \
    -out "$CERTS_DIR/ca.crt" \
    -subj "/C=TR/ST=Antalya/L=Antalya/O=Sentiric/CN=Sentiric Root CA"

# Servis listesi (Docker compose service adlarıyla uyumlu olmalı)
SERVICES=(
    "llm-llama-service"
    "stt-whisper-service"
    "tts-coqui-service"
    "knowledge-query-service"
    "knowledge-indexing-service"
    "qdrant"
)

for SERVICE in "${SERVICES[@]}"; do
    echo "🔑 Sertifika üretiliyor: $SERVICE"
    
    # Private Key
    openssl genrsa -out "$CERTS_DIR/$SERVICE.key" 2048
    
    # CSR Config
    cat > "$CERTS_DIR/$SERVICE.cnf" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = TR
ST = Antalya
L = Antalya
O = Sentiric
CN = $SERVICE

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $SERVICE
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

    # CSR Oluştur
    openssl req -new -key "$CERTS_DIR/$SERVICE.key" -out "$CERTS_DIR/$SERVICE.csr" -config "$CERTS_DIR/$SERVICE.cnf"
    
    # İmzala (CRT Oluştur)
    openssl x509 -req -in "$CERTS_DIR/$SERVICE.csr" -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" \
        -CAcreateserial -out "$CERTS_DIR/$SERVICE.crt" -days 365 -sha256 -extfile "$CERTS_DIR/$SERVICE.cnf" -extensions req_ext
    
    # Chain Oluştur (Servis + CA)
    cat "$CERTS_DIR/$SERVICE.crt" "$CERTS_DIR/ca.crt" > "$CERTS_DIR/$SERVICE-chain.crt"
    
    # Temizlik
    rm "$CERTS_DIR/$SERVICE.csr" "$CERTS_DIR/$SERVICE.cnf"
done

# İzinleri ayarla (Postgres ve diğer servisler okuyabilsin diye)
chmod -R 755 "$CERTS_DIR"
echo "✅ Tüm sertifikalar '$CERTS_DIR' içine oluşturuldu."