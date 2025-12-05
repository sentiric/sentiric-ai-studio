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

## 🛠️ BÖLÜM 3: Sistem ve Sürücü Kurulumu

Sunucu açıldıktan sonra SSH ile bağlanın ve aşağıdaki komutları sırasıyla çalıştırın.

### 3.1. Sistemi Güncelle
```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y build-essential curl git htop
```

### 3.2. NVIDIA Sürücülerini Kur (Headless/Server Modu)
Masaüstü araçlarına ihtiyacımız yok, sadece hesaplama gücüne ihtiyacımız var.

```bash
# Mevcut/varsayılan sürücüleri temizle
sudo apt-get remove --purge '^nvidia-.*' -y
sudo apt-get autoremove -y

# Üretim için kararlı "server" sürücüsünü kur (RTX 3060 için 535 veya 550 uygundur)
sudo apt-get install -y nvidia-driver-535-server

# Sürücünün yüklenmesi için REBOOT ŞART
sudo reboot
```

*(Yeniden başlattıktan sonra `nvidia-smi` komutu ile sürücünün çalıştığını doğrulayın)*

---

## 🐳 BÖLÜM 4: Docker ve NVIDIA Container Toolkit

Yapay zeka konteynerlerinin GPU'ya erişebilmesi için bu adım zorunludur.

### 4.1. Docker Kurulumu
```bash
# Resmi Docker kurulum scripti
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Mevcut kullanıcıyı docker grubuna ekle (sudo'suz docker için)
sudo usermod -aG docker $USER
```
*(Bu aşamada oturumu kapatıp açmanız (logout/login) gerekir)*

### 4.2. NVIDIA Container Toolkit
```bash
# Depoyu ekle
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Docker'ı yapılandır
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### 4.3. Nihai Doğrulama
Aşağıdaki komut hata vermeden GPU bilgilerini göstermelidir:
```bash
docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
```

---

## 🚀 BÖLÜM 5: Sentiric AI Studio Kurulumu

```bash
# 1. Repoyu çek
git clone https://github.com/sentiric/sentiric-ai-studio.git
cd sentiric-ai-studio

# 2. Yapılandırma
cp .env.example .env
# .env dosyasını düzenle (Gerekirse)

# 3. Başlat
make prod
```
