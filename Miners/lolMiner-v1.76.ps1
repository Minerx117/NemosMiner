If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "INTEL", "NVIDIA"))) { Return }

$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.76/lolMiner_v1.76_Win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\lolminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Type = "AMD"; Fee = @(0.015);      MinMemGiB = 0.85; Minerset = 1; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithms = @("BeamV3");                     Type = "AMD"; Fee = @(0.01);       MinMemGiB = 6.0;  MinerSet = 0; WarmupTimes = @(45, 50); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithms = @("Blake3");                     Type = "AMD"; Fee = @(0.0075);     MinMemGiB = 2.0;  Minerset = 1; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("GCN1", "GCN2");         Arguments = " --algo ALEPH" }
    [PSCustomObject]@{ Algorithms = @("Cuckoo29");                   Type = "AMD"; Fee = @(0.02);       MinMemGiB = 6.0;  MinerSet = 0; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo29B");                Type = "AMD"; Fee = @(0.02);       MinMemGiB = 6.0;  Minerset = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo29S");                Type = "AMD"; Fee = @(0.02);       MinMemGiB = 6.0;  Minerset = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo30CTX");              Type = "AMD"; Fee = @(0.025);      MinMemGiB = 7.8;  Minerset = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithms = @("CuckarooD29");                Type = "AMD"; Fee = @(0.01);       MinMemGiB = 4.0;  Minerset = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo C29D" } # TeamRedMiner-v0.10.14 is fastest, keep enabled because TeamRed does not support algo on Navi
    [PSCustomObject]@{ Algorithms = @("CuckarooM29");                Type = "AMD"; Fee = @(0.01);       MinMemGiB = 6.0;  Minerset = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo C29M" }
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo31");                 Type = "AMD"; Fee = @(0.02);       MinMemGiB = 4.0;  Minerset = 3; WarmupTimes = @(60, 80); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo C31" } # ASIC
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo32");                 Type = "AMD"; Fee = @(0.02);       MinMemGiB = 4.0;  Minerset = 3; WarmupTimes = @(60, 70); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo C32" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Equihash1254");               Type = "AMD"; Fee = @(0.015);      MinMemGiB = 3.0;  MinerSet = 0; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --coin ZEL" }
    [PSCustomObject]@{ Algorithms = @("Equihash1445");               Type = "AMD"; Fee = @(0.01);       MinMemGiB = 3.0;  Minerset = 1; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --coin $(If ($MinerPools[0].Equihash1445.Currency -in @("BTCZ", "BTG", "EXCC", "XSG")) { $MinerPools[0].Equihash1445.Currency } Else { "AUTO144_5" })" } # FPGA
    [PSCustomObject]@{ Algorithms = @("Equihash1927");               Type = "AMD"; Fee = @(0.01);       MinMemGiB = 3.0;  MinerSet = 0; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --coin $(If ($MinerPools[0].Equihash1927.Currency -in @("YEC", "ZCL", "ZER")) { $MinerPools[0].Equihash1927.Currency } Else { "AUTO192_7" })" } # FPGA
    [PSCustomObject]@{ Algorithms = @("EtcHash");                    Type = "AMD"; Fee = @(0.007);      MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @();                       Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");          Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @();                       Arguments = " --algo ETCHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");      Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @("RDNA1");                Arguments = " --algo ETCHASH --dualmode KASPADUAL" }
    [PSCustomObject]@{ Algorithms = @("Ethash");                     Type = "AMD"; Fee = @(0.007);      MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @();                       Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");           Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @();                       Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @("RDNA1");                Arguments = " --algo ETHASH --dualmode KASPADUAL" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");               Type = "AMD"; Fee = @(0.007);      MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @();                       Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "Blake3");     Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @();                       Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "kHeavyHash"); Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @("RDNA1");                Arguments = " --algo ETHASH --dualmode KASPADUAL" }
    [PSCustomObject]@{ Algorithms = @("IronFish");                   Type = "AMD"; Fee = @(0.0075);     MinMemGiB = 2.0;  Minerset = 1; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("GCN1", "GCN2");         Arguments = " --algo IRONFISH" }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Type = "AMD"; Fee = @(0.0075);     MinMemGiB = 2.0;  Minerset = 1; WarmupTimes = @(60, 50); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo KASPA" }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                    Type = "AMD"; Fee = @(0.02);       MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3"); Arguments = " --algo NEXA" }
    [PSCustomObject]@{ Algorithms = @("UbqHash");                    Type = "AMD"; Fee = @(0.007);      MinMemGiB = 0.85; MinerSet = 0; WarmupTimes = @(60, 70); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo UBQHASH" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "Blake3");          Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = @("RDNA3");                Arguments = " --algo UBQHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "kHeavyHash");      Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; MinerSet = 0; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = @("RDNA1", "RDNA3");       Arguments = " --algo UBQHASH --dualmode KASPADUAL" }

    [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Type = "INTEL"; Fee = @(0.015);      MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithms = @("BeamV3");                     Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 6.0;  Minerset = 2; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @(); Arguments = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithms = @("Equihash1254");               Type = "INTEL"; Fee = @(0.015);      MinMemGiB = 3.0;  Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); Arguments = " --coin ZEL" }
    [PSCustomObject]@{ Algorithms = @("Equihash1445");               Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 3.0;  Minerset = 2; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @(); Arguments = " --coin $(If ($MinerPools[0].Equihash1445.Currency -in @("BTCZ", "BTG", "EXCC", "XSG")) { $MinerPools[0].Equihash1445.Currency } Else { "AUTO144_5" })" } # FPGA
    [PSCustomObject]@{ Algorithms = @("EtcHash");                    Type = "INTEL"; Fee = @(0.007);      MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");      Type = "INTEL"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @(); Arguments = " --algo ETCHASH --dualmode KASPADUAL --maxdualimpact *" } # No hasrate for 2nd algorithm
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Type = "INTEL"; Fee = @(0.0075);     MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 50); ExcludeGPUArchitecture = @(); Arguments = " --algo KASPA" }

    [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Type = "NVIDIA"; Fee = @(0.015);      MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @();                  Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithms = @("Blake3");                     Type = "NVIDIA"; Fee = @(0.075);      MinMemGiB = 2.0;  Minerset = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();                  Arguments = " --algo ALEPH" }
    [PSCustomObject]@{ Algorithms = @("BeamV3");                     Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 6.0;  Minerset = 2; WarmupTimes = @(45, 50); ExcludeGPUArchitecture = @("Turing");          Arguments = " --algo BEAM-III" } # NBMiner-v42.3 is fastest
    [PSCustomObject]@{ Algorithms = @("Cuckoo29");                   Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 6.0;  Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @();                  Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo29B");                Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 6.0;  Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @();                  Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo29S");                Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 6.0;  Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @();                  Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo30CTX");              Type = "NVIDIA"; Fee = @(0.025);      MinMemGiB = 8.0;  Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @();                  Arguments = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithms = @("CuckarooD29");                Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 4.0;  Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @();                  Arguments = " --algo C29D" } # GMiner-v3.41 is fastest
    [PSCustomObject]@{ Algorithms = @("CuckarooM29");                Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 6.0;  Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @();                  Arguments = " --algo C29M" }
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo31");                 Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 4.0;  Minerset = 3; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();                  Arguments = " --algo C31" } # ASIC
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo32");                 Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 4.0;  Minerset = 3; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();                  Arguments = " --algo C32" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Equihash1254");               Type = "NVIDIA"; Fee = @(0.015);      MinMemGiB = 3.0;  Minerset = 1; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @();                  Arguments = " --coin ZEL" } # MiniZ-v2.0c5 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithms = @("Equihash1445");               Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 3.0;  Minerset = 1; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @();                  Arguments = " --coin $(If ($MinerPools[0].Equihash1445.Currency -in @("BTCZ", "BTG", "EXCC", "XSG")) { $MinerPools[0].Equihash1445.Currency } Else { "AUTO144_5" })" } # FPGA
    [PSCustomObject]@{ Algorithms = @("Equihash1927");               Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @();                  Arguments = " --coin $(If ($MinerPools[0].Equihash1927.Currency -in @("YEC", "ZCL", "ZER")) { $MinerPools[0].Equihash1927.Currency } Else { "AUTO192_7" })" } # FPGA
    [PSCustomObject]@{ Algorithms = @("Equihash2109");               Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();                  Arguments = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                    Type = "NVIDIA"; Fee = @(0.007);      MinMemGiB = 0.85; MinerSet = 0; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @();                  Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");          Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @();                  Arguments = " --algo ETCHASH --dualmode ALEPHDUAL --maxdualimpact *" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");      Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 1; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @();                  Arguments = " --algo ETCHASH --dualmode KASPADUAL --maxdualimpact *" } # No hash rate for kHeavyHash
    [PSCustomObject]@{ Algorithms = @("Ethash");                     Type = "NVIDIA"; Fee = @(0.007);      MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @();                  Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");           Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @();                  Arguments = " --algo ETHASH --dualmode ALEPHDUAL --maxdualimpact *" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = @();                  Arguments = " --algo ETHASH --dualmode KASPADUAL --maxdualimpact *" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");               Type = "NVIDIA"; Fee = @(0.007);      MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = @();                  Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "Blake3");     Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();                  Arguments = " --algo ETHASH --dualmode ALEPHDUAL --maxdualimpact *" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "kHeavyHash"); Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();                  Arguments = " --algo ETHASH --dualmode KASPADUAL --maxdualimpact *" }
