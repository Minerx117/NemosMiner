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
File:           \Includes\MinerAPIs\Rigel.ps1
Version:        4.3.6.2
Version date:   2023/08/25
#>

Class Rigel : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/stat"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = ""
        $Hashrate_Value = [Double]0
        $Algorithms = [String[]]@($Data.algorithm -split "\+")
        $Algorithm = $Algorithms[0]

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = $Shares_Rejected = $Shares_Invalid = [Int64]0

        ForEach ($Algorithm in $Algorithms) { 
            $HashRate_Name = $this.Algorithms | Select-Object -Index $Algorithms.IndexOf($Algorithm)
            $HashRate_Value = [Double]$Data.hashrate.$Algorithm
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

            $Shares_Accepted = [Int64]$Data.solution_stat.$Algorithm.accepted
            $Shares_Rejected = [Int64]$Data.solution_stat.$Algorithm.rejected
            $Shares_Invalid = [Int64]$Data.solution_stat.$Algorithm.invalid
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }
        }

        $PowerUsage = [Double]0

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            If ($this.ReadPowerUsage) { 
                $PowerUsage = [Double]$Data.power_usage
                If (-not $PowerUsage) { 
                    $PowerUsage = $this.GetPowerUsage()
                }
            }

            Return [PSCustomObject]@{ 
                Date       = (Get-Date).ToUniversalTime()
                HashRate   = $HashRate
                PowerUsage = $PowerUsage
                Shares     = $Shares
            }
        }
        Return $null
    }
}