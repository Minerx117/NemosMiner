using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices | Where-Object Type -EQ "NVIDIA")) { Return }
If ($Config.MinerInstancePerDeviceModel -and ($Devices.Model | Select-Object -Unique).Count -gt 1) { Return } # Error 'No cuda shared libraries found' if more than one active instance

$Uri = "https://github.com/Minerx117/miners/releases/download/TT-Miner/TT-Miner-v6.2.0.7z"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";      Fee = 0.01; MinMemGB = 4; MinerSet = 1; WarmupTimes = @(45, 60); Arguments = " -algo ETHASH -coin ETC -intensity 15" } # PhoenixMiner-v5.9d is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.01; MinMemGB = 5; MinerSet = 1; WarmupTimes = @(45, 60); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v5.9d is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.01; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(45, 60); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v5.9d is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Fee = 0.01; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(60, 60); Arguments = " -algo KAWPOW -intensity 15" } # Trex-v0.25.8 is fastest
    [PSCustomObject]@{ Algorithm = "MTP";          Fee = 0.01; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(45, 60); Arguments = " -algo MTP -intensity 21" } # CcminerMTP-v1.3.2 is faster
    [PSCustomObject]@{ Algorithm = "ProgPoW";      Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(45, 60); Arguments = " -algo PROGPOW" } # Sero
    [PSCustomObject]@{ Algorithm = "UbqHash";      Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(45, 60); Arguments = " -algo UBQHASH -intensity 15" }
    [PSCustomObject]@{ Algorithm = "Zano";         Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 60); Arguments = " -algo PROGPOWZ" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 1GB -le 2 }) { $_.Arguments = $_.Arguments -replace " -intensity [0-9\.]+" }
                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Coin = ""
                If ($Pools.($_.Algorithm).Currency -in @("CLO", "ETC", "ETH", "EPIC", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "SERO", "TCR", "UBQ", "VBK", "VEIL", "ZANO", "ZCOIN", "ZELS")) { 
                    $Coin = " -coin $($Pools.($_.Algorithm).Currency)"
                }
                ElseIf ($_.Algorithm -eq "ProgPoW") { # No coin
                    Return
                }

                $Pass = " -pass $($Pools.($_.Algorithm).Pass)"
                If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = "NVIDIA"
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) -pool stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -user $($Pools.($_.Algorithm).User)$Pass -PRT 1 -PRS 0 $Coin -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "EthMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}