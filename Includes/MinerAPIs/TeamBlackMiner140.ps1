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
File:           lolMiner.ps1
Version:        4.3.1.0
Version date:   02 March 2023
#>

class TeamBlackMiner140 : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0

        $Request = "http://127.0.0.1:$($this.Port)/pools"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]""
        $HashRate_Value = [Double]0

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0
        $Shares_Invalid = [Int64]0

        ForEach ($Algorithm in $this.Algorithms) { 
            $HashRate_Name = [String]$Algorithm
            $Data.Pool.PSObject.Properties.Name | ForEach-Object { 
                If ((Get-Algorithm $Data.Pool.$_.Algo) -eq $Algorithm) { 
                    $HashRate_Value = [Double]($Data.Pool.$_.total_hashrate)
                    $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

                    $Shares_Accepted = [Int64]($Data.Pool.$_.total_accepted)
                    $Shares_Rejected = [Int64]($Data.Pool.$_.total_rejected)
                    $Shares_Invalid =  [Int64]($Data.Pool.$_.total_stale)
                    $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }
                }
            }
        }

        If ($this.ReadPowerUsage) { 
            $PowerUsage = $this.GetPowerUsage()
        }

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
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