# PehlivanİSG Mobil — Geliştirme Yol Haritası
## (Bu dosyayı Claude'a göster → kaldığın yerden devam et)

---

## PROJE BİLGİLERİ

| | |
|---|---|
| **Uygulama Adı** | PehlivanİSG Mobil |
| **Platform** | Flutter (Android) |
| **Proje Klasörü** | `C:\Users\abdur\AndroidStudioProjects\pehlivan_isg` |
| **GitHub** | aputi53/pehlivan_isg |
| **Veritabanı** | SQLite (sqflite) |
| **Bulut Sync** | Firebase Firestore (`pehlivan_sync` koleksiyonu) |
| **Bağlı PC Uygulama** | PehlivanİSG Masaüstü (aputi53/isg-risk-analiz) |
| **DB Versiyon** | v10 |

---

## MEVCUT DOSYA YAPISI

```
lib/
├── main.dart                    ← Uygulama girişi, Firebase init
├── firebase_options.dart        ← Firebase config
├── pages/
│   ├── firmalar_page.dart       ← Firma listesi + Firebase sync + çoklu seçim silme
│   ├── firma_detay_page.dart    ← Firma detay (notlar, belgeler, görseller, çalışanlar)
│   ├── aksiyon_page.dart        ← Aksiyonlar takibi
│   ├── ayarlar_page.dart        ← Uygulama ayarları
│   ├── ai_asistan_page.dart     ← AI asistan
│   ├── calisanlar_page.dart     ← Çalışan yönetimi
│   ├── egitim_katilim_page.dart ← Eğitim katılım kayıtları
│   ├── gorsel_rapor_page.dart   ← Görsel raporlar
│   ├── personel_havuzu_page.dart← Uzman & Hekim havuzu
│   ├── edit_profile_page.dart   ← Profil düzenleme
│   └── ziyaret_planlama_page.dart ← Ziyaret planlama (YENİ)
├── screens/
│   ├── home_screen.dart         ← Ana ekran (alt nav)
│   ├── saha_denetim_screen.dart ← Saha denetim
│   └── security/
│       └── change_pin_screen.dart
├── services/
│   ├── database_service.dart    ← SQLite CRUD + Firebase sync
│   ├── backup_service.dart      ← Yedekleme
│   ├── biometric_service.dart   ← Biyometrik
│   └── theme_service.dart       ← Tema yönetimi
└── widgets/
    └── app_empty_state.dart     ← Boş durum widget
```

---

## TAMAMLANANLAR

| Modül | Açıklama | Tarih |
|-------|----------|-------|
| **Firmalar** | CRUD, gruplar, arama, sıralama | — |
| **Firmalar** | Firebase sync (PC → Mobil), bulut ikonu | — |
| **Firmalar** | ISG-Katip Excel import | — |
| **Firmalar** | CSV import | — |
| **Firmalar** | Çoklu seçimli silme (uzun bas → seçim modu) | 28 Haz |
| **Firmalar** | Sync mesajı: "X yeni, Y güncellendi, Z atlandı" detaylı | 28 Haz |
| **Firma Detay** | Notlar (fotoğraflı), belgeler, görseller | — |
| **Firma Detay** | Çalışanlar listesi | — |
| **Firma Detay** | Aksiyonlar | — |
| **Firma Detay** | Sertifikalar | — |
| **Firma Detay** | Eğitim katılımı | — |
| **Aksiyonlar** | Tüm firmalara ait aksiyon listesi, tamamla/aç | — |
| **AI Asistan** | Gemini tabanlı ISG asistan | — |
| **Saha Denetim** | Checklist bazlı denetim formu | — |
| **Personel Havuzu** | Uzman & Hekim kayıt listesi | — |
| **Ayarlar** | Biyometrik, tema, yedekleme/geri yükleme | — |
| **Ziyaret Planlama** | Firebase'den gruplar + aylık plan yükleme | 28 Haz |
| **DB v10** | ziyaret_sync_log tablosu migration fix (v8 eksik tablo hatası çözüldü) | 28 Haz |
| **DB v9** | firmalar: adres kolonu eklendi | — |

---

