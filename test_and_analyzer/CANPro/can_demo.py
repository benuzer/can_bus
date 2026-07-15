import ctypes
import struct
import time
import threading
import sys
import os

# --- Configuration ---
DLL_PATH = os.path.join(os.getcwd(), "ControlCAN.dll")
DEV_PRO = 21  # USBCAN-2E-U
DEV_IND = 0   # Device Index 0
CAN_ECU = 0   # Channel 0 for ECU
CAN_SCANNER = 1 # Channel 1 for Scanner
BAUD_RATE = 0x060003 # 500Kbps for USBCAN-2E-U (Check doc if differs)
# 500k timing0=0x00, timing1=0x1C? No, Waveshare usually has specific hex codes
# For USBCAN-2E-U: 500k is often configurable. Let's try standard timing or the one from config.
# If this fails, we might need to look up the exact timing code in the manual or cantype.ini.
# Using a generic approach or standard 500k: 
# Timing0=0x00, Timing1=0x1C (common)
# But USBCAN-2E-U often takes specific flags. Let's assume the library handles it or use the one from config.ini if possible.
# Actually, the user says 250k worked properly.
# 250k: Timing0=0x01, Timing1=0x1C

class VCI_INIT_CONFIG(ctypes.Structure):
    _fields_ = [("AccCode", ctypes.c_uint),
                ("AccMask", ctypes.c_uint),
                ("Reserved", ctypes.c_uint),
                ("Filter", ctypes.c_ubyte),
                ("Timing0", ctypes.c_ubyte),
                ("Timing1", ctypes.c_ubyte),
                ("Mode", ctypes.c_ubyte)]

class VCI_CAN_OBJ(ctypes.Structure):
    _fields_ = [("ID", ctypes.c_uint),
                ("TimeStamp", ctypes.c_uint),
                ("TimeFlag", ctypes.c_ubyte),
                ("SendType", ctypes.c_ubyte),
                ("RemoteFlag", ctypes.c_ubyte),
                ("ExternFlag", ctypes.c_ubyte),
                ("DataLen", ctypes.c_ubyte),
                ("Data", ctypes.c_ubyte * 8),
                ("Reserved", ctypes.c_ubyte * 3)]

def load_dll():
    try:
        return ctypes.windll.LoadLibrary(DLL_PATH)
    except Exception as e:
        print(f"Error loading DLL: {e}")
        return None

def check_call(res, func_name):
    if res != 1:
        print(f"{func_name} Failed! Error Code: {res}")
        return False
    return True

# --- ECU Logic (The "Target") ---
def ecu_thread(can_lib):
    print("[ECU] Activated on Channel 0. Listening...")
    
    SEED = 0xA1B2C3D4
    SECRET_KEY_CONSTANT = 0x1234
    
    while True:
        # Receive
        rx_vci_can_obj = (VCI_CAN_OBJ * 50)()
        num = can_lib.VCI_Receive(DEV_PRO, DEV_IND, CAN_ECU, ctypes.byref(rx_vci_can_obj), 50, 0)
        
        if num > 0:
            for i in range(num):
                msg = rx_vci_can_obj[i]
                data = list(msg.Data)
                # print(f"[ECU] Rx: ID={hex(msg.ID)} Data={data}")
                
                # Logic: UDS-like Security Access
                if msg.ID == 0x7E0:
                    # Service 27 01 (Request Seed)
                    if data[0] == 0x27 and data[1] == 0x01:
                        print(f"[ECU] Received Seed Request. Sending Seed: {hex(SEED)}")
                        
                        # Prepare Response: 27 01 <SeedBytes>
                        resp = VCI_CAN_OBJ()
                        resp.ID = 0x7E8
                        resp.SendType = 0
                        resp.RemoteFlag = 0
                        resp.ExternFlag = 0
                        resp.DataLen = 8
                        # Response: 67 01 AA BB CC DD
                        resp.Data[0] = 0x67 # Positive Response to 27
                        resp.Data[1] = 0x01
                        
                        seed_bytes = SEED.to_bytes(4, 'big')
                        resp.Data[2] = seed_bytes[0]
                        resp.Data[3] = seed_bytes[1]
                        resp.Data[4] = seed_bytes[2]
                        resp.Data[5] = seed_bytes[3]
                        
                        can_lib.VCI_Transmit(DEV_PRO, DEV_IND, CAN_ECU, ctypes.byref(resp), 1)

                    # Service 27 02 (Send Key)
                    elif data[0] == 0x27 and data[1] == 0x02:
                        # Extract Key
                        user_key_bytes = bytes(data[2:6])
                        user_key = int.from_bytes(user_key_bytes, 'big')
                        
                        print(f"[ECU] Received Key Attempt: {hex(user_key)}")
                        
                        # Simple "Algorithm"
                        expected_key = SEED + SECRET_KEY_CONSTANT
                        
                        resp = VCI_CAN_OBJ()
                        resp.ID = 0x7E8
                        resp.SendType = 0
                        resp.RemoteFlag = 0
                        resp.ExternFlag = 0
                        resp.DataLen = 8
                        
                        if user_key == expected_key:
                            print("[ECU] Key Valid! Access GRANTED.")
                            resp.Data[0] = 0x67 # Positive
                            resp.Data[1] = 0x02 # Subfunction 02
                            resp.Data[2] = 0x34 # '4' - Access Granted Code
                        else:
                            print("[ECU] Key Invalid! Access DENIED.")
                            resp.Data[0] = 0x7F # Negative Resp
                            resp.Data[1] = 0x27
                            resp.Data[2] = 0x35 # Invalid Key
                        
                        can_lib.VCI_Transmit(DEV_PRO, DEV_IND, CAN_ECU, ctypes.byref(resp), 1)

        time.sleep(0.01)

