<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           \Includes\MinerAPIs\EthMiner.ps1
Version:        5.0.2.6
Version date:   2023/12/28
#>

Class EthMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest -Server 127.0.0.1 -Port $this.Port -Request $Request -Timeout $Timeout -ErrorAction Stop
            $Data = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]$this.Algorithms[0]
        $HashRate_Value = [Double]($Data.result[2] -split ";")[0]
        If ($Data.result[0] -notmatch "^TT-Miner") { 
            If ($HashRate_Name -eq "EtcHash")          { $HashRate_Value *= 1000 }
            ElseIf ($HashRate_Name -eq "Ethash")       { $HashRate_Value *= 1000 }
            ElseIf ($HashRate_Name -eq "UbqHash")      { $HashRate_Value *= 1000 }
        }
        If ($HashRate_Name -eq "Neoscrypt")           { $HashRate_Value *= 1000 }
        ElseIf ($HashRate_Name -eq "BitcoinInterest") { $HashRate_Value *= 1000 }
        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]($Data.result[2] -split ";")[1]
        $Shares_Rejected = [Int64]($Data.result[2] -split ";")[2]
        $Shares_Invalid = [Int64]0
        $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }

        If ($HashRate_Name = [String]($this.Algorithms -ne $HashRate_Name)) { 
            $HashRate_Value = [Double]($Data.result[4] -split ";")[0]
            If ($this.Algorithms[0] -eq "Blake2s") { $HashRate_Value *= 1000 }
            If ($this.Algorithms[0] -eq "Keccak") { $HashRate_Value *= 1000 }
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

            $Shares_Accepted = [Int64]($Data.result[4] -split ";")[1]
            $Shares_Rejected = [Int64]($Data.result[4] -split ";")[2]
            $Shares_Invalid = [Int64]0
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }
        }

        $PowerConsumption = [Double]0

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = $this.GetPowerConsumption()
            }

            Return [PSCustomObject]@{ 
                Date             = ([DateTime]::Now).ToUniversalTime()
                HashRate         = $HashRate
                PowerConsumption = $PowerConsumption
                Shares           = $Shares
            }
        }
        Return $null
    }
}