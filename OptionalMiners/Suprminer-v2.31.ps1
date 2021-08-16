using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\suprminer.exe"
$Uri = "https://github.com/ocminer/suprminer-releases/raw/main/suprminer-winx86_64_cuda11_1.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "HeavyHash"; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --algo obtc" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object { -not $Pools.($_.Algorithm).SSL } | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "statsavg") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = "NVIDIA"
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --retry-pause 1 --api-bind $MinerAPIPort --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "Ccminer"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = 0.01
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates, second value: extra time (in seconds) until miner must send first valid sample
                    }
                }
            }
        }
    }
}