#   [PSCustomObject]@{ Algorithms = @("IronFish");                   Type = "NVIDIA"; Fee = @(0.0075);     MinMemGiB = 2.0;  Minerset = 1; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @();                  Arguments = " --algo IRONFISH" }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Type = "NVIDIA"; Fee = @(0.0075);     MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 50); ExcludeGPUArchitecture = @();                  Arguments = " --algo KASPA" }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                    Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 2.0;  Minerset = 1; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @("Other", "Pascal"); Arguments = " --algo NEXA" }
    [PSCustomObject]@{ Algorithms = @("UbqHash");                    Type = "NVIDIA"; Fee = @(0.007);      MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(60, 70); ExcludeGPUArchitecture = @();                  Arguments = " --algo UBQHASH" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "Blake3");          Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; Minerset = 2; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = @();                  Arguments = " --algo UBQHASH --dualmode ALEPHDUAL --maxdualimpact *" }
#   [PSCustomObject]@{ Algorithms = @("UbqHash", "kHeavyHash");      Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 0.85; MinerSet = 0; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = @();                  Arguments = " --algo UBQHASH --dualmode KASPADUAL --maxdualimpact *" } # No hasrate for 2nd algorithm
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }

If ($Algorithms) { 

    # MaxDualImpact for 2. algorithm; The maximum impact on the eth mining speed in dual mining in %. Default is * for automatic mode
    $MaxDualImpactValues = @("*", 5, 10, 15, 20)

    # Build command sets for MaxDualImpact (only seems to work with AMD, no 2nd hashrates for GTX1660Super when --maxdualimpact is a number)
    $Algorithms = $Algorithms | ForEach-Object { 
        If ($_.Type -eq "AMD" -and $_.Algorithms[1]) { 
            ForEach ($MaxDualImpact in $MaxDualImpactValues) { 
                $_ | Add-Member MaxDualImpact $MaxDualImpact -Force
                $_.PsObject.Copy()
            }
        }
        Else { 
            $_
        }
    }

    $Algorithms | Where-Object MinMemGiB | ForEach-Object { 
        $_.MinMemGiB += $MinerPools[0].($_.Algorithms[0]).DAGSizeGiB
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -eq $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            If ($_.Algorithms[0] -match "^Cuckaroo.*$|^Cuckoo.*$" -and ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0")) { $_.MinMemGiB += 1 }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Algorithm0 = $_.Algorithms[0]
                $Algorithm1 = $_.Algorithms[1]
                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)$(If ($Algorithm1) { "-$($Algorithm0)&$($Algorithm1)" })$(If ($_.MaxDualImpact -gt 0) { "-$($_.MaxDualImpact)" })" -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "coin") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --pool $($MinerPools[0].$Algorithm0.Host):$(($MinerPools[0].$Algorithm0.PoolPorts | Select-Object -Last 1))"
                $Arguments += " --user $($MinerPools[0].$Algorithm0.User)$(If ($MinerPools[0].$Algorithm0.WorkerName) { ".$($MinerPools[0].$Algorithm0.WorkerName)" })"
                $Arguments += " --pass $($MinerPools[0].$Algorithm0.Pass)$(If ($MinerPools[0].$Algorithm0.BaseName -eq "ProHashing" -and $Algorithm0 -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].$Algorithm0.DAGSizeGiB))" })"
                $Arguments += If ($MinerPools[0].$Algorithm0.PoolPorts[1]) { " --tls on" } Else { " --tls off" }
                $Arguments += Switch ($MinerPools[0].$Algorithm0.Protocol) { 
                    "ethproxy"     { " --ethstratum ETHPROXY"; Break }
                    "ethstratum1"  { " --ethstratum ETHV1"; Break }
                    "ethstratum2"  { " --ethstratum ETHV1"; Break }
                    "ethstratumnh" { " --ethstratum ETHV1"; Break }
                    Default        { "" }
                }

                If ($Algorithm1) { 
                    $Arguments += " --dualpool $($MinerPools[1].$Algorithm1.Host):$($MinerPools[1].$Algorithm1.PoolPorts | Select-Object -Last 1)"
                    $Arguments += " --dualuser $($MinerPools[1].$Algorithm1.User)$(If ($MinerPools[1].$Algorithm1.WorkerName) { ".$($MinerPools[1].$Algorithm1.WorkerName)" })"
                    $Arguments += " --dualpass $($MinerPools[1].$Algorithm1.Pass)$(If ($MinerPools[1].$Algorithm1.BaseName -eq "ProHashing" -and $Algorithm1 -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].$Algorithm1.DAGSizeGiB))" })"
                    If ($_.MaxDualImpact) { $Arguments += " --maxdualimpact $($_.MaxDualImpact)" }
                    $Arguments += If ($MinerPools[1].$Algorithm1.PoolPorts[1]) { " --dualtls on" } Else { " --dualtls off" }
                }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithms | Select-Object)
                    API         = "lolMiner"
                    Arguments   = ("$($Arguments) --log off --apiport $MinerAPIPort --shortstats 1 --longstats 5 --digits 6 --watchdog exit --dns-over-https 1 --devicesbypcie --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0}:0' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee
                    MinerSet    = $_.MinerSet
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