## AKTİF SORUNLAR

| Sorun | Açıklama | Öncelik |
|-------|----------|---------|
| **Firma sayı tutarsızlığı** | 131 sync ediliyor, listede 125 görünüyor. getAllFirmalar sorgusu incelenmeli | Yüksek |

---

## KISA VADELİ (Sıradaki)

- [ ] **Firma sayı sorunu çözümü** — `getAllFirmalar` DB sorgusu debug + olası duplicate/NULL kayıt temizliği
- [ ] **Ziyaret Planlama** — Takvim görünümü (PC'deki gibi aylık grid)
- [ ] **Ziyaret Planlama** — Gruba atanmış firmaları görüntüleme
- [ ] **Push Bildirimleri** — Aksiyon son tarih hatırlatıcısı (FCM)

---

## ORTA VADELİ

- [ ] **Risk Analizi Görüntüleme** — PC'den sync edilen risk analizlerini mobilde görüntüle (read-only)
- [ ] **Eğitim Planı Sync** — PC yıllık eğitim planını mobilde göster
- [ ] **Muayene Formu** — İşe giriş / periyodik hekim muayene kaydı
- [ ] **Offline Mod** — İnternet olmadan çalışma, bağlantı gelince sync
- [ ] **Firma Haritası** — Google Maps entegrasyonu, firma pinleri
- [ ] **Dashboard** — Firma bazlı KPI kartları (açık aksiyon, eksik belge, yaklaşan sertifika)

---

## UZUN VADELİ

- [ ] **İki yönlü Sync** — Mobilde girilen veri PC'ye de yansısın (şu an tek yön: PC → Mobil)
- [ ] **iOS desteği** — Flutter build yapılandırması
- [ ] **QR Saha Bildirimi** — QR okuyucu ile firma/personel kaydı
- [ ] **KKD Zimmet** — Mobil zimmet fişi imzalama
- [ ] **Fotoğraf AI** — Saha fotoğrafından tehlike tespiti (Gemini Vision)

---

## FIREBASE YAPILANMASI

```
Firestore Koleksiyonu: pehlivan_sync
├── firmalar         ← PC Firmalar → Mobil (PATCH/GET)
├── gruplar          ← PC Ziyaret Grupları → Mobil
└── plan_YYYY_MM     ← PC Aylık Plan → Mobil
```

**Sync Yönü:** Şu an yalnızca PC → Mobil (tek yön)

---

## DB VERSİYON GEÇMİŞİ

| Versiyon | Değişiklik |
|----------|------------|
| v1 | Temel: gruplar, firmalar, notlar, görsel_raporlar, belgeler |
| v2 | firmalar: ziyaretTarihi, belgeler: gecerlilikTarihi |
| v3 | firmalar: egitim/muayene/evrak geçerlilik yılları; calisanlar, calisan_belgeleri |
| v4 | belgeler: calisanId |
| v5 | aksiyonlar |
| v6 | sertifikalar, egitim_katilim |
| v7 | firmalar: sgkNo, tehlikeSinifi, uzman/hekim alanları; sertifikalar genişletildi; personel_havuzu |
| v8 | ziyaret_sync_log (migration sırası hatası — v9'a kadar bazı cihazlarda eksikti) |
| v9 | firmalar: adres |
| v10 | ziyaret_sync_log CREATE IF NOT EXISTS (v8 migration bug fix) |

---

## CLAUDE'A GÖSTER — BU DOSYAYI VER, DEVAM ET

**Komut:** "Mobil yol haritasını oku, kaldığımız yerden devam et."

Bu dosyayı gösterdiğinde Claude şunları bilecek:
1. Mobil projenin tam dosya yapısı
2. Tamamlananlar ve açık sorunlar
3. Firebase sync mimarisi
4. DB versiyon geçmişi
5. Bir sonraki oturumda nereden başlanacağı

---

*Son güncelleme: 28 Haziran 2026 (1. Mobil Roadmap — v10 DB — Ziyaret Planlama, Firebase sync, çoklu silme)*
*Hazırlayan: Claude Sonnet 4.6 — PehlivanİSG Geliştirme Oturumu*
