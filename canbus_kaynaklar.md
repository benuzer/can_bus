# Açık Kaynak CAN Sözlükleri (DBC ve ID Havuzları)

1. **[Comma.ai OpenDBC](https://github.com/commaai/opendbc)**
   - Honda, Toyota, VW gibi onlarca markanın şifresi çözülmüş devasa CAN DBC (sözlük) kütüphanesidir. Aktif olarak güncellenmektedir.

2. **[Awesome Automotive CAN ID](https://github.com/iDoka/awesome-automotive-can-id)**
   - İnternetteki farklı araç markalarına ait sızdırılmış tüm CAN ID'lerini ve dökümanları tek çatı altında toplayan dev fihristtir.

3. **[Open-CAN-DB](https://github.com/equinox311/open-can-db)**
   - Özellikle Subaru ve Mini Cooper araçların CAN ağlarının şifrelerini barındıran veri tabanıdır.

4. **[Mazda 6th Gen CAN DBC](https://github.com/berumiya/CAN_DBC_6thGenMazda)**
   - 6. nesil Mazda araçların şifrelerini çözmeye adanmış spesifik ve detaylı bir veri tabanıdır.

---

# Hack ve Analiz Araçları (Yazılımlar)

5. **[SavvyCAN](https://github.com/collin80/SavvyCAN)**
   - CAN-Bus dünyasının en güçlü ücretsiz analiz yazılımıdır: DBC yükleme, grafik çizdirme, tersine mühendislik, fuzzing ve replay saldırıları tek programda yapılır. Aktif olarak güncellenmektedir (Qt6 desteği ekleniyor).

6. **[Comma Cabana](https://github.com/commaai/cabana)**
   - Kaydettiğin ham CAN verilerini (logları) tarayıcıya yükleyip grafiklerini çizdirerek şifreleri kırmanı sağlayan görsel analiz aracıdır.

7. **[cantools](https://github.com/cantools/cantools)**
   - Python'da DBC dosyalarını okuyup CAN mesajlarını otomatik encode/decode eden endüstri standardı kütüphanedir. `pip install cantools` ile kurulur.

8. **[Canmatrix](https://github.com/ebroecker/canmatrix)**
   - `.arxml` veya `.kcd` gibi farklı formatlardaki veri tabanlarını, endüstri standardı olan `.dbc` formatına dönüştürmeni sağlayan araçtır.

9. **[python-can](https://github.com/hardbyte/python-can)**
   - Bilgisayarındaki donanımlarla (USB-CAN-B, Arduino, sanal CAN vb.) doğrudan Python üzerinden iletişim kurup veri okuma/yazmanı sağlayan ana kütüphanedir.

10. **[VehCANSigLyzer](https://github.com/ahlashkari/VehCANSigLyzer)**
    - Ham CAN verilerinden yapay zekanın kullanacağı "zamanlama" ve "sinyal" özelliklerini otomatik olarak çıkaran veri madenciliği aracıdır (2024).

11. **[CANalyzat0r](https://github.com/schutzwerk/CANalyzat0r)**
    - Python 3 tabanlı, modüler yapıda açık kaynak CAN güvenlik analiz aracıdır. Sniffing, fuzzing ve tersine mühendislik modülleri içerir.

12. **[ICSim - Instrument Cluster Simulator](https://github.com/zombieCraig/ICSim)**
    - Sanal bir araç gösterge paneli simülatörüdür: Hız göstergesi, sinyal lambaları ve kapı kilitleri CAN mesajlarına göre hareket eder. Donanım olmadan bilgisayardan saldırı pratiği yapılır.

---

# Siber Güvenlik Veri Setleri (2023-2026 Güncel)

13. **[CAN-MIRGU (GitHub)](https://github.com/sampathrajapaksha/CAN-MIRGU)**
    - Hareket halindeki otonom yetenekli bir elektrikli araçtan toplanan ve fiziksel saldırılar içeren en güncel (2024) gerçek dünya veri setidir.

14. **[CAN-MIRGU (UCI ML Repository)](https://archive.ics.uci.edu/dataset/1035/can-mirgu)**
    - Aynı veri setinin akademik ve resmi indirme kaynağıdır. Python ile `ucimlrepo` paketi üzerinden doğrudan yüklenebilir.

15. **[can-train-and-test (DTU Data)](https://data.dtu.dk/articles/dataset/can-train-and-test/24855731)**
    - 4 farklı araçtan (Subaru, Chevrolet) toplanan, 9 farklı saldırı tipini içeren, eğitim/test ayrımı hazır derlenmiş akademik veri setidir (2024).

16. **[ROAD Dataset (Zenodo)](https://zenodo.org/records/10444390)**
    - Oak Ridge Ulusal Laboratuvarı tarafından dinamometre üzerindeki gerçek araçtan toplanan, karmaşık ve gizli (stealthy) saldırılar içeren referans veri setidir.

17. **[SynCAN Dataset](https://github.com/etas/SynCAN)**
    - ETAS (Bosch yan kuruluşu) tarafından sinyal seviyesinde IDS benchmarkı için üretilmiş sentetik CAN veri setidir. CANShield gibi framework'lerle birlikte kullanılır.

18. **[X-CANIDS (can-ids)](https://github.com/freundma/can-ids)**
    - Basit ID tabanlı değil, doğrudan sinyal (signal-level) seviyesinde veri içeren ve karmaşık sızma testleri (fuzzing, masquerade) için kullanılan veri setidir.

19. **[Bit-Scanner Dataset](https://github.com/happy-little-zhang/Bit-Scanner)**
    - Araç içi anomali tespiti ve beyaz liste (whitelisting) çalışmaları için, hiçbir saldırı olmadan toplanmış saf ve temiz veri setidir (2023).

20. **[ACS-CAN-IDS](https://github.com/enginsubasi/acs)**
    - Akademik çalışmalarda referans gösterilen, modern araç ağlarındaki saldırı tespit sistemleri için derlenmiş güncel bir veri setidir.

21. **[CICIoV2024 (UNB)](https://www.unb.ca/cic/datasets/)**
    - Kanada Siber Güvenlik Enstitüsü (CIC) tarafından yayınlanan, araç ağlarındaki IoV (Internet of Vehicles) saldırılarını içeren 2024 tarihli kapsamlı veri setidir.

---

# Yapay Zeka Siber Güvenlik Altyapıları (Frameworks)

22. **[CANival](https://github.com/trifle19/CANival)**
    - X-CANIDS ve SynCAN veri setlerini kullanarak araçlardaki sızmaları birden fazla modelle (multimodal) tespit etmeye yarayan güncel makine öğrenmesi altyapısıdır (2024).

23. **[CANShield](https://github.com/shahriar0651/CANShield)**
    - Araç ağına yapılan saldırıları ham sinyal seviyesinde analiz edip engelleyen derin öğrenme tabanlı saldırı tespit sistemi projesidir (2023).

24. **[Internet-of-Vehicles-Code](https://github.com/a-m-s-a-l-e-h/Internet-of-Vehicles-Code)**
    - Otomotiv güvenliği, elektrikli araçlar ve otonom sürüş üzerine son yıllarda yazılmış kodları ve akademik makaleleri derleyen kaynak havuzudur.

25. **[CAN-IDSs-on-the-ROAD](https://github.com/lorenzo9uerra/CAN-IDSs-on-the-ROAD)**
    - ROAD veri seti üzerinde çeşitli IDS algoritmalarını etiketleme ve analiz etme scriptleri içeren araştırma deposudur.

---

# Topluluk ve Eğitim Kaynakları

26. **[Awesome CAN Bus](https://github.com/iDoka/awesome-canbus)**
    - CAN-Bus dünyasındaki tüm açık kaynak araçları, kütüphaneleri, donanımları ve veri setlerini derleyen devasa fihrist deposudur.

27. **[Open Garages (Web)](http://opengarages.org/index.php/Main_Page)**
    - Efsanevi "Car Hacker's Handbook" kitabının yazarının kurduğu, otomotiv hackleme araçlarını paylaşan ana topluluğun web sitesidir.

28. **[Open Garages (GitHub)](https://github.com/opengarages)**
    - Open Garages topluluğuna ait araç hackleme kod deposudur.

29. **[Waveshare USB-CAN-B Wiki](https://www.waveshare.com/wiki/USB-CAN-B)**
    - USB-CAN-B donanımının resmi dökümanı, sürücüleri ve Python örnek kodlarının indirme sayfasıdır.
