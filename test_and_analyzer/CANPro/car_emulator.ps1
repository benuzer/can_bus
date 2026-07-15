
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
$DEV_PRO = 21; $DEV_IND = 0; $CAN_CH = 0 # Car is on Ch0
$BAUD_TIMING0 = 0x01; $BAUD_TIMING1 = 0x1C

# --- PHYSICS ENGINE VARIABLES ---
$RPM = 0
$Speed = 0
$Throttle = 0
$Temp = 90
$Gear = "P"
$Odo = 123450

# --- STATUS FLAGS ---
$Doors = @{ FL = $false; FR = $false; RL = $false; RR = $false } # False=Closed
$Locks = @{ FL = $true; FR = $true; RL = $true; RR = $true }     # True=Locked
$Lights = $false
$Brake = $false
$Seatbelt = $true

function Draw-Dashboard {
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, 0
    
    $bar = ""; 1..($Speed / 5) | % { $bar += "█" }
    $rpmBar = ""; 1..($RPM / 500) | % { $rpmBar += "▒" }
    
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                TOYOTA COROLLA - VIRTUAL CLUSTER                " -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  SPEED:  $([math]::Round($Speed,0)) km/h  " -NoNewline -ForegroundColor Green
    Write-Host "  [$($bar.PadRight(40))]" -ForegroundColor Green
    Write-Host "  RPM:    $([math]::Round($RPM,0))       " -NoNewline -ForegroundColor Yellow
    Write-Host "  [$($rpmBar.PadRight(16))]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "----------------------------------------------------------------"
    Write-Host "  GEAR: [$Gear]    TEMP: $Temp °C    ODO: $Odo km" -ForegroundColor White
    Write-Host "----------------------------------------------------------------"
    Write-Host "  DOORS:   FL:[$(if($Doors.FL){'OPEN'}else{'CLSD'})] FR:[$(if($Doors.FR){'OPEN'}else{'CLSD'})] RL:[$(if($Doors.RL){'OPEN'}else{'CLSD'})] RR:[$(if($Doors.RR){'OPEN'}else{'CLSD'})]" -ForegroundColor Gray
    Write-Host "  LOCKS:   FL:[$(if($Locks.FL){'LCK'}else{'ULK'})]  FR:[$(if($Locks.FR){'LCK'}else{'ULK'})]  RL:[$(if($Locks.RL){'LCK'}else{'ULK'})]  RR:[$(if($Locks.RR){'LCK'}else{'ULK'})]" -ForegroundColor Gray
    Write-Host "----------------------------------------------------------------"
    Write-Host "  STATUS:  " -NoNewline
    if ($Brake) { Write-Host "[BRAKE] " -NoNewline -ForegroundColor Red -BackgroundColor White } else { Write-Host "[BRAKE] " -NoNewline -ForegroundColor DarkGray }
    if ($Lights) { Write-Host "[LIGHTS] " -NoNewline -ForegroundColor Yellow -BackgroundColor Black } else { Write-Host "[LIGHTS] " -NoNewline -ForegroundColor DarkGray }
    if (-not $Seatbelt) { Write-Host "[SEATBELT] " -NoNewline -ForegroundColor Red -BackgroundColor Black } else { Write-Host "[SEATBELT] " -NoNewline -ForegroundColor DarkGray }
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  SIMULATION LOG (Last Events):" -ForegroundColor Gray
}

function Send-Msg {
    param($Id, $DataBytes)
    $obj = New-Object VCI_CAN_OBJ
    $obj.ID = $Id; $obj.DataLen = $DataBytes.Length; $obj.Data = New-Object byte[] 8
    for ($i = 0; $i -lt $DataBytes.Length; $i++) { $obj.Data[$i] = $DataBytes[$i] }
    $arr = @($obj)
    [CANWrapper]::VCI_Transmit($DEV_PRO, $DEV_IND, $CAN_CH, $arr, 1) > $null
}

