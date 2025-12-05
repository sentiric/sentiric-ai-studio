#!/bin/bash
set -e

# Mevcut proje dizini (sentiric-ai-studio)
PROJECT_DIR="$(pwd)"
# Bir üst dizin (sentiric/)
PARENT_DIR="$(dirname "$PROJECT_DIR")"
# Geçici SQL toplama alanı
SQL_STAGING_DIR="$PROJECT_DIR/.tmp/postgres-initdb"

echo "🏗️  Sentiric AI Studio Ortam Hazırlığı Başlıyor..."
echo "📂 Çalışma Alanı: $PARENT_DIR"

# --- 1. FONKSİYON: Public Repo Çekici ---
ensure_repo() {
    local REPO_NAME=$1
    local REPO_URL=$2
    local TARGET_DIR="$PARENT_DIR/$REPO_NAME"

    if [ -d "$TARGET_DIR" ]; then
        echo "🔄 $REPO_NAME güncelleniyor..."
        cd "$TARGET_DIR" && git pull && cd "$PROJECT_DIR"
    else
        echo "⬇️  $REPO_NAME indiriliyor..."
        git clone "$REPO_URL" "$TARGET_DIR"
    fi
}

# --- 2. Bağımlılıkları Çek (Assets ve Database) ---
ensure_repo "sentiric-assets" "https://github.com/sentiric/sentiric-assets.git"
ensure_repo "sentiric-database" "https://github.com/sentiric/sentiric-database.git"

# --- 3. SQL Dosyalarını Birleştir (MERGE STRATEGY) ---
echo "⚙️  Veritabanı dosyaları hazırlanıyor..."

# Klasör yoksa oluştur
mkdir -p "$SQL_STAGING_DIR"

# DİKKAT: Sadece Şema (10_V) ve İndeks (30_I) dosyalarını dışarıdan alacağız.
# Veri (20_R) dosyaları zaten bu projenin içinde (demo datalar).
# Önce eski şemaları temizle (Veri dosyalarına dokunma!)
find "$SQL_STAGING_DIR" -name "10_V*.sql" -delete
find "$SQL_STAGING_DIR" -name "30_I*.sql" -delete

# Güncel şemaları kopyala
cp "$PARENT_DIR/sentiric-database/sql/postgres/10_V"* "$SQL_STAGING_DIR/"
cp "$PARENT_DIR/sentiric-database/sql/postgres/30_I"* "$SQL_STAGING_DIR/"

echo "✅ SQL Şemaları (Database Repo) + Demo Verileri (Local) birleştirildi."

# --- 4. .env Ayarı ---
# Eğer .env yoksa oluştur
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "⚠️  .env dosyası oluşturuldu."
fi

# ASSETS_REPO_PATH'i ../sentiric-assets olarak ayarla (Varsayılan bu olmalı)
# Ancak garanti olsun diye sed ile düzeltelim
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|ASSETS_REPO_PATH=.*|ASSETS_REPO_PATH=../sentiric-assets|g" .env
else
    sed -i "s|ASSETS_REPO_PATH=.*|ASSETS_REPO_PATH=../sentiric-assets|g" .env
fi

echo "✅ Ortam değişkenleri ayarlandı: ASSETS_REPO_PATH=../sentiric-assets"
echo "✨ Hazırlık tamamlandı! Artık 'make prod' yapabilirsiniz."