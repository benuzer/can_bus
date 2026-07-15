
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

# Constants & Setup
$DEV_PRO = 21 # USBCAN-2E-U
$DEV_IND = 0
$CAN_ECU = 0
$CAN_USER = 1
$BAUD_TIMING0 = 0x01 # 250K
$BAUD_TIMING1 = 0x1C

# Functions
function Send-Msg {
    param($Ch, $Id, $DataBytes)
    $obj = New-Object VCI_CAN_OBJ
    $obj.ID = $Id
    $obj.SendType = 0
    $obj.RemoteFlag = 0
    $obj.ExternFlag = 0
    $obj.DataLen = $DataBytes.Length
    $obj.Data = New-Object byte[] 8
    for ($i = 0; $i -lt $DataBytes.Length; $i++) { $obj.Data[$i] = $DataBytes[$i] }
    
    $arr = @($obj)
    [CANWrapper]::VCI_Transmit($DEV_PRO, $DEV_IND, $Ch, $arr, 1) > $null
}

function Listen-Ch {
    param($Ch, $Name)
    $count = [CANWrapper]::VCI_GetReceiveNum($DEV_PRO, $DEV_IND, $Ch)
    if ($count -gt 0) {
        $rxObjs = New-Object VCI_CAN_OBJ[] $count
        for ($i = 0; $i -lt $count; $i++) { $rxObjs[$i] = New-Object VCI_CAN_OBJ; $rxObjs[$i].Data = New-Object byte[] 8; $rxObjs[$i].Reserved = New-Object byte[] 3 }
        $num = [CANWrapper]::VCI_Receive($DEV_PRO, $DEV_IND, $Ch, $rxObjs, $count, 0)
        
        for ($k = 0; $k -lt $num; $k++) {
            $m = $rxObjs[$k]
            $dStr = ($m.Data[0..($m.DataLen - 1)] | ForEach-Object { $_.ToString("X2") }) -join " "
            Write-Host "[$Name RECV] ID:$($m.ID.ToString("X3")) Data: $dStr" -ForegroundColor Yellow
            return $m # Return first msg for logic
        }
    }
    return $null
}

