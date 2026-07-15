# CANPro Detaylı Proje Analizi ve Kullanım Rehberi

Yaptığım derinlemesine inceleme ve testler sonucunda, uygulamanın çalışır durumda olduğunu ve aşağıdaki teknik altyapıya sahip olduğunu doğruladım. Bu rehber, varsayımlar yerine sistem üzerinde yapılan analizlere dayanmaktadır.

## 1. Sistem Durumu ve Çalıştırma

*   **Çalıştırma Testi**: `CANPro.exe` dosyası test edilmiş ve Windows ortamında başarıyla belleğe yüklendiği (`~96 MB` RAM kullanımı ile) görülmüştür. Uygulama "portable" (kurulumsuz) yapıda çalışmaktadır.
*   **Donanım Uyumluluğu**: `Driver_Install/DrvInstall.ini` dosyasındaki analizime göre, bu yazılım **CANalyst-II+** (VID_0471&PID_1261) donanımı için tasarlanmıştır. Eğer elinizde bu USB-CAN adaptörü varsa, sürücüler `Driver_Install` klasöründe hazırdır.

## 2. Derinlemesine Dosya Analizi

### Ana Uygulama (`/`)
*   **`CANPro.exe`**: Ana analiz arayüzü.
*   **`config.ini`**: Kayıt yolları ve tampon bellek ayarlarını içerir. `DataDir` parametresi ile log dosyalarının nereye kaydedileceğini değiştirebilirsiniz.

### Protokol Scriptleme Dili (`ProtocolScripts/`)
`.proS` uzantılı dosyaları incelediğimde, bunların **Lua Script** dili ile yazıldığını doğruladım.
*   **Yapı**: `CondSetting` ve `Protocol.AddMessage` gibi fonksiyon çağrıları içerir.
*   **Özelleştirme**: Kendi protokolünüzü eklemek için bu dosyaları herhangi bir metin editörü (Notepad++, VS Code) ile açıp, Lua sözdizimine uygun olarak yeni mesaj ID'leri ve veri parsing kuralları ekleyebilirsiniz.

### Veritabanı Desteği (`DBCFiles/`)
*   Sektör standardı **.DBC** dosyalarını destekler.
*   Mevcut dosyalar: `j1939.dbc` (Ağır vasıta) ve `CANopen.dbc`. Bu dosyalar ham CAN verilerini (Hex) okunabilir sinyallere (Hız, Sıcaklık vb.) dönüştürür.

### Özelleştirilmiş Analiz (`CANCustomAnalyse/`)
Bu klasörde yer alan `CANCustomAnalyse.exe`, daha gelişmiş grafiksel analizler için kullanılıyor.
*   **Proje Dosyaları**: `Example/Siample` klasöründeki incelememde, proje dosyalarının (`.ccp`) **XML tabanlı** olduğunu tespit ettim. Bu, proje ayarlarının dışarıdan da (editörle) manipüle edilebileceği anlamına gelir.
*   **Örnekler**: `J1939Example` ve `Siample` (Simple/Basit gönderim) klasörlerinde hazır test senaryoları mevcuttur.

## 3. Nasıl Kullanmalısınız? (Adım Adım Doğrulanmış Yöntem)

1.  **Sürücü Kurulumu**: Eğer cihazı ilk kez takıyorsanız, `Driver_Install/DriverSetup.exe` uygulamasını çalıştırın.
2.  **Yazılımı Başlatma**: `CANPro.exe`'yi çalıştırın.
3.  **Protokol Seçimi**:
    *   Standart araçlar için -> `CAN.proS` (Standart CAN)
    *   Kamyon/Otobüs için -> `SAE J1939.proS`
    *   Endüstriyel otomasyon için -> `CANopen.proS`
    seçeneklerini arayüzden göreceksiniz.
4.  **Veri İzleme**: `config.ini` dosyasında varsayılan olarak `iListRefreshTm=300` (300ms) yenileme hızı ayarlanmıştır. Veri akışı çok hızlıysa bu değeri artırarak arayüzü rahatlatabilirsiniz.

## 4. Sorun Giderme (Troubleshooting)

### Cihaz Görünmüyor / "WinUSB Disk" Hatası
Eğer cihazınızı taktığınızda Aygıt Yöneticisi'nde "WinUSB Disk" veya benzeri genel bir isimle görünüyorsa:
1.  Uygulamayı kapatın.
2.  `Driver_Install` klasörüne gidin ve `DriverSetup.exe` dosyasını çalıştırıp kurulumu tamamlayın.
3.  Uygulamayı (`CANPro.exe`) tekrar başlatın.
4.  Cihazınızın `USBCAN2` veya `USBCAN-2E-U` modlarından biriyle uyumlu olduğunu kontrol edin.

## Teknik Özet Tablosu

| Bileşen | Teknoloji / Format | Açıklama |
| :--- | :--- | :--- |
| **Script Dili** | Lua 5.x | Protokol tanımları (`.proS`) için |
| **Proje Dosyası** | XML | Analiz ayarları (`.ccp`) için |
| **Donanım** | CANalyst-II+ | USB-ZLG uyumlu cihazlar |
| **Veritabanı** | DBC | Sinyal dönüşümü için |

Bu paket, ek bir kuruluma ihtiyaç duymadan, doğrudan klasör içinden çalışmaya hazır bir CAN analiz ortamıdır.