try {
    Clear-Host
    Write-Host "STARTING SIMULATION..."
    $res = [CANWrapper]::VCI_OpenDevice($DEV_PRO, $DEV_IND, 0)
    if ($res -ne 1) { Write-Host "Error OpenDevice"; exit }

    $config = New-Object VCI_INIT_CONFIG
    $config.AccCode = 0; $config.AccMask = 0; $config.Filter = 1; $config.Timing0 = $BAUD_TIMING0; $config.Timing1 = $BAUD_TIMING1; $config.Mode = 0
    [CANWrapper]::VCI_InitCAN($DEV_PRO, $DEV_IND, $CAN_CH, [ref]$config)
    [CANWrapper]::VCI_StartCAN($DEV_PRO, $DEV_IND, $CAN_CH)

    $Tick = 0
    while ($true) {
        # --- PHYSICS UPDATE ---
        $Tick++
        
        # Simple Drive Cycle: Idle -> Accel -> Cruise -> Brake
        if ($Tick -lt 50) {
            # Start/Idle
            $RPM = 800; $Speed = 0; $Gear = "P"
        }
        elseif ($Tick -lt 200) {
            # Accel
            $Gear = "D"; $Locks.FL = $true
            $RPM += 50; if ($RPM -gt 3500) { $RPM = 3000 }
            $Speed += 0.5; if ($Speed -gt 120) { $Speed = 120 }
        }
        elseif ($Tick -lt 400) {
            # Cruise
            $RPM = 2200 + (Get-Random -Min -50 -Max 50)
            $Speed = 100 + (Get-Random -Min -1 -Max 1)
        }
        else {
            # Brake
            $Brake = $true
            $RPM -= 60; if ($RPM -lt 800) { $RPM = 800 }
            $Speed -= 1.0; if ($Speed -lt 0) { $Speed = 0 }
        }
        if ($Tick -gt 500) { $Tick = 0; $Brake = $false } # Loop

        # --- BROADCAST CAN DATA (Toyota Style) ---
        
        # 0x2C4: RPM & Speed (Standard Toyota ID)
        # Bytes 0-1: RPM, Bytes 2-3: Speed * 100
        $rpmBytes = [BitConverter]::GetBytes([UInt16]$RPM)
        $spdBytes = [BitConverter]::GetBytes([UInt16]($Speed * 100))
        if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($rpmBytes); [Array]::Reverse($spdBytes) }
        Send-Msg 0x2C4 @($rpmBytes[0], $rpmBytes[1], $spdBytes[0], $spdBytes[1], 0, 0, 0, 0)

        # 0x2C1: Pedals (Throttle, Brake)
        # Byte 0: Throttle %, Byte 1: Brake (Bit 6)
        $brakeByte = if ($Brake) { 0x40 }else { 0x00 }
        Send-Msg 0x2C1 @([byte]($RPM / 50), $brakeByte, 0, 0, 0, 0, 0, 0)

        # 0x3B0: Doors & Lights
        # Bit packing simulated
        Send-Msg 0x3B0 @(0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)

        # --- HANDLE INCOMING REQUESTS (OBDII) ---
        $num = [CANWrapper]::VCI_GetReceiveNum($DEV_PRO, $DEV_IND, $CAN_CH)
        if ($num -gt 0) {
            $rxObjs = New-Object VCI_CAN_OBJ[] $num
            for ($x = 0; $x -lt $num; $x++) { $rxObjs[$x] = New-Object VCI_CAN_OBJ; $rxObjs[$x].Data = New-Object byte[] 8; $rxObjs[$x].Reserved = New-Object byte[] 3 }
            [CANWrapper]::VCI_Receive($DEV_PRO, $DEV_IND, $CAN_CH, $rxObjs, $num, 0) > $null
            
            foreach ($m in $rxObjs) {
                # OBDII Request ID: 0x7DF
                if ($m.ID -eq 0x7DF) {
                    # Mode 01, PID 0C (RPM) -> Reply 4 Bytes on 0x7E8
                    if ($m.Data[2] -eq 0x0C) { 
                        # Formula: (A*256 + B) / 4 = RPM  =>  4*RPM = Val
                        $val = [UInt16]($RPM * 4)
                        $b = [BitConverter]::GetBytes($val)
                        if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($b) }
                        Send-Msg 0x7E8 @(0x04, 0x41, 0x0C, $b[0], $b[1], 0, 0, 0)
                        Write-Host "`n [OBD] RPM Requested -> Replied $RPM" -ForegroundColor Yellow
                    }
                    # Mode 01, PID 0D (Speed)
                    if ($m.Data[2] -eq 0x0D) {
                        Send-Msg 0x7E8 @(0x03, 0x41, 0x0D, [byte]$Speed, 0, 0, 0, 0)
                        Write-Host "`n [OBD] Speed Requested -> Replied $Speed" -ForegroundColor Yellow
                    }
                }
            }
        }

        Draw-Dashboard
        Start-Sleep -Milliseconds 50
    }

}
finally { [CANWrapper]::VCI_CloseDevice($DEV_PRO, $DEV_IND) }
