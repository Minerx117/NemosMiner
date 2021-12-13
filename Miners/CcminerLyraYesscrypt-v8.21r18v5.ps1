using module ..\Includes\Include.psm1

$Path = ".\Bin\NVIDIA-CcmineryescryptrV5\ccminer.exe"
$Path = ".\Bin\$($Name)\ccminer.exe"
$Uri = "https://github.com/Minerx117/ccminer/releases/download/8.21-r18-v5/ccmineryescryptrV5.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";    MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo lyra2v3 --intensity 24 --statsavg 5" }
#    [PSCustomObject]@{ Algorithm = "Lyra2z330";   MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo lyra2z330 --intensity 13.2 --timeout 1 --statsavg 5" } #only runs on single gpu's
#    [PSCustomObject]@{ Algorithm = "Yescrypt";    MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --algo yescrypt --statsavg 5" } # bad shares, CcminerLyra2z330-v8.21r9 is fastest
    [PSCustomObject]@{ Algorithm = "YescryptR16"; MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo yescryptr16 --intensity 13.2 --statsavg 5" }
#    [PSCustomObject]@{ Algorithm = "YescryptR32"; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo yescryptr32 --intensity 12.23 --statsavg 5" } # Out of memory even with 6GB
    [PSCustomObject]@{ Algorithm = "YescryptR8";  MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo yescryptr8 --intensity 13.2 --statsavg 5" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host } | Where-Object { -not $Pools.($_.Algorithm).SSL }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ConvertTo-Json | ConvertFrom-Json | ForEach-Object {

                If ($_.Algorithm -eq "Lyra2RE3" -and $Pools.($_.Algorithm).Name -like "MiningPoolHub*") { Return } # Temp fix
                If ($_.Algorithm -eq "Yescrypt" -and $Pools.($_.Algorithm).Currency -ne "BSTY") { Return } # Temp fix

                $MinMemGB = $_.MinMemGB

                If ($AvailableMiner_Devices = @($Miner_Devices | Where-Object { [Uint]($_.OpenCL.GlobalMemSize / 0.99GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                    If ($AvailableMiner_Devices | Where-Object { [Uint]($_.OpenCL.GlobalMemSize / 0.99GB) -le 2 }) { $_.Arguments = $_.Arguments -replace " --intensity [0-9\.]+" }
                    # Get arguments for available miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "timeout") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $AvailableMiner_Devices.Name
                        Type        = "NVIDIA"
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "Ccminer"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
