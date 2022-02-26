using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices = $Devices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.Type -eq"NVIDIA" })) { Return }

$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/2.75/gminer_2_75_windows64.zip"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs 

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Equihash1927";  Fee = 0.02; MinMemGB = 2.8; Type = "AMD"; MinerSet = 1; WarmupTimes = @(30, 0); Arguments = " --algo equihash192_7 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.46a is fastest

    [PSCustomObject]@{ Algorithm = "Equihash1927";  Fee = 0.02; MinMemGB = 2.8; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(30, 0); Arguments = " --algo equihash192_7 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.8y4rc2 is fastest
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            # Windows 10 requires more memory on some algos
            If ($_.Algorithm -match "Cuckaroo*|Cuckoo*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGB += 1 }

            $AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }

            If ($AvailableMiner_Devices) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "cuda", "opencl", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --server $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass)"
                If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { $_.Arguments += ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" }
                If ($Pools.($_.Algorithm).DAGsize -ne $null -and $Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --proto stratum" }
                If ($Pools.($_.Algorithm).SSL) { $_.Arguments += " --ssl true --ssl_verification false" }

                # Apply tuning parameters
                If ($Config.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                # Contest ETH address (if ETH wallet is specified in config)
                # $_.Arguments += If ($Config.Wallets.ETH) { " --contest_wallet $($Config.Wallets.ETH)" } Else { " --contest_wallet 0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $_.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --api $($MinerAPIPort) --watchdog 0 --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "Gminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}