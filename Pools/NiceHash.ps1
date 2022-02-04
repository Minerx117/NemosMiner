<#
Copyright (c) 2018-2022 Nemo, MrPlus & UselessGuru


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
File:           NiceHash.ps1
Version:        4.0.0.18 (RC18)
Version date:   04 February 2022
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $PoolsConfig.(Get-PoolName $Name)
$Fee = $PoolConfig.Variant.$PoolVariant.Fee
$PayoutCurrency = $PoolConfig.Variant.$PoolVariant.Wallets.PSObject.Properties.Name | Select-Object -First 1
$Wallet = $PoolConfig.Variant.$PoolVariant.Wallets.$PayoutCurrency
$User = "$Wallet.$($PoolConfig.WorkerName -replace "^ID=")"

If ($Wallet) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" #-Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
        $RequestAlgodetails = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/mining/algorithms/" #-Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
        $Request.miningAlgorithms | ForEach-Object { $Algo = $_.Algorithm; $_ | Add-Member -Force @{ algodetails = $RequestAlgodetails.miningAlgorithms | Where-Object { $_.Algorithm -eq $Algo } } }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $PoolHost = "nicehash.com"

    $Request.miningAlgorithms | Where-Object speed -GT 0 | Where-Object { $_.algodetails.order -gt 0 } | ForEach-Object { 
        $Algorithm = $_.Algorithm
        $Algorithm_Norm = Get-Algorithm $Algorithm

        $Currency = Switch -Regex ($Algorithm_Norm) {
            "BeamHash3"                 { "BEAM" }
            "CuckooCycle"               { "AE" }
            "Cuckaroo29"                { "XBG" }
            "Cuckarood29"               { "MWC" }
            "^Cuckatoo31$|^Cuckatoo32$" { "GRIN" }
            "Eaglesong"                 { "CKB" }
            "EquihashR25x5x3"           { "BEAM" }
            "EquihashBTG"               { "BTG" }
            "KawPoW"                    { "RVN" }
            "Lbry"                      { "LBC" }
            "RandomX"                   { "XMR" }
            "Octopus"                   { "CFX" }
            Default                     { "" }
        }

        $Port = $_.algodetails.port
        # $DivisorMultiplier = 1000000000
        # $Divisor = $DivisorMultiplier * [Double]$_.Algodetails.priceFactor
        $Divisor = 100000000

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)_Profit" -Value ([Double]$_.paying / $Divisor) -FaultDetection $false

        ForEach ($Region in $PoolConfig.Region) { 
            $Region_Norm = Get-Region $Region

            # ForEach ($SSL in @($false <#, $true#>)) { 
            ForEach ($SSL in @($false, $true)) { 
                [PSCustomObject]@{ 
                    Name                     = [String]$PoolVariant
                    BaseName                 = [String]$Name
                    Algorithm                = [String]$Algorithm_Norm
                    Currency                 = [String]$Currency
                    Price                    = [Double]$Stat.Live
                    StablePrice              = [Double]$Stat.Week
                    Accuracy                 = [Double](1 - $Stat.Week_Fluctuation)
                    EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                    Host                     = "$Algorithm.$Region.$PoolHost".ToLower()
                    Port                     = [UInt16]$Port
                    User                     = [String]$User
                    Pass                     = "x"
                    Region                   = [String]$Region_Norm
                    SSL                      = $SSL
                    Fee                      = [Decimal]$PoolConfig.Fee
                    EstimateFactor           = [Decimal]1
                }
            }
        }
    }
}
