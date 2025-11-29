# 🧠 Sentiric AI Studio

**Sentiric AI Studio**, yerel ortamda (On-Premise) çalışan, GPU hızlandırmalı, tam kapsamlı bir Üretken Yapay Zeka (Generative AI) platformudur.

Bu depo, tüm mikroservisleri (LLM, STT, TTS, RAG, Veritabanları) tek bir `docker-compose` yapısı altında toplar ve yönetir.

![System Status](https://img.shields.io/badge/System-Production%20Ready-green)
![GPU Support](https://img.shields.io/badge/GPU-NVIDIA%20CUDA-76b900)

## 🚀 Özellikler

*   **Merkezi Orkestrasyon:** Tek komutla tüm AI altyapısını ayağa kaldırır.
*   **Open WebUI Entegrasyonu:** ChatGPT benzeri modern bir arayüz ile gelir.
*   **Tam OpenAI Uyumluluğu:** LLM, STT ve TTS servisleri OpenAI API standardını destekler.
*   **RAG (Retrieval-Augmented Generation):** Qdrant vektör veritabanı ile doküman tabanlı sohbet.
*   **Yüksek Performans:**
    *   **LLM:** `llama.cpp` tabanlı, GPU/CPU hibrit motor.
    *   **STT:** `whisper.cpp` tabanlı, gerçek zamanlı ses tanıma.
    *   **TTS:** `coqui-xtts` tabanlı, duygu ve klonlama destekli ses sentezleme.

---

## 🛠️ Kurulum ve Başlatma

### Ön Gereksinimler
*   Docker & Docker Compose
*   **Önerilen:** NVIDIA GPU + NVIDIA Container Toolkit (Sürücüler kurulu olmalı)
*   En az 16GB RAM (GPU yoksa) veya 8GB VRAM (GPU varsa).

### 1. Hazırlık
Repoyu klonlayın ve yapılandırma dosyasını oluşturun:

```bash
git clone https://github.com/sentiric/sentiric-ai-studio.git
cd sentiric-ai-studio

# Örnek .env dosyasını kopyalayın
cp .env.example .env
```

### 2. Başlatma (Makefile ile)

Geliştirme veya Üretim modunda başlatmak için `Makefile` komutlarını kullanın:

```bash
# Geliştirme Modu (İmajları yerel Dockerfile'lardan derler)
make up

# Üretim Modu (Hazır imajları ghcr.io'dan çeker - Daha Hızlı)
make prod

# Logları İzlemek İçin
make logs

# Durdurmak İçin
make down
```

---

## 📡 Servis Haritası ve Portlar

Sistem ayağa kalktığında aşağıdaki adreslerden servislere erişebilirsiniz:

| Servis | URL / Port | Açıklama |
| :--- | :--- | :--- |
| **Open WebUI** | `http://localhost:3000` | **Ana Kullanıcı Arayüzü** (Sohbet, RAG, Ayarlar) |
| **LLM Service** | `http://localhost:16070` | Metin Üretim Motoru (Llama/Gemma) |
| **STT Service** | `http://localhost:15030` | Ses Tanıma Motoru (Whisper) |
| **TTS Service** | `http://localhost:14030` | Ses Sentezleme Motoru (Coqui) |
| **RAG Query** | `http://localhost:17020` | Vektör Arama Servisi |
| **Qdrant DB** | `http://localhost:6333` | Vektör Veritabanı Paneli |

---

## 🧩 Open WebUI Entegrasyon Detayları

Open WebUI, Sentiric servislerini otomatik olarak tanıyacak şekilde yapılandırılmıştır.

### 1. Metinden Sese (TTS) Ses Seçimi

Sentiric TTS servisi, OpenAI API standardını destekler ancak kendi özel yüksek kaliteli ses modellerini kullanır. Open WebUI ayarlarında "Voice" kısmına aşağıdaki değerleri girebilirsiniz:

| Dosya Adı (Önerilen) | OpenAI Eşdeğeri (Fallback) | Tarz |
| :--- | :--- | :--- |
| **Alloy** | `F_Narrator_Linda` | **Varsayılan Kadın** (Net, Profesyonel Anlatım) |
| **Echo** | `M_News_Bill` | Varsayılan Erkek (Haberci) |
| **Shimmer** | `F_Calm_Ana` | Sakin ve Yumuşak Kadın |
| **Onyx** | `M_Deep_Damien` | Derin ve Otoriter Erkek |
| **Nova** | `F_Assistant_Judy` | Enerjik ve Hızlı Asistan |
| **Fable** | `M_Story_Telling` | Vurgulu Hikaye Anlatıcısı |


> **Not:** Sistemde `M_Default` gibi başka ses dosyaları da mevcuttur. Bunları kullanmak için Open WebUI ses ayarına dosya adını manuel yazabilirsiniz.

### 2. Konuşmadan Metne (STT)

*   Sistem, MP3, WebM ve WAV formatlarını otomatik olarak tanır ve işler (FFmpeg entegreli).
*   Open WebUI ayarlarında:
    *   **STT Engine:** `OpenAI`
    *   **API Base URL:** `http://stt-whisper-service:15030/v1`
    *   **Auto-Send:** *Kapalı* (Önerilen: Konuştuğunuzu önce metin kutusunda görün).

---

## ⚠️ Sorun Giderme

### 1. Sesli yanıtta `(static)` yazıyor veya ses gelmiyor
*   Open WebUI **Ses Ayarları**'na gidin.
*   **Text-to-Speech Engine**'in `OpenAI` olduğundan emin olun.
*   **API Base URL**'in `http://tts-coqui-service:14030/v1` olduğunu doğrulayın (localhost yazmayın, docker içindeyiz).

### 2. Mikrofon `[static]` yazıyor
*   Tarayıcı mikrofon iznini kontrol edin.
*   STT servisinin loglarına bakın: `docker logs stt-whisper-service`. "FFmpeg conversion success" yazısını görmelisiniz.

### 3. GPU Bellek Hatası (OOM)
*   Eğer 4GB-6GB VRAM'e sahipseniz, `.env` dosyasında `LLM_LLAMA_SERVICE_GPU_LAYERS` değerini düşürün (örn: 16 veya 20).
*   `TTS_COQUI_SERVICE` için `CUDA_VISIBLE_DEVICES` ayarını kontrol edin.

---

## 📜 Lisans

Bu proje **Sentiric Cloud** altyapısının bir parçasıdır.
Lisans: `AGPL-3.0`