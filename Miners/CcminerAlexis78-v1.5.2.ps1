If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = "https://github.com/Minerx117/ccmineralexis78/releases/download/v1.5.2/ccmineralexis78.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "C11";       MinMemGB = 3; Minerset = 1; WarmupTimes = @(60, 0); Arguments = " --algo c11 --intensity 22" }
    [PSCustomObject]@{ Algorithm = "Keccak";    MinMemGB = 3; Minerset = 3; WarmupTimes = @(45, 0); Arguments = " --algo keccak --diff-multiplier 2 --intensity 29" } # ASIC
    [PSCustomObject]@{ Algorithm = "Lyra2RE2";  MinMemGB = 3; Minerset = 3; WarmupTimes = @(30, 0); Arguments = " --algo lyra2v2" } # ASIC
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(30, 0); Arguments = " --algo neoscrypt --intensity 15.5" } # FPGA
    [PSCustomObject]@{ Algorithm = "Skein";     MinMemGB = 3; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo skein" } # FPGA
    [PSCustomObject]@{ Algorithm = "Skein2";    MinMemGB = 3; MinerSet = 0; WarmupTimes = @(60, 0); Arguments = " --algo skein2 --intensity 31.9" }
    [PSCustomObject]@{ Algorithm = "Veltor";    MinMemGB = 2; Minerset = 2; WarmupTimes = @(40, 0); Arguments = " --algo veltor --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Whirlcoin"; MinMemGB = 2; Minerset = 2; WarmupTimes = @(30, 0); Arguments = " --algo whirlcoin" }
    [PSCustomObject]@{ Algorithm = "Whirlpool"; MinMemGB = 2; Minerset = 2; WarmupTimes = @(40, 0); Arguments = " --algo whirlpool" }
    [PSCustomObject]@{ Algorithm = "X11evo";    MinMemGB = 2; Minerset = 2; WarmupTimes = @(40, 0); Arguments = " --algo x11evo --intensity 21" }
    [PSCustomObject]@{ Algorithm = "X17";       MinMemGB = 3; MinerSet = 1; WarmupTimes = @(30, 0); Arguments = " --algo x17 --intensity 22" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts } | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ForEach-Object { 

            $Arguments = $_.Arguments

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGB -le 2) { $Arguments = $Arguments -replace " --intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    API         = "Ccminer"
                    Arguments   = ("$($Arguments) --url stratum+tcp://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --retry-pause 1 --api-bind $MinerAPIPort --cuda-schedule 2 --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
                    DeviceNames = $AvailableMiner_Devices.Name
                    MinerSet    = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
