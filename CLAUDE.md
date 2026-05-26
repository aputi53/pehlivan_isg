# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PehlivanİSG** — Flutter tabanlı İş Sağlığı ve Güvenliği (İSG) yönetim uygulaması. Birincil hedef Android (API 36, arm64), ayrıca Windows ve Web desteği mevcut.

## Commands

```bash
# Bağlı cihazları listele
flutter devices

# Cihaza yükleyip çalıştır (debug)
flutter run -d <device-id>

# Debug APK derle
flutter build apk --debug

# Release APK derle
flutter build apk --release

# Statik analiz (hata kontrolü)
flutter analyze

# Paketleri güncelle
flutter pub get
```

Test altyapısı henüz kurulmamıştır; `flutter test` çalıştırılabilir ancak anlamlı test dosyası yoktur.

## Environment

`assets/.env` dosyasında API anahtarı bulunur (git'e takip edilir, `.gitignore`'da değil):

```
GEMINI_API_KEY=...
```

`flutter_dotenv` paketi bu dosyayı `main()` içinde `await dotenv.load(fileName: ".env")` ile yükler. `pubspec.yaml`'da `assets:` listesine `.env` eklenmiş olması gerekir.

## Architecture

```
lib/
├── main.dart                    # Giriş noktası; PehlivanISGApp, AppLockWrapper sarmalayıcı
├── services/
│   ├── database_service.dart    # SQLite (sqflite) — tüm kalıcı veri buradan geçer
│   └── biometric_service.dart   # PIN + biyometrik doğrulama; singleton
├── screens/
│   ├── home_screen.dart         # Ana ekran; modül kartları
│   ├── saha_denetim_screen.dart # Saha Denetim modülü (ana aktif ekran)
│   └── security/                # AppLockWrapper, LockScreen, PIN/biyometrik ayarları
├── pages/
│   ├── gorsel_rapor_page.dart   # Görsel rapor listesi + AI analiz + PDF/paylaşım
│   ├── raporlar_page.dart       # Raporlar modülü: denetim özeti + tüm görsel raporlar
│   ├── denetimler_page.dart     # Placeholder (statik veri)
│   ├── profil_page.dart         # Profil görüntüleme
│   ├── edit_profile_page.dart   # Profil düzenleme
│   └── ayarlar_page.dart        # Ayarlar; güvenlik, bildirimler, yasal
└── widgets/
    ├── app_drawer.dart          # Yan menü; profil verisini FlutterSecureStorage'dan okur
    └── belgeler_widget.dart     # Firma bağlantılı belge yönetimi widget'ı
```

## Data Flow

**SQLite şeması** (`DatabaseService`):
- `gruplar` → `firmalar` (grupId FK) → `notlar`, `gorsel_raporlar`, `belgeler` (firmaId FK)
- Tüm FK'larda `ON DELETE CASCADE` aktif
- `DatabaseService` static metodlarla çalışır, doğrudan import edilip kullanılır

**Güvenlik katmanı:**
- `AppLockWrapper` (main.dart → home) tüm içeriği sarar
- PIN ve biyometrik durum `BiometricService` singleton'ından okunur
- 30 saniye arka planda kalınca uygulama otomatik kilitlenir
- Profil verisi (isim, fotoğraf vb.) `FlutterSecureStorage` ile şifreli saklanır; SQLite'a yazılmaz

**Saha Denetim veri modeli:**
- `saha_denetim_screen.dart` state'i `List<Map<String, dynamic>>` tutar; her map DB'den yüklenen grup/firma/not hiyerarşisini taşır
- `FirmaNot` sınıfı `saha_denetim_screen.dart` içinde tanımlıdır (`id` alanı DB ID'sidir)
- `GorselRapor` modeli `gorsel_rapor_page.dart` içinde tanımlıdır

**AI Analiz:**
- `gorsel_rapor_page.dart` → `RaporOlusturPage` → Gemini 1.5 Flash (`google_generative_ai`)
- Fotoğraflar `DataPart("image/jpeg", bytes)` olarak gönderilir

## Key Packages

| Paket | Kullanım |
|---|---|
| `sqflite` + `path` | Yerel veritabanı |
| `flutter_secure_storage` | PIN, biyometrik tercihi, profil verisi |
| `local_auth` | Parmak izi / yüz tanıma |
| `google_generative_ai` | Gemini AI görsel analiz |
| `pdf` + `printing` | PDF üretimi ve yazdırma |
| `share_plus` | `Share.shareXFiles([XFile(path)])` — v10 API'si |
| `image_picker` | Kamera / galeri |
| `flutter_dotenv` | `.env` dosyası okuma |

## Conventions

- Renk paleti: arka plan `0xFF0D1117`, kart `0xFF161B22`, vurgu `Colors.amber` / `0xFFE8B84B`
- `withOpacity()` yerine `.withValues(alpha: x)` kullanılır (deprecation uyarısı)
- `share_plus` v10'da `Share.shareXFiles(...)` kullanılır (`SharePlus.instance` v11+ API'sidir)
- Türkçe büyük harf dönüşümünde `toUpperCase()` yerine manuel karakter eşlemesi (`i→İ`, `ı→I`) uygulanır
