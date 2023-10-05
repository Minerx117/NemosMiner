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
Version:        5.0.1.0
Version date:   2023/10/05
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.OpenCL.ComputeCapability -ge "5.1" })) { Return }

$URI = "https://github.com/Minerx117/ccminer8.21r9-lyra2z330/releases/download/v3/ccminerlyra2z330v3.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Lyra2z330";   MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo lyra2z330 -intensity 12.5" } # Algorithtm is dead
#   [PSCustomObject]@{ Algorithm = "Yescrypt";    MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(75, 5); ExcludePools = @(); Arguments = " --algo yescrypt" } # Too many bad shares
    [PSCustomObject]@{ Algorithm = "YescryptR16"; MinMemGiB = 3; Minerset = 1; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo yescryptr16 --intensity 13.3" } # CcminerLyraYesscrypt-v8.21r18v5 is fastest
    [PSCustomObject]@{ Algorithm = "YescryptR32"; MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(60, 0); ExcludePools = @(); Arguments = " --algo yescryptr32 --intensity 12.3" } # CcminerLyraYesscrypt-v8.21r18v5 is fastest
    [PSCustomObject]@{ Algorithm = "YescryptR8";  MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo yescryptr8" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].PoolPorts[0] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object { $_.PoolPorts[0] } | Where-Object BaseName -notin $ExcludePools)) { 

                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    $Arguments = $_.Arguments
                    If ($AvailableMiner_Devices | Where-Object MemoryGiB -LE 2) { $Arguments = $Arguments -replace ' --intensity [0-9\.]+' }

                    [PSCustomObject]@{ 
                        API         = "CcMiner"
                        Arguments   = "$Arguments --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" }) --pass $($Pool.Pass) --statsavg 5 --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"
                        DeviceNames = $AvailableMiner_Devices.Name
                        MinerSet    = $_.MinerSet
                        Name        = $Miner_Name
                        Path        = $Path
                        Port        = $MinerAPIPort
                        Type        = "NVIDIA"
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                        Workers     = @(@{ Pool = $Pool })
                    }
                }
            }
        }
    }
}