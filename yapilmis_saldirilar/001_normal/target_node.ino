#include <SPI.h>
#include <mcp_can.h>

// SparkFun CAN-Bus Shield standart olarak CS (Chip Select) pini olarak D10 kullanır.
// Eğer özel bir shield veya kablolama varsa D9 veya D10 olduğunu doğrulayın.
const int SPI_CS_PIN = 10; 
MCP_CAN CAN(SPI_CS_PIN);

void setup() {
    Serial.begin(115200);

    // MCP2515 modülünü 500kbps hızında ve 16MHz kristal osilatör ayarıyla başlatıyoruz.
    // Sparkfun shield'lar genellikle 16MHz kristal kullanır.
    while (CAN_OK != CAN.begin(MCP_ANY, CAN_500KBPS, MCP_16MHZ)) {
        Serial.println("MCP2515 Baslatilamadi! Baglantilari kontrol edin...");
        delay(1000);
    }
    Serial.println("MCP2515 Basariyla Baslatildi. CAN Hizi: 500kbps");
    
    // Modülü normal çalışma moduna alıyoruz
    CAN.setMode(MCP_NORMAL);
}

void loop() {
    // 1. Paket Simülasyonu: Motor Devri (ID: 0x100, Uzunluk: 8 Byte)
    unsigned char rpmData[8] = {0x0A, 0xBC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}; // Örnek devir verisi
    CAN.sendMsgBuf(0x100, 0, 8, rpmData);
    
    delay(50); // Paketler arası küçük gecikme

    // 2. Paket Simülasyonu: Araç Hızı (ID: 0x101, Uzunluk: 8 Byte)
    unsigned char speedData[8] = {0x00, 0x45, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}; // Örnek hız verisi (69 km/h)
    CAN.sendMsgBuf(0x101, 0, 8, speedData);

    delay(100); // Toplam periyot döngüsü (~10 Hz frekans)
}