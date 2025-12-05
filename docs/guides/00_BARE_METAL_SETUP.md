# 🏗️ Sentiric AI Node: Bare Metal (Sıfırdan) Kurulum Rehberi

Bu rehber, NVIDIA GPU'lu bir sunucuyu (örn: RTX 3060) Sentiric AI platformunu çalıştırmak üzere sıfırdan hazırlamak için gereken adımları içerir.

## 🛑 BÖLÜM 1: BIOS / UEFI Ayarları (KRİTİK)

İşletim sistemini kurmadan önce BIOS'a girin ve şu ayarı yapın. Bu yapılmazsa NVIDIA sürücüleri **YÜKLENMEZ**.

1.  **Secure Boot:** **DISABLED** (Kapalı)
    *   *Neden:* Secure Boot, imzalanmamış NVIDIA çekirdek modüllerinin yüklenmesini engeller.
2.  **Fast Boot:** **DISABLED** (Önerilen)
3.  **Above 4G Decoding:** **ENABLED** (VRAM yönetimi için)

---

## 💿 BÖLÜM 2: İşletim Sistemi Kurulumu

*   **OS:** Ubuntu Server 24.04 LTS (veya 22.04 LTS)
*   **Disk Yapılandırması:**
    *   Kurulum sırasında "Use Entire Disk" (Tüm diski kullan) seçeneğini seçin.
    *   "Set up this disk as an LVM group" seçeneğini işaretleyin.
    *   **Önemli:** `/` (root) dizinine diskin tamamını (veya en az 200GB) verdiğinizden emin olun. Varsayılan kurulum bazen sadece 100GB ayırıp gerisini boş bırakabilir.
*   **SSH:** "Install OpenSSH Server" seçeneğini işaretleyin.

---

## 🔐 BÖLÜM 3: Uzaktan Erişim ve Güvenli Ağ (SSH & Tailscale)

Kurulum bittikten sonra makineye fiziksel erişimi kesip uzaktan yönetime geçeceğiz.

### 3.1. SSH Anahtarı Kurulumu (Yönetici Bilgisayarından)
*Bu adımı kendi bilgisayarınızdan yapın, sunucudan değil.*

```bash
# 1. Eğer anahtarınız yoksa oluşturun (Varsa atlayın)
ssh-keygen -t ed25519 -C "admin@sentiric.ai"

# 2. Anahtarı sunucuya gönderin (Parola soracak)
ssh-copy-id -i ~/.ssh/id_ed25519.pub ubuntu@SUNUCU_YEREL_IPSI

# 3. Test edin (Parola sormamalı)
ssh ubuntu@SUNUCU_YEREL_IPSI
```

### 3.2. Parola Girişini Kapatma (Sunucu İçinden)
SSH ile bağlandıktan sonra güvenliği artırmak için parola ile girişi kapatın.

```bash
# Konfigürasyonu düzenle
sudo nano /etc/ssh/sshd_config
# Şu satırı bul ve değiştir: PasswordAuthentication no

# Servisi yeniden başlat
sudo service ssh restart
```

### 3.3. Tailscale Kurulumu (VPN'siz Erişim)
Sunucu NAT arkasında olsa bile erişebilmek için Tailscale kuruyoruz.

```bash
# 1. Kurulum
curl -fsSL https://tailscale.com/install.sh | sh

# 2. Başlatma (Size bir URL verecek, tarayıcıda açıp onaylayın)
sudo tailscale up

# 3. IP'yi Öğrenme
tailscale ip -4
```
*Artık bu makineye dünyanın her yerinden Tailscale IP'si ile erişebilirsiniz.*

---

## 🛠️ BÖLÜM 4: Sistem ve Sürücü Kurulumu

Tailscale veya SSH üzerinden bağlandıktan sonra aşağıdaki komutları sırasıyla çalıştırın.

### 4.1. Sistemi Güncelle
```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y build-essential curl git htop
```

### 4.2. NVIDIA Sürücülerini Kur (Headless/Server Modu)
Masaüstü araçlarına ihtiyacımız yok, sadece hesaplama gücüne ihtiyacımız var. Bu yüzden "server" varyasyonunu kuracağız.

```bash
# 1. Mevcut/varsayılan sürücüleri temizle
sudo apt-get remove --purge '^nvidia-.*' -y
sudo apt-get autoremove -y

# 2. Mevcut sürücüleri listele
sudo apt search nvidia-driver-*-server

# 3. En güncel "server" sürücüsünü kur
# (Listede çıkan en yüksek versiyonu seçin, örn: 580)
sudo apt-get install -y nvidia-driver-580-server

# ALTERNATİF (Eğer en günceli sorun çıkarırsa kararlı LTS sürümü):
# sudo apt-get install -y nvidia-driver-535-server

# 4. Sürücünün ve kernel modüllerinin yüklenmesi için REBOOT ŞART
sudo reboot
```

*(Yeniden başlattıktan sonra `nvidia-smi` komutu ile sürücünün çalıştığını doğrulayın)*

---

## 🐳 BÖLÜM 5: Docker ve NVIDIA Container Toolkit

Yapay zeka konteynerlerinin GPU'ya erişebilmesi için bu adım zorunludur.

### 5.1. Docker Kurulumu
```bash
# Resmi Docker kurulum scripti
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Mevcut kullanıcıyı docker grubuna ekle (sudo'suz docker için)
sudo usermod -aG docker $USER
```
*(Bu aşamada oturumu kapatıp açmanız (logout/login) gerekir)*

### 5.2. NVIDIA Container Toolkit
```bash
# 1. Depoyu ekle
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# 2. Paket listesini güncelle ve kur
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# 3. Docker'ı yapılandır
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 5.3. Nihai Doğrulama
Aşağıdaki komut hata vermeden GPU bilgilerini göstermelidir:
```bash
docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
```

---

## 🚀 BÖLÜM 6: Sentiric AI Studio Kurulumu

```bash
# 1. Repoyu çek
git clone https://github.com/sentiric/sentiric-ai-studio.git
cd sentiric-ai-studio

# 2. Kurulumu Başlat (Sertifikalar otomatik üretilir)
make setup

# 3. Yapılandırma (.env dosyasını kontrol et)
nano .env
# CERTIFICATES_REPO_PATH=./certs olduğundan emin ol

# 4. Servisleri Başlat
make prod
```