# --- Scanner Logic (The User) ---
def scanner_listener(can_lib):
    while True:
        rx_vci_can_obj = (VCI_CAN_OBJ * 50)()
        num = can_lib.VCI_Receive(DEV_PRO, DEV_IND, CAN_SCANNER, ctypes.byref(rx_vci_can_obj), 50, 0)
        if num > 0:
            for i in range(num):
                msg = rx_vci_can_obj[i]
                data_hex = ' '.join(f"{b:02X}" for b in msg.Data[:msg.DataLen])
                print(f"\n[SCANNER] Received from BUS: ID=0x{msg.ID:X}  Data=[{data_hex}]")
                print("Your Command> ", end='', flush=True)
        time.sleep(0.01)

def main():
    print("Initializing Waveshare USB-CAN-B...")
    can = load_dll()
    if not can:
        return

    # Open Device
    if not check_call(can.VCI_OpenDevice(DEV_PRO, DEV_IND, 0), "OpenDevice"):
        return

    # Init Config (250Kbps: Timing0=0x01, Timing1=0x1C)
    vci_init = VCI_INIT_CONFIG()
    vci_init.AccCode = 0x00000000
    vci_init.AccMask = 0xFFFFFFFF
    vci_init.Filter = 1 # Dual Filter
    vci_init.Timing0 = 0x01 # 250Kbps
    vci_init.Timing1 = 0x1C
    vci_init.Mode = 0 # Normal

    # Init CAN0 (ECU)
    check_call(can.VCI_InitCAN(DEV_PRO, DEV_IND, CAN_ECU, ctypes.byref(vci_init)), "InitCAN0")
    check_call(can.VCI_StartCAN(DEV_PRO, DEV_IND, CAN_ECU), "StartCAN0")

    # Init CAN1 (Scanner)
    check_call(can.VCI_InitCAN(DEV_PRO, DEV_IND, CAN_SCANNER, ctypes.byref(vci_init)), "InitCAN1")
    check_call(can.VCI_StartCAN(DEV_PRO, DEV_IND, CAN_SCANNER), "StartCAN1")

    print("\nSystem Ready!")
    print("---------------------------------------------------------------")
    print("Scenario: Security Access (Seed & Key)")
    print("Goal: You are the Scanner (CAN1). You want to unlock the ECU (CAN0).")
    print("Commands:")
    print("  seed  -> Request a Seed (Sends 27 01)")
    print("  key <hex> -> Send Key (Sends 27 02 <hex>)")
    print("  raw <id> <data...> -> Send raw data")
    print("  exit  -> Quit")
    print("---------------------------------------------------------------")

    # Start Threads
    t_ecu = threading.Thread(target=ecu_thread, args=(can,), daemon=True)
    t_ecu.start()

    t_scan = threading.Thread(target=scanner_listener, args=(can,), daemon=True)
    t_scan.start()

    # User Input Loop
    try:
        while True:
            cmd = input("Your Command> ").strip().split()
            if not cmd: continue
            
            if cmd[0] == "exit":
                break
            
            msg = VCI_CAN_OBJ()
            msg.SendType = 0
            msg.RemoteFlag = 0
            msg.ExternFlag = 0
            
            if cmd[0] == "seed":
                # Send Request Seed: ID 7E0, Data 27 01
                msg.ID = 0x7E0
                msg.DataLen = 2
                msg.Data[0] = 0x27
                msg.Data[1] = 0x01
                can.VCI_Transmit(DEV_PRO, DEV_IND, CAN_SCANNER, ctypes.byref(msg), 1)
                print("[SCANNER] Requesting Seed...")

            elif cmd[0] == "key":
                # key AABBCCDD
                if len(cmd) < 2:
                    print("Usage: key <4-byte-hex>")
                    continue
                try:
                    key_val = int(cmd[1], 16)
                    key_bytes = key_val.to_bytes(4, 'big')
                    msg.ID = 0x7E0
                    msg.DataLen = 6
                    msg.Data[0] = 0x27
                    msg.Data[1] = 0x02
                    msg.Data[2] = key_bytes[0]
                    msg.Data[3] = key_bytes[1]
                    msg.Data[4] = key_bytes[2]
                    msg.Data[5] = key_bytes[3]
                    can.VCI_Transmit(DEV_PRO, DEV_IND, CAN_SCANNER, ctypes.byref(msg), 1)
                    print(f"[SCANNER] Sending Key: {hex(key_val)}")
                except:
                    print("Invalid Key Format")

            elif cmd[0] == "raw":
                # raw 7E0 27 01
                try:
                    msg.ID = int(cmd[1], 16)
                    data_bytes = [int(x, 16) for x in cmd[2:]]
                    msg.DataLen = len(data_bytes)
                    for i, b in enumerate(data_bytes):
                        msg.Data[i] = b
                    can.VCI_Transmit(DEV_PRO, DEV_IND, CAN_SCANNER, ctypes.byref(msg), 1)
                    print(f"[SCANNER] Sent Raw ID={hex(msg.ID)}")
                except:
                   print("Invalid Raw format")

    except KeyboardInterrupt:
        pass

    print("Closing...")
    can.VCI_CloseDevice(DEV_PRO, DEV_IND)

if __name__ == "__main__":
    main()
