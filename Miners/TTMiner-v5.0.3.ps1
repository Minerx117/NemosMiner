using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices | Where-Object { $_.Type -eq "NVIDIA" -and $_.OpenCL.ComputeCapability -lt 8.6 <# No response in API with RTX cards #>})) { Return }

$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs 

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Eaglesong";    MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -algo EAGLESONG" }
    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGB = 4; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; MinMemGB = 3; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "KawPoW";       MinMemGB = 3; MinerSet = 0; WarmupTimes = @(40, 15); Arguments = " -algo KAWPOW" }
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";     MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -algo LYRA2V3" }
    [PSCustomObject]@{ Algorithm = "MTP";          MinMemGB = 3; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -algo MTP -intensity 21" } # CcminerMTP-v1.3.2 is faster
    [PSCustomObject]@{ Algorithm = "ProgPoW";      MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -algo PROGPOW" } # Zano, Sero
    [PSCustomObject]@{ Algorithm = "UbqHash";      MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " -algo UBQHASH -intensity 15" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            If ($Pools.($_.Algorithm).Epoch -gt 384) { Return }

            $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            $AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }

            If ($AvailableMiner_Devices) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 1GB -le 2 }) { $_.Arguments = $_.Arguments -replace " -intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Coin = ""
                If ($Pools.($_.Algorithm).Currency -in @("CKB", "CLO", "EPIC", "ERE", "ETC", "ETH", "ETP", "EXP", "HANA", "MUSIC", "PIRL", "SERO", "TCR", "UBQ", "VTC", "ZANO", "ZCOIN")) { 
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
                    Arguments   = ("$($_.Arguments) -pool stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -user $($Pools.($_.Algorithm).User)$Pass -work-timeout 500000$Coin -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "EthMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
