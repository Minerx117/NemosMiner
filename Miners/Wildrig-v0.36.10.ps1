<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
Version:        4.3.6.1
Version date:   2023/08/19
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$URI = "https://github.com/andru-kun/wildrig-multi/releases/download/0.36.10/wildrig-multi-windows-0.36.10.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\wildrig.exe"
$DeviceEnumerator = "Type_Vendor_Slot"


$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "0x10";             Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo 0x10" }
    [PSCustomObject]@{ Algorithm = "Aergo";            Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo aergo" }
    [PSCustomObject]@{ Algorithm = "Anime";            Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo anime" }
    [PSCustomObject]@{ Algorithm = "APEPEPoW";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo memehashv2" }
    [PSCustomObject]@{ Algorithm = "AstralHash";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo glt-astralhash" }
#   [PSCustomObject]@{ Algorithm = "BCD";              Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo bcd" } # ASIC
    [PSCustomObject]@{ Algorithm = "Bitcore";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc";      Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo blake2b-btcc" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo blake2b-glt" }
#   [PSCustomObject]@{ Algorithm = "Bmw512";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo bmw512" } # ASIC
    [PSCustomObject]@{ Algorithm = "Bitcore";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "C11";              Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo c11" }
    [PSCustomObject]@{ Algorithm = "CurveHash";        Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo curvehash" }
    [PSCustomObject]@{ Algorithm = "Dedal";            Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo dedal" } # CryptoDredge-v0.27.0 is fastest
    [PSCustomObject]@{ Algorithm = "EvrProgPow";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 0.62; MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo evrprogpow" } 
    [PSCustomObject]@{ Algorithm = "Exosis";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo exosis" } 
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo firopow" }
    [PSCustomObject]@{ Algorithm = "Geek";             Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo geek" }
    [PSCustomObject]@{ Algorithm = "Ghostrider";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(90, 45); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo ghostrider" }
    [PSCustomObject]@{ Algorithm = "GlobalHash";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo glt-globalhash" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";        Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 1; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo heavyhash" } # FPGA
    [PSCustomObject]@{ Algorithm = "Hex";              Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo hex" }
    [PSCustomObject]@{ Algorithm = "HMQ1725";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo hmq1725" } # CryptoDredge-v0.27.0 is fastest
    [PSCustomObject]@{ Algorithm = "JeongHash";        Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo glt-jeonghash" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 0.62; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo kawpow" } # TeamRedMiner-v0.10.14 is fastest on Navi
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo lyra2v3" } # ASIC
    [PSCustomObject]@{ Algorithm = "Lyra2TDC";         Type = "AMD"; Fee = @(0.02); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo lyra2tdc" }
    [PSCustomObject]@{ Algorithm = "Lyra2vc0ban";      Type = "AMD"; Fee = @(0.02); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo lyra2vc0ban" }
    [PSCustomObject]@{ Algorithm = "MegaBtx";          Type = "AMD"; Fee = @(0.02); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo megabtx" }
    [PSCustomObject]@{ Algorithm = "MegaMec";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo megamec" }
    [PSCustomObject]@{ Algorithm = "Mike";             Type = "AMD"; Fee = @(0.05); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo mike" }
    [PSCustomObject]@{ Algorithm = "Minotaur";         Type = "AMD"; Fee = @(0.05); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo minotaur" }
#   [PSCustomObject]@{ Algorithm = "MTP";              Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo mtp" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "MTPTcr";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo mtp-tcr" }
    [PSCustomObject]@{ Algorithm = "NexaPow";          Type = "AMD"; Fee = @(0.02); MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @("NiceHash"); Arguments = " --algo nexapow" } # https://github.com/andru-kun/wildrig-multi/issues/243
    [PSCustomObject]@{ Algorithm = "PadiHash";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo glt-padihash" }
    [PSCustomObject]@{ Algorithm = "PawelHash";        Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo glt-pawelhash" }
#   [PSCustomObject]@{ Algorithm = "Phi";              Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo phi" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Phi5";             Type = "AMD"; Fee = @(0.02); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo phi5" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "Polytimos";        Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "AMD"; Fee = @(0.01); MinMemGiB = 0.62; Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo progpow-sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "AMD"; Fee = @(0.01); MinMemGiB = 0.62; Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo progpow-veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo vprogpow" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Type = "AMD"; Fee = @(0.01); MinMemGiB = 0.62; MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo progpowz" }
    [PSCustomObject]@{ Algorithm = "Pufferfish2BMB";   Type = "AMD"; Fee = @(0.01); MinMemGiB = 8;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo pufferfish2" }
    [PSCustomObject]@{ Algorithm = "Renesis";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo renesis" }
    [PSCustomObject]@{ Algorithm = "SHA256csm";        Type = "AMD"; Fee = @(0.02); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo sha256csm" }
    [PSCustomObject]@{ Algorithm = "SHA256t";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo sha256t" } # Takes too long until it starts mining
    [PSCustomObject]@{ Algorithm = "SHA256q";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo sha256q" }
    [PSCustomObject]@{ Algorithm = "SHA512256d";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo sha512256d" }
    [PSCustomObject]@{ Algorithm = "SHAndwich256";     Type = "AMD"; Fee = @(0.01); MinMemGiB = 3;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo skydoge" }
    [PSCustomObject]@{ Algorithm = "Skein2";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo skein2" }
    [PSCustomObject]@{ Algorithm = "SkunkHash";        Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo skunkhash" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "Sonoa";            Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo sonoa" }
    [PSCustomObject]@{ Algorithm = "Timetravel";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo timetravel" }
    [PSCustomObject]@{ Algorithm = "WildKeccak";       Type = "AMD"; Fee = @(0.02); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo wildkeccak" }
    [PSCustomObject]@{ Algorithm = "X11k";             Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo x11k" }
#   [PSCustomObject]@{ Algorithm = "X16r";             Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo x16r" } # ASIC
    [PSCustomObject]@{ Algorithm = "X16rt";            Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo x16rt" } # FPGA
    [PSCustomObject]@{ Algorithm = "X16rv2";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 3;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo x16rv2" }
    [PSCustomObject]@{ Algorithm = "X16s";             Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo x16s" } # FPGA
    [PSCustomObject]@{ Algorithm = "X17";              Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo x17" }
    [PSCustomObject]@{ Algorithm = "X17r";             Type = "AMD"; Fee = @(0.02); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo x17r --protocol ufo2" }
    [PSCustomObject]@{ Algorithm = "X21s";             Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo x21s" } # TeamRedMiner-v0.10.14 is fastest
    [PSCustomObject]@{ Algorithm = "X22i";             Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo x22i" }
    [PSCustomObject]@{ Algorithm = "X33";              Type = "AMD"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo x33" }
    [PSCustomObject]@{ Algorithm = "Xevan";            Type = "AMD"; Fee = @(0.02); MinMemGiB = 3;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @(); ExcludePools = @();           Arguments = " --algo xevan" } # No hashrate on time for old GPUs

    [PSCustomObject]@{ Algorithm = "0x10";             Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo 0x10 --watchdog" }
    [PSCustomObject]@{ Algorithm = "Aergo";            Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo aergo --watchdog" }
    [PSCustomObject]@{ Algorithm = "Anime";            Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo anime --watchdog" }
    [PSCustomObject]@{ Algorithm = "APEPEPoW";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo memehashv2 --watchdog" }
    [PSCustomObject]@{ Algorithm = "AstralHash";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo glt-astralhash --watchdog" }
#   [PSCustomObject]@{ Algorithm = "BCD";              Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo bcd --watchdog" } # ASIC
    [PSCustomObject]@{ Algorithm = "Bitcore";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo bitcore --watchdog" }
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo blake2b-btcc --watchdog" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo blake2b-glt --watchdog" }
#   [PSCustomObject]@{ Algorithm = "Bmw512";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo bmw512 --watchdog" } # ASIC
    [PSCustomObject]@{ Algorithm = "C11";              Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 1; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo c11 --watchdog" }
    [PSCustomObject]@{ Algorithm = "CurveHash";        Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo curvehash --watchdog" }
    [PSCustomObject]@{ Algorithm = "Dedal";            Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo dedal --watchdog" } # CryptoDredge-v0.27.0 is fastest
    [PSCustomObject]@{ Algorithm = "EvrProgPow";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 0.62; Minerset = 1; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo evrprogpow --watchdog" }
    [PSCustomObject]@{ Algorithm = "Exosis";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo exosis --watchdog" }
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; Minerset = 1; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo firopow --watchdog" }
    [PSCustomObject]@{ Algorithm = "Geek";             Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo geek --watchdog" }
    [PSCustomObject]@{ Algorithm = "Ghostrider";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(90, 45); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo ghostrider --watchdog" }
    [PSCustomObject]@{ Algorithm = "GlobalHash";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo glt-globalhash --watchdog" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";        Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo heavyhash --watchdog" } # FPGA
    [PSCustomObject]@{ Algorithm = "Hex";              Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo hex --watchdog" }
    [PSCustomObject]@{ Algorithm = "HMQ1725";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 1; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo hmq1725 --watchdog" } # CryptoDredge-v0.27.0 is fastest
    [PSCustomObject]@{ Algorithm = "JeongHash";        Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo glt-jeonghash --watchdog" } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 0.90; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo kawpow --watchdog" } # NBMiner-v42.3 is fastest
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo lyra2v3 --watchdog" } # ASIC
    [PSCustomObject]@{ Algorithm = "Lyra2TDC";         Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo lyra2tdc --watchdog" }
    [PSCustomObject]@{ Algorithm = "Lyra2vc0ban";      Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo lyra2vc0ban --watchdog" }
    [PSCustomObject]@{ Algorithm = "MegaBtx";          Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo megabtx --watchdog" }
    [PSCustomObject]@{ Algorithm = "MegaMec";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo megamec --watchdog" }
    [PSCustomObject]@{ Algorithm = "Mike";             Type = "NVIDIA"; Fee = @(0.05); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo mike --watchdog" }
    [PSCustomObject]@{ Algorithm = "Minotaur";         Type = "NVIDIA"; Fee = @(0.05); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo minotaur --watchdog" }
#   [PSCustomObject]@{ Algorithm = "MTP";              Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo mtp --watchdog" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "MTPTcr";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo mtp-tcr --watchdog" }
    [PSCustomObject]@{ Algorithm = "NexaPow";          Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @("NiceHash"); Arguments = " --algo nexapow --watchdog" } # https://github.com/andru-kun/wildrig-multi/issues/243
    [PSCustomObject]@{ Algorithm = "PadiHash";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo glt-padihash --watchdog" }
    [PSCustomObject]@{ Algorithm = "PawelHash";        Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo glt-pawelhash --watchdog" } # Trex-v0.26.8 is fastest
#   [PSCustomObject]@{ Algorithm = "Phi";              Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo phi --watchdog" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Phi5";             Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo phi5 --watchdog" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "Polytimos";        Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo polytimos --watchdog" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 0.62; Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo progpow-sero --watchdog" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 0.62; Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo progpow-veil --watchdog" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo vprogpow --watchdog" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 0.62; Minerset = 1; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo progpowz --watchdog" }
    [PSCustomObject]@{ Algorithm = "Renesis";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo renesis --watchdog" }
    [PSCustomObject]@{ Algorithm = "SHA256csm";        Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo sha256csm --watchdog" }
    [PSCustomObject]@{ Algorithm = "SHA256t";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo sha256t --watchdog" }
    [PSCustomObject]@{ Algorithm = "SHA256q";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo sha256q --watchdog" }
    [PSCustomObject]@{ Algorithm = "SHA512256d";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           Arguments = " --algo sha512256d --watchdog" }
    [PSCustomObject]@{ Algorithm = "SHAndwich256";     Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo skydoge" }
    [PSCustomObject]@{ Algorithm = "Skein2";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(90, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo skein2 --watchdog" } # CcminerAlexis78-v1.5.2 is fastest
    [PSCustomObject]@{ Algorithm = "SkunkHash";        Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(90, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo skunkhash --watchdog" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "Sonoa";            Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo sonoa --watchdog" } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithm = "Timetravel";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo timetravel --watchdog" }
#   [PSCustomObject]@{ Algorithm = "Tribus";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo tribus --watchdog" } # ASIC
    [PSCustomObject]@{ Algorithm = "WildKeccak";       Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo wildkecca --watchdog" }
    [PSCustomObject]@{ Algorithm = "X11k";             Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo x11k --watchdog" }
#   [PSCustomObject]@{ Algorithm = "X16r";             Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo x16r --watchdog" } # ASIC
    [PSCustomObject]@{ Algorithm = "X16rt";            Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo x16rt --watchdog" } # FPGA
    [PSCustomObject]@{ Algorithm = "X16rv2";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 3;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo x16rv2 --watchdog" }
    [PSCustomObject]@{ Algorithm = "X16s";             Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo x16s --watchdog" } # FPGA
    [PSCustomObject]@{ Algorithm = "X17";              Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo x17 --watchdog" }
    [PSCustomObject]@{ Algorithm = "X17r";             Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo x17r --protocol ufo2 --watchdog" }
    [PSCustomObject]@{ Algorithm = "X21s";             Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo x21s --watchdog" } # Trex-v0.26.8 is fastest
#   [PSCustomObject]@{ Algorithm = "X22i";             Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo x22i" } # Incorrect intensities
    [PSCustomObject]@{ Algorithm = "X33";              Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           Arguments = " --algo x33 --watchdog" }
) 

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePools }

If ($Algorithms) { 

    $Algorithms | ForEach-Object { 
        $_.MinMemGiB += $MinerPools[0].($_.Algorithm).DAGSizeGiB
    }
 
    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "XmRig"
                    Arguments   = ("$($_.Arguments) --api-port $MinerAPIPort --url $(If ($AllMinerPools.($_.Algorithm).PoolPorts[1]) { "stratum+tcps" } Else { "stratum+tcp" })://$($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($AllMinerPools.($_.Algorithm).User)$(If ($AllMinerPools.($_.Algorithm).WorkerName) { ".$($AllMinerPools.($_.Algorithm).WorkerName)" }) --pass $($AllMinerPools.($_.Algorithm).Pass) --multiple-instance --opencl-platforms $($AvailableMiner_Devices.PlatformId | Sort-Object -Unique) --opencl-devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee # subtract devfee
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = $_.Type
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}