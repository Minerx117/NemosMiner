﻿<#
Copyright (c) 2018-2021 Nemo, MrPlus & UselessGuru

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
File:           NBMiner.ps1
Version:        3.9.9.26
Version date:   18 March 2021
#>

using module ..\Include.psm1

class NBMiner : Miner { 
    [Object]UpdateMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/api/v1/status"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        $HashRate_Name = $this.Algorithm | Select-Object -Last 1

        $HashRate_Value = [Double]$Data.miner.total_hashrate_raw
        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        If ($this.AllowedBadShareRatio) { 
            $Shares_Accepted = [Int64]$Data.stratum.accepted_shares
            $Shares_Rejected = [Int64]$Data.stratum.rejected_shares
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
        }

        If ($Data.stratum.dual_mine) { 
            $HashRate_Name = [String]($this.Algorithm -ne $HashRate_Name)
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$Data.miner.total_hashrate2_raw }

            If ($this.AllowedBadShareRatio) { 
                $Shares_Accepted = [Int64]$Data.stratum.accepted_shares2
                $Shares_Rejected = [Int64]$Data.stratum.rejected_shares2
                $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
            }
        }

        If ($this.CalculatePowerCost) { 
            $PowerUsage = $this.GetPowerUsage()
        }

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            $Sample = [PSCustomObject]@{ 
                Date       = (Get-Date).ToUniversalTime()
                HashRate   = $HashRate
                PowerUsage = $PowerUsage
                Shares     = $Shares
            }
            Return $Sample
        }
        Return $null
    }
}

