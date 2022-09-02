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
File:           ZergPool.ps1
Version:        4.2.1.0
Version date:   02 September 2022
#>

using module ..\Includes\Include.psm1

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$BrainName = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$BrainConfig = $Config.PoolsConfig.$BrainName.BrainConfig

$AlgoObject = @()
$APICallFails = 0
$CurrenciesData = @()
$TransferFile = "$($PWD)\Data\BrainData_$($BrainName).json"

$ProgressPreference = "SilentlyContinue"

# Fix TLS Version erroring
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

While ($BrainConfig) { 

    If ($BrainConfig.ShowStartStop) { Write-Message -Level Debug "Start Brain '$Brainname'." }

    $Duration = Measure-Command { 
        $CurDate = (Get-Date).ToUniversalTime()
        $PoolVariant = $Config.PoolName | Where-Object { $_ -match "$($BrainName)*" } 

        Do {
            Try { 
            $CurrenciesData = Invoke-RestMethod -Uri $BrainConfig.PoolCurrenciesUri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $BrainConfig.PoolAPITimeout
                If ($PoolVariant -match "Coins(|Plus)$") { 
                    $AlgoData = [PSCustomObject]@{ }
                    $CurrenciesArray = @()
                    # Add currency and convert to array for easy sorting
                    ($CurrenciesData | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
                        $CurrenciesData.$_ | Add-Member -Force @{ Currency = If ($CurrenciesData.$_.Symbol) { $CurrenciesData.$_.Symbol -replace "-.+" } Else { $_ -replace "-.+" } }
                        $CurrenciesArray += $CurrenciesData.$_
                    }

                    $CurrenciesArray | Group-Object algo | ForEach-Object { 
                        $BestCurrency = ($_.Group | Sort-Object estimate_current | Select-Object -First 1)
                        $BestCurrency | Add-Member coinname ($BestCurrency.name -replace "coin$", "Coin" -replace "hash$", "Hash") -Force
                        $BestCurrency | Add-Member name $BestCurrency.algo -Force
                        # $BestCurrency | Add-Member estimate_last24h $BestCurrency.estimate_last24
                        $BestCurrency.PSObject.Properties.Remove("algo")
                        # $BestCurrency.PSObject.Properties.Remove("estimate_last24")
                        $BestCurrency.PSObject.Properties.Remove("symbol")
                        $AlgoData | Add-Member $BestCurrency.name $BestCurrency
                    }
                }
                Else{ 
                    $AlgoData = Invoke-RestMethod -Uri $BrainConfig.PoolStatusUri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $BrainConfig.PoolAPITimeout
                }
                $APICallFails = 0
            }
            Catch { 
                $APICallFails++
                Start-Sleep -Seconds ($APICallFails * $BrainConfig.PoolAPIRetryInterval)
            }
        } While (-not $AlgoData)

        ForEach ($Algo in (($AlgoData | Get-Member -MemberType NoteProperty).Name)) { 
            If (-not $AlgoData.$Algo.currency) { 
                $Currencies = @(($CurrenciesData | Get-Member -MemberType NoteProperty).Name | Where-Object { $CurrenciesData.$_.algo -eq $Algo } | ForEach-Object { $CurrenciesData.$_ })
                $Currency = If ($Currencies.Symbol) { ($Currencies | Sort-Object Estimate)[-1].Symbol } Else { "" }
                $AlgoData.$Algo | Add-Member @{ Currency = $Currency.Trim() }
            }

            $AlgoData.$Algo.estimate_last24h = [Double]$AlgoData.$Algo.estimate_last24h
            If ($AlgoData.$Algo.actual_last24h) { $AlgoData.$Algo.actual_last24h = [Double]($AlgoData.$Algo.actual_last24h / 1000) }
            # If ($AlgoData.$Algo.actual_last24h_shared) { $AlgoData.$Algo.actual_last24h_shared = [Double]($AlgoData.$Algo.actual_last24h_shared / 1000) }
            # If ($AlgoData.$Algo.actual_last24h_solo) { $AlgoData.$Algo.actual_last24h_solo = [Double]($AlgoData.$Algo.actual_last24h_solo / 1000) }
            $BasePrice = If ($AlgoData.$Algo.actual_last24h) { [Double]$AlgoData.$Algo.actual_last24h } Else { [Double]$AlgoData.$Algo.estimate_last24h }
            $AlgoData.$Algo.estimate_current = [math]::max(0, [Double]($AlgoData.$Algo.estimate_current * ( 1 - ($BrainConfig.PoolAPIPerFailPercentPenalty * [math]::max(0, $APICallFails - $BrainConfig.PoolAPIAllowedFailureCount) / 100))))
            $AlgoObject += [PSCustomObject]@{
                Date               = $CurDate
                Name               = $AlgoData.$Algo.name
                Port               = $AlgoData.$Algo.port
                Coins              = $AlgoData.$Algo.coins
                CoinName           = $AlgoData.$Algo.CoinName
                Currency           = $AlgoData.$Algo.Currency
                Fees               = $AlgoData.$Algo.Fees
                Hashrate           = $AlgoData.$Algo.Hashrate
                Workers            = $AlgoData.$Algo.Workers
                estimate_current   = $AlgoData.$Algo.estimate_current -as [Double]
                estimate_last24h   = $AlgoData.$Algo.estimate_last24h
                actual_last24h     = $BasePrice
                hashrate_last24h   = $AlgoData.$Algo.hashrate_last24h
                Last24Drift        = $AlgoData.$Algo.estimate_current - $BasePrice
                Last24DriftSign    = If (($AlgoData.$Algo.estimate_current - $BasePrice) -ge 0) { "Up" } Else { "Down" }
                Last24DriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algo.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                FirstDate          = $AlgoObject[0].Date
                TimeSpan           = If ($null -ne $AlgoObject.Date) { (New-TimeSpan -Start ($AlgoObject[0]).Date -End $CurDate).TotalMinutes }
            }
        }

        If ($PoolVariant -match "Plus$") {
            # Created here for performance optimization, minimize # of lookups
            $CurAlgoObject = $AlgoObject | Where-Object { $_.date -eq $CurDate }
            $SampleSizets = New-TimeSpan -Minutes $BrainConfig.SampleSizeMinutes
            $SampleSizeHalfts = New-TimeSpan -Minutes ($BrainConfig.SampleSizeMinutes / 2)
            $GroupAvgSampleSize = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name, Last24DriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
            $GroupMedSampleSize = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
            $GroupAvgSampleSizeHalf = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name, Last24DriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
            $GroupMedSampleSizeHalf = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
            $GroupMedSampleSizeNoPercent = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24Drift } }

            ForEach ($Name in ($AlgoObject.Name | Select-Object -Unique)) { 
                $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Median)
                $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | Where-Object { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSizeNoPercent | Where-Object { $_.Name -eq $Name }).Median)
                $Penalty = ($PenaltySampleSizeHalf * $BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($BrainConfig.SampleHalfPower + 1)
                $Price = [math]::max(0, [Double](($Penalty) + ($CurAlgoObject | Where-Object { $_.Name -eq $Name }).actual_last24h))
                If ($BrainConfig.UseFullTrust) { 
                    If ($Penalty -gt 0) { 
                        $Price = [Math]::max([Double]$Price, [Double]($CurAlgoObject | Where-Object { $_.Name -eq $Name }).estimate_current)
                    }
                    Else { 
                        $Price = [Math]::min([Double]$Price, [Double]($CurAlgoObject | Where-Object { $_.Name -eq $Name }).estimate_current)
                    }
                }
                $AlgoData.$Name | Add-Member -Force @{ Plus_Price = $Price }
            }
        }

        ($AlgoData | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
            If ([Double]($AlgoData.$_.actual_last24h_shared) -gt 0) { 
                $AlgoData.$_ | Add-Member Updated $CurDate -Force
            }
            Else { 
                $AlgoData.PSObject.Properties.Remove($_)
            }
        }

        $Variables.BrainData | Add-Member $BrainName $AlgoData -Force

        If ($BrainConfig.UseTransferFile) { 
            ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -FilePath $TransferFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        }

        # Limit to only sample size + 10 minutes min history
        $AlgoObject = $AlgoObject | Where-Object { $_.Date -ge $CurDate.AddMinutes(-($BrainConfig.SampleSizeMinutes + 10)) }

        Remove-Variable AlgoData, BasePrice, CurAlgoObject, CurrenciesData, Currencies, Currency, SampleSizeHalfts, SampleSizets, GroupAvgSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSize, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, Name, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, Price -ErrorAction Ignore
    }

    If ($BrainConfig.ShowStartStop) { Write-Message -Level Debug "End Brain '$Brainname' ($($Duration.TotalSeconds) sec.)." }

    Do { 
        Start-Sleep -Seconds 3
    } While (-not $Variables.Miners -or $CurDate -gt $Variables.PoolDataCollectedTimeStamp -or (Get-Date).ToUniversalTime().AddSeconds([Int]$Duration.TotalSeconds + 5) -lt $Variables.EndCycleTime)

    $BrainConfig = $Config.PoolsConfig.$BrainName.BrainConfig

    [System.GC]::Collect()
}