# START MAIN
try {
    Write-Host "Initializing Self-Contained Demo..." -ForegroundColor Cyan
    $res = [CANWrapper]::VCI_OpenDevice($DEV_PRO, $DEV_IND, 0)
    if ($res -ne 1) { Write-Host "Error OpenDevice"; exit }

    $config = New-Object VCI_INIT_CONFIG
    $config.AccCode = 0; $config.AccMask = [UInt32]4294967295; $config.Filter = 1; $config.Timing0 = $BAUD_TIMING0; $config.Timing1 = $BAUD_TIMING1; $config.Mode = 0
    
    [CANWrapper]::VCI_InitCAN($DEV_PRO, $DEV_IND, $CAN_ECU, [ref]$config)
    [CANWrapper]::VCI_StartCAN($DEV_PRO, $DEV_IND, $CAN_ECU)
    [CANWrapper]::VCI_InitCAN($DEV_PRO, $DEV_IND, $CAN_USER, [ref]$config)
    [CANWrapper]::VCI_StartCAN($DEV_PRO, $DEV_IND, $CAN_USER)

    Write-Host "------------------------------------------------"
    Write-Host "HACKING SIMULATION READY" -ForegroundColor Green
    Write-Host "You are the Hacker (Channel 1)."
    Write-Host "Target is ECU (Channel 0)."
    Write-Host "Commands:"
    Write-Host "  1  -> Request Seed (Sends 7E0 02 27 01...)"
    Write-Host "  2  -> Send Key (Sends 7E0 ... calculated key)"
    Write-Host "  q  -> Quit"
    Write-Host "------------------------------------------------"

    $CapturedSeed = 0

    while ($true) {
        # READ USER INPUT (Non-blocking check not easy in loop, so we block for input)
        $input = Read-Host "COMMAND (1/2/q)"
        
        if ($input -eq "q") { break }
        
        if ($input -eq "1") {
            Write-Host "[YOU] Sending Seed Request..." -ForegroundColor Green
            Send-Msg $CAN_USER 0x7E0 @(0x02, 0x27, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00)
        }
        elseif ($input -eq "2") {
            if ($CapturedSeed -eq 0) {
                Write-Host "You don't have a seed yet! Request one first." -ForegroundColor Red
            }
            else {
                $Key = $CapturedSeed + 1
                $kBytes = [BitConverter]::GetBytes([UInt32]$Key)
                if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($kBytes) }
                
                Write-Host "[YOU] Sending Key: $($Key.ToString("X8"))" -ForegroundColor Green
                Send-Msg $CAN_USER 0x7E0 @(0x06, 0x27, 0x02, $kBytes[0], $kBytes[1], $kBytes[2], $kBytes[3])
            }
        }
        
        # PROCESS TRAFFIC LOOP (Run for a bit to catch replies)
        for ($t = 0; $t -lt 10; $t++) {
            Start-Sleep -Milliseconds 100
            
            # 1. Check ECU Incoming (Ch0)
            $msg = Listen-Ch $CAN_ECU "ECU"
            if ($msg) {
                # Logic ECU
                if ($msg.ID -eq 0x7E0 -and $msg.Data[1] -eq 0x27 -and $msg.Data[2] -eq 0x01) {
                    Write-Host "[ECU LOGIC] Seed Requested. Generating..." -ForegroundColor Gray
                    $Seed = 0xA1B2C3D4
                    Send-Msg $CAN_ECU 0x7E8 @(0x06, 0x67, 0x01, 0xA1, 0xB2, 0xC3, 0xD4)
                }
                if ($msg.ID -eq 0x7E0 -and $msg.Data[1] -eq 0x27 -and $msg.Data[2] -eq 0x02) {
                    Write-Host "[ECU LOGIC] Key Received. Verifying..." -ForegroundColor Gray
                    # Extract User Key
                    $uKBytes = @($msg.Data[3], $msg.Data[4], $msg.Data[5], $msg.Data[6])
                    
                    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($uKBytes) }
                    $uKey = [BitConverter]::ToUInt32($uKBytes, 0)
                    
                    # Robust Comparison
                    $ExpectedVal = [UInt32]2712847317 # 0xA1B2C3D5
                    
                    Write-Host "[DEBUG] ECU Calculated: $ExpectedVal  |  User Sent: $uKey" -ForegroundColor DarkGray
                    
                    if ($uKey -eq $ExpectedVal) {
                        Write-Host "[ECU] *** ACCESS GRANTED ***" -ForegroundColor Magenta
                        Send-Msg $CAN_ECU 0x7E8 @(0x02, 0x67, 0x02, 0x00, 0x00, 0x00, 0x00)
                    }
                    else {
                        Write-Host "[ECU] ACCESS DENIED" -ForegroundColor Red
                        Send-Msg $CAN_ECU 0x7F8 @(0x7F, 0x27, 0x35)
                    }
                }
            }
            
            # 2. Check User Incoming (Ch1) - What hacker sees
            $msgUser = Listen-Ch $CAN_USER "YOU"
            if ($msgUser) {
                # If we got a seed response, store it
                if ($msgUser.ID -eq 0x7E8 -and $msgUser.Data[1] -eq 0x67 -and $msgUser.Data[2] -eq 0x01) {
                    $sBytes = @($msgUser.Data[3], $msgUser.Data[4], $msgUser.Data[5], $msgUser.Data[6])
                    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($sBytes) }
                    $CapturedSeed = [BitConverter]::ToUInt32($sBytes, 0)
                    Write-Host "[SYSTEM] Seed Captured: $($CapturedSeed.ToString("X8")). Press '2' to unlock." -ForegroundColor Cyan
                }
            }
        }
    }

}
finally { [CANWrapper]::VCI_CloseDevice($DEV_PRO, $DEV_IND); Write-Host "Closed." }
