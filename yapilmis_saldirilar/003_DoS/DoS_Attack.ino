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
    Serial.println("Ağ aktif. DoS/Flood bekleniyor...");
    CAN.setMode(MCP_NORMAL);
}

void loop() {
    unsigned char data[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}; 
    
    // Paketi hatta basmaya çalışıyoruz
    byte sendStat = CAN.sendMsgBuf(0x100, 0, 8, data);
    
    // CAN_OK (0) dönmezse, ağ %100 meşgul demektir (TX Buffer Dolu)
    if(sendStat != CAN_OK) {
        Serial.println("[⚠️ KRİTİK] DoS SALDIRISI / FLOOD TESPİT EDİLDİ! Ağ bloke oldu.");
    }
    
    delay(50); // Hızlı periyot
}