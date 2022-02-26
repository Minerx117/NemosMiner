using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices | Where-Object { $_.Type -eq "NVIDIA" -and $_.OpenCL.ComputeCapability -ge 6.0 })) { Return }

$Uri = Switch ($DriverVersion.CUDA) { 
    { $_ -ge "11.4" } { "https://github.com/KlausT/ccminer/releases/download/8.26/ccminer-826-cuda114-x64.zip" }
    Default { Return }
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "C11";       MinMemGB = 2; MinerSet = 2; WarmupTimes = @(60, 0);  Arguments = " --algo c11 --intensity 22" } # CcminerAlexis78-v1.5.2 is faster
    [PSCustomObject]@{ Algorithm = "Keccak";    MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo keccak --diff-multiplier 2 --intensity 29" }
    [PSCustomObject]@{ Algorithm = "Lyra2RE2";  MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo lyra2v2" }
    [PSCustomObject]@{ Algorithm = "NeoScrypt"; MinMemGB = 2; MinerSet = 2; WarmupTimes = @(30, 0);  Arguments = " --algo neoscrypt --intensity 15.5" } # CryptoDredge-v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Skein";     MinMemGB = 2; MinerSet = 2; WarmupTimes = @(30, 0);  Arguments = " --algo skein" } # CcminerAlexis78-v1.5.2 is fastest
    [PSCustomObject]@{ Algorithm = "Veltor";    MinMemGB = 2; MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo veltor --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Whirlcoin"; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo whirlcoin" }
    [PSCustomObject]@{ Algorithm = "Whirlpool"; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo whirlpool" }
    [PSCustomObject]@{ Algorithm = "X11evo";    MinMemGB = 2; MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo x11evo --intensity 21" }
    [PSCustomObject]@{ Algorithm = "X17";       MinMemGB = 2; MinerSet = 2; WarmupTimes = @(60, 15); Arguments = " --algo x17 --intensity 22" } # CcminerAlexis78-v1-5-2 is faster
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host } | Where-Object { -not $Pools.($_.Algorithm).SSL }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 1GB -le 2 }) { $_.Arguments = $_.Arguments -replace " --intensity [0-9\.]+" }
                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = "NVIDIA"
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "Ccminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}