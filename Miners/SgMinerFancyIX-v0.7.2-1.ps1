using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\sgminer.exe"
$Uri = "https://github.com/fancyIX/sgminer-phi2-branch/releases/download/0.7.2-1/sgminer-fancyIX-win64-0.7.2-1.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "NeoscryptXaya"; MinerSet = 0; Arguments = " -k neoscrypt-xaya -s 1 -w 256 -I 17" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "AMD" | Select-Object Model -Unique | ForEach-Object { 

        If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            $AlgorithmDefinitions | ForEach-Object { 

                # Get arguments for active miner devices
                # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                $Protocol = "stratum+tcp"
                If ($Pools.($_.Algorithm).SSL) { $Protocol = $Protocol -replace "tcp", "ssl" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $Miner_Devices.Name
                    Type        = "AMD"
                    Path        = $Path
                    Arguments    = ("$($_.Arguments) --url $($Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --api-listen --api-port $MinerAPIPort --gpu-platform $($Miner_Devices.PlatformId | Sort-Object -Unique) --device $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "Xgminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    WaitForData = 30 # Seconds, additional wait time until first data sample, wait for JIT compiler
                }
            }
        }
    }
}