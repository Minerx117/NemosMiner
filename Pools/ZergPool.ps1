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
File:           ZergPool.ps1
Version:        4.3.4.5
Version date:   30 April 2023
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $Variables.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$HostSuffix = "mine.zergpool.com"
$PayoutCurrency = $PoolConfig.Wallets.Keys | Select-Object -First 1
$Regions = If ($Config.UseAnycast -and $PoolConfig.Region -contains "n/a (Anycast)") { "n/a (Anycast)" } Else { $PoolConfig.Region | Where-Object { $_ -ne "n/a (Anycast)" }  }
$Wallet = $PoolConfig.Wallets.$PayoutCurrency
$TransferFile = (Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Data\BrainData_" + (Get-Item $MyInvocation.MyCommand.Path).BaseName + ".json"

If ($DivisorMultiplier -and $Regions -and $Wallet) {

    $StartTime = (Get-Date)
    Write-Message -Level Debug "Pool '$($Name) (Variant $($PoolVariant))': Start loop"

    $PayoutThreshold = $PoolConfig.PayoutThreshold.$PayoutCurrency
    If (-not $PayoutThreshold -and $PoolConfig.PayoutThreshold.mBTC) { $PayoutThreshold = $PoolConfig.PayoutThreshold.mBTC / 1000 }
    $PayoutThresholdParameter = ",pl=$([Double]$PayoutThreshold)"

    Try { 
        If ($Variables.Brains.$Name) { 
            $Request = $Variables.BrainData.$Name
        }
        Else { 
            $Request = Get-Content $TransferFile -ErrorAction Stop | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request.PSObject.Properties.Name) { Return }

    $Request.PSObject.Properties.Name | ForEach-Object { 
        $Algorithm = $Request.$_.algo
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$_.currency)".Trim() -replace "-.+$"
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor
        $Fee = $Request.$_.Fees / 100

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ($Request.$_.$PriceField / $Divisor) -FaultDetection $false

        $Reasons = [System.Collections.Generic.List[String]]@()
        If ($Request.$_.noautotrade -eq 1 -and $Request.$_.Currency -ne $PayoutCurrency) { $Reasons.Add("Conversion disabled at pool") }
        If ($Request.$_.hashrate_shared -eq 0) { $Reasons.Add("No hashrate at pool") }
        If ($PoolVariant -match ".+Plus$" -and $Request.$_.$PriceField -eq 0) { $Reasons.Add("Plus price -eq 0")}

        ForEach ($Region_Norm in $Variables.Regions.($Config.Region)) { 
            If ($Region = $Regions | Where-Object { $_ -eq "n/a (Anycast)" -or (Get-Region $_) -eq $Region_Norm }) { 

                If ($Region -eq "n/a (Anycast)") { 
                    $PoolHost = "$Algorithm.$HostSuffix"
                    $Region_Norm = $Region
                }
                Else { 
                    $PoolHost = "$Algorithm.$Region.$HostSuffix"
                }

                [PSCustomObject]@{ 
                    Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
                    Algorithm                = [String]$Algorithm_Norm
                    BaseName                 = [String]$Name
                    Currency                 = [String]$Currency
                    Disabled                 = [Boolean]$Stat.Disabled
                    EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                    Fee                      = [Decimal]$Fee
                    Host                     = [String]$PoolHost
                    Name                     = [String]$PoolVariant
                    Pass                     = "c=$PayoutCurrency$(If ($Currency) { ",mc=$Currency" }),ID=$($PoolConfig.WorkerName)$PayoutThresholdParameter"
                    Port                     = If ($PoolConfig.SSL -eq "Always") { 0 } Else { [UInt16]$Request.$_.port }
                    PortSSL                  = If ($PoolConfig.SSL -eq "Never") { 0 } Else { [UInt16]$Request.$_.tls_port }
                    Price                    = [Double]$Stat.Live
                    Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratum2" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Reasons                  = $Reasons
                    Region                   = [String]$Region_Norm
                    SendHashrate             = $false
                    SSLSelfSignedCertificate = $true
                    StablePrice              = [Double]$Stat.Week
                    Updated                  = [DateTime]$Request.$_.Updated
                    User                     = [String]$Wallet
                    Workers                  = [Int]$Request.$_.workers_shared
                    WorkerName               = ""
                }
                Break
            }
        }
    }

    Write-Message -Level Debug "Pool '$($Name) (Variant $($PoolVariant))': End loop (Duration: $(((Get-Date) - $StartTime).TotalSeconds) sec.)"
}

$Error.Clear()