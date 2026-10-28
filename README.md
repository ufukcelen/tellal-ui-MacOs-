# Tellal macOS App (v0.0.1)

YouTube ve Kick yayınları için yayın takvimi, ekip içi canlı sohbet ve After Effects render otomasyonunu bir araya getiren yerel macOS SwiftUI uygulaması.

> **Kanal Odakları:**  
> 📺 **Uykusuz Tosba** (`/uykusuztosba`)  
> 📻 **Radio Mocas** (`/radiomocas`)

---

## 🚀 Özellikler

- 📅 **Yayın Takvimi (Schedule)**:
  - Canlı yayınları planlama, durum takibi (Beklemede, Duyuruldu ✅, İptal ❌).
  - Firebase Realtime Database ve Ntfy ile bulut eşitlemesi.
  - Google Calendar senkronizasyonu.
- 💬 **Ekip Sohbeti (Live Chat)**:
  - Ekip üyeleri (Ufuk, Yiğit, Cem) arasında anlık mesajlaşma.
  - Karşı tarafın Mac ekranına anlık sesli bildirim gönderme (Ntfy altyapısı).
- 🐢 **Uykusuz Tosba Otomasyonları**:
  - Canlı Maç Sohbetleri ve Maç Sonu duyuru afişleri.
  - Lig seçimi (Süper Lig, Şampiyonlar Ligi, Avrupa Ligi, Premier Lig vb.) ve dinamik arka planlar.
  - Otomatik YouTube & Kick SEO metni üretimi.
  - Tek tıkla Adobe After Effects `aerender` entegrasyonu.
- 📻 **Radio Mocas Otomasyonları**:
  - Filtresiz Memleket Havası ve Albert & Cem duyuru motoru.
- ⚡ **Terminal & Render Konsolu**:
  - Arka planda çalışan render süreçlerini (`PROGRESS: %xx`) ve Python scriptlerini canlı izleme.
- ⚙️ **Ayarlar & Ekip**:
  - Aktif kullanıcı profili seçimi, TellalCLI dizin yönetimi ve servis sağlık kontrolü.

---

## 🛠️ Kurulum & Gereksinimler

- **macOS**: Sonoma (14.0) veya üzeri (macOS 15+ / macOS 26+ önerilir)
- **Xcode**: 16.0+
- **Backend / CLI**: [ufukcelen/tellal](https://github.com/ufukcelen/tellal)
  - Otomasyon şablonları ve After Effects projeleri için `TellalCLI` dizini kullanılır.
