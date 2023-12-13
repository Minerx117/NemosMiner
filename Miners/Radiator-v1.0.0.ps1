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
Version:        5.0.2.3
Version date:   2023/10/06
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.6" } { "https://github.com/xiaolin1579/radiator/releases/download/v1.0.0/Radiator1.0.0_cuda11.6_Win64.zip"; Break }
    { $_ -ge "11.2" } { "https://github.com/xiaolin1579/radiator/releases/download/v1.0.0/Radiator1.0.0_cuda11.2_Win64.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "SHA512256d"; MinMemGiB = 2; MinerSet = 1; WarmupTimes = @(90, 0); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo=rad" }
    [PSCustomObject]@{ Algorithm = "SHA256dt";   MinMemGiB = 2; MinerSet = 1; WarmupTimes = @(90, 0); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo=novo" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Select-Object Model -Unique).ForEach(
        { 
            $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
            $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $ExcludePools = $_.ExcludePools
                    ForEach ($Pool in ($MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $_.Name -notin $ExcludePools }))) { 

                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        $MinMemGiB  = $_.MinMemGiB 
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB -and $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                            $Arguments = $_.Arguments
                            If ($AvailableMiner_Devices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace ' --intensity [0-9\.]+' }

                            [PSCustomObject]@{ 
                                API         = "CcMiner"
                                Arguments   = "$Arguments --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMiner_Devices.Name
                                Fee         = @(0) # Dev fee
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
            )
        }
    )
}