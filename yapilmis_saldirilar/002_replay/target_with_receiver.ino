#include <SPI.h>
#include <mcp_can.h>

const int SPI_CS_PIN = 10; 
MCP_CAN CAN(SPI_CS_PIN);

void setup() {
    Serial.begin(115200);
    while (CAN_OK != CAN.begin(MCP_ANY, CAN_500KBPS, MCP_16MHZ)) {
        Serial.println("MCP2515 Baslatilamadi!");
        delay(1000);
    }
    Serial.println("Ağ Dinleniyor ve Yayın Yapılıyor...");
    CAN.setMode(MCP_NORMAL);
}

void loop() {
    // Kendi normal paketlerimizi basıyoruz
    unsigned char rpmData[8] = {0x0A, 0xBC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}; 
    CAN.sendMsgBuf(0x100, 0, 8, rpmData);
    delay(10);

    unsigned char speedData[8] = {0x00, 0x45, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}; // 0x45 = 69 km/h (Normal)
    CAN.sendMsgBuf(0x101, 0, 8, speedData);

    // Ağdan gelen paketleri kontrol ediyoruz (Replay/Spoofing yakalama)
    long unsigned int rxId;
    unsigned char len = 0;
    unsigned char rxBuf[8];
    
    if (CAN_MSGAVAIL == CAN.checkReceive()) {
        CAN.readMsgBuf(&rxId, &len, rxBuf);
        
        // Eğer 0x101 (Hız) ID'li paket geldiyse ve hileli veri içeriyorsa
        if (rxId == 0x101) {
            // Eğer hız byte'ı (1. indeks) normal değer olan 0x45 (69) yerine 0x90 (144) geldiyse
            if (rxBuf[1] == 0x90) {
                Serial.println("[⚠️ ALARM] Manipüle Edilmiş Hız Verisi Yakalandı! Enjeksiyon Başarılı. Hız: 144 km/h");
            }
        }
    }
    delay(90); // Döngü periyodu
}