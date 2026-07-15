#include <SPI.h>
#include <mcp_can.h>

const int SPI_CS_PIN = 10; 
MCP_CAN CAN(SPI_CS_PIN);

unsigned long lastSendTime = 0;
int currentSpeed = 0;
bool accelerating = true;

// Fuzzing tespiti için sayaç
int unknownPacketCount = 0; 
unsigned long lastFuzzTime = 0;

void setup() {
    Serial.begin(115200);
    while (CAN_OK != CAN.begin(MCP_ANY, CAN_500KBPS, MCP_16MHZ)) {
        Serial.println("MCP2515 Baslatilamadi!");
        delay(1000);
    }
    Serial.println("Dinamik ECU Aktif. Fuzzing Bekleniyor...");
    CAN.setMode(MCP_NORMAL);
}

void loop() {
    unsigned long currentMillis = millis();

    // --- 1. DİNAMİK NORMAL TRAFİK (Overfitting'i Önlemek İçin) ---
    // Her 100ms'de bir paket gönder
    if (currentMillis - lastSendTime >= 100) {
        lastSendTime = currentMillis;

        // Gerçekçi Hız Simülasyonu (0'dan 120'ye çıkar, sonra geri düşer)
        if (accelerating) {
            currentSpeed += random(1, 4); // 1 ile 3 arası rastgele ivmelenme
            if (currentSpeed >= 120) accelerating = false;
        } else {
            currentSpeed -= random(1, 4); // Yavaşlama
            if (currentSpeed <= 0) accelerating = true;
        }

        // Paketi Gönder (Dinamik Hız Verisi)
        unsigned char speedData[8] = {0x00, (byte)currentSpeed, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}; 
        CAN.sendMsgBuf(0x101, 0, 8, speedData);
        
        // Motor Devri (Sabit Bıraktım, istersen bunu da dinamik yapabilirsin)
        unsigned char rpmData[8] = {0x0A, 0xBC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}; 
        CAN.sendMsgBuf(0x100, 0, 8, rpmData);
    }

    // --- 2. FUZZING TESPİTİ VE ÇÖKME SİMÜLASYONU (Watchdog) ---
    if (CAN_MSGAVAIL == CAN.checkReceive()) {
        long unsigned int rxId;
        unsigned char len = 0;
        unsigned char rxBuf[8];
        CAN.readMsgBuf(&rxId, &len, rxBuf);

        // Sistemin tanımadığı (100 ve 101 harici) bir ID gelirse
        if (rxId != 0x100 && rxId != 0x101) {
            unknownPacketCount++;
            lastFuzzTime = currentMillis;

            // Eğer sistem çok kısa sürede çok fazla tanımlanmayan veri alırsa (Fuzzing)
            if (unknownPacketCount > 500) {
                Serial.println("[💥 FATAL ERROR] Tanımsız Veri Yağmuru! Bellek Taştı, ECU Çöktü!");
                while(1); // Arduino'yu kalıcı olarak kilitler (Gerçek bir Hard-Fault simülasyonu)
            }
        }
    }

    // Eğer 1 saniye boyunca fuzzing paketi gelmezse sayacı temizle (Sistemi rahatlat)
    if (currentMillis - lastFuzzTime > 1000) {
        unknownPacketCount = 0;
    }
}