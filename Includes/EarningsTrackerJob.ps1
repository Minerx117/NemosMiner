<#
Copyright (c) 2018 MrPlus
EarningsTrackerJob.ps1 Written by MrPlusGH https://github.com/MrPlusGH

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           EarningsTrackerJob.ps1
version:        3.8.1.3
version date:   12 November 2019
#>

# To start the job one could use the following
# $job = Start-Job -FilePath .\EarningTrackerJob.ps1 -ArgumentList $params
# Remove progress info from job.childjobs.Progress to avoid memory leak

(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$args[0].GetEnumerator() | ForEach-Object { New-Variable -Name $_.Key -Value $_.Value }

If ($WorkingDirectory) { Set-Location $WorkingDirectory }

#Start the log
If ($Transcript) { Start-Transcript -Path ".\Logs\EarningTracker-$(Get-Date -Format "yyyy-MM-dd").log" -Append -Force | Out-Null }

If (Test-Path ".\Logs\EarningTrackerData.json") { $AllBalanceObjects = @(Get-Content ".\logs\EarningTrackerData.json" | ConvertFrom-Json) } Else { $AllBalanceObjects = @() }

$TrustLevel = 0
$StartTime = $LastAPIUpdateTime = (Get-Date).ToUniversalTime()
$BalanceObject = [PSCustomObject]@{ }

#To be removed: Fix typo in field name, convert date format
If (Test-Path -Path ".\Logs\DailyEarnings.csv" -PathType Leaf) { 
    $DailyEarnings = @(Import-Csv ".\Logs\DailyEarnings.csv" -ErrorAction SilentlyContinue)

    If ($DailyEarnings.PrePaimentDayValue | Select-Object) { 
        $DailyEarnings = $DailyEarnings | ForEach-Object  { 
            [PSCustomObject]@{
                Date               = [DateTime]::parseexact($_.Date, "MM/dd/yyyy", $null).ToShortDateString()
                Pool               = $_.Pool
                DailyEarnings      = $_.DailyEarnings
                StartTime          = ([DateTime]($_.FirstDayDate)).ToLongTimeString()
                StartValue         = $_.FirstDayValue
                EndTime            = ([DateTime]($_.LastDayDate)).ToLongTimeString()
                EndValue           = $_.LastDayValue
                PrePaymentDayValue = $_.PrePaimentDayValue
                Balance            = $_.Balance
                BTCD               = $_.BTCD
            }
        }
        $DailyEarnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation -Force
    }
    Remove-Variable DailyEarnings
}

While ($true) { 

    $CurDateTime = (Get-Date).ToUniversalTime()

    #Read Config (ie. Pools to track)
    $EarningsTrackerConfig = Get-content ".\Config\EarningTrackerConfig.json" | ConvertFrom-Json
    $Interval = $EarningsTrackerConfig.PollInterval
    
    #Filter pools variants
    $TrackPools = @(($EarningsTrackerConfig.pools) -replace "24hr" -replace "coins") | Sort-Object -Unique

    # Get pools api ref
    If (-not $PoolAPI -or ($LastAPIUpdateTime -le (Get-Date).ToUniversalTime().AddDays(-1))) { 
        Try { 
            $PoolAPI = Invoke-WebRequest "https://raw.githubusercontent.com/Minerx117/UpDateData/master/poolapiref.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
            $PoolAPI | ConvertTo-Json | Out-File ".\Config\poolapiref.json" -Force
            $LastAPIUpdateTime = Get-Date
        }
        Catch { 
            $PoolAPI = Get-Content ".\Config\poolapiref.json" | ConvertFrom-Json
        }
    }

    #For each pool in config
    #Go loop
    $PoolNamesToTrack = @($PoolAPI | Where-Object EarnTrackSupport -EQ "yes" | Where-Object Name -in $TrackPools ).Name | ForEach-Object { $_ -replace "24hr" -replace "coins" } | Sort-Object -Unique
    $PoolAPI | Where-Object Name -in $PoolNamesToTrack | ForEach-Object { 
        $Pool = $_.Name
        $APIUri = $_.WalletUri
        $PaymentThreshold = $_.PaymentThreshold
        $BalanceData = [PSCustomObject]@{ }
        $BalanceJson = $_.Balance
        $TotalJson = $_.Total
        $PoolAccountUri = $_.AccountUri

        $ConfName = If ($PoolsConfig.$Pool -ne $null) { $Pool } Else { "Default" }
        $PoolConf = $PoolsConfig.$ConfName

        If ($Pool -eq "mph") { 
            $Wallet = $PoolConf.APIKey
        }
        Else { 
            $Wallet = $PoolConf.Wallet
        }

        Switch ($Pool) { 
            "NicehashV2" { 
                Try { 
                    $BalanceData = Invoke-WebRequest ("$($APIUri)$($Wallet)/rigs2") -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json 
                    [Double]$NHTotalBalance = [Double]($BalanceData.unpaidAmount) + [Double]($BalanceData.externalBalance)
                    $BalanceData | Add-Member -NotePropertyName $BalanceJson -NotePropertyValue $NHTotalBalance -Force
                    $BalanceData | Add-Member -NotePropertyName $TotalJson -NotePropertyValue $NHTotalBalance -Force
                    $BalanceData | Add-Member Currency "BTC" -ErrorAction Ignore
                }
                Catch { }
            }
            "MPH" { 
                Try { 
                    $BalanceData = ((((Invoke-WebRequest ("$($APIUri)$($Wallet)") -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" }).content | ConvertFrom-Json).getuserallbalances).data | Where-Object { $_.coin -eq "bitcoin" })
                    $BalanceData | Add-Member Currency "BTC" -ErrorAction Ignore
                }
                Catch { }
            }
            Default { 
                Try { 
                    $BalanceData = Invoke-WebRequest ("$($APIUri)$($Wallet)") -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json 
                    $PoolAccountUri = "$($PoolAccountUri -replace '\[currency\]', $PoolConf.PasswordCurrency)$Wallet"
                }
                Catch { }
            }
        }
        If ($BalanceData.$TotalJson -gt 0) { 
            $AllBalanceObjects += $BalanceObject = [PSCustomObject]@{ 
                Pool         = $Pool
                Date         = $CurDateTime
                Balance      = $BalanceData.$BalanceJson
                Unsold       = $BalanceData.unsold
                Total_unpaid = $BalanceData.total_unpaid
                Total_paid   = $BalanceData.total_paid
                Total_earned = ($BalanceData.$BalanceJson, $BalanceData.$TotalJson | Measure-Object -Minimum).Minimum # Pool reduced earnings!
                Currency     = $BalanceData.currency
            }

            $BalanceObjects = @($AllBalanceObjects | Where-Object { $_.Pool -eq $Pool } | Sort-Object Date)

            If ((($CurDateTime - ($BalanceObjects[0].Date)).TotalMinutes) -eq 0) { $CurDateTime = $CurDateTime.AddMinutes(1) }
            If ((($CurDateTime - ($BalanceObjects[0].Date)).TotalDays) -ge 1) { 
                $Growth1 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDateTime.AddHours(-1) }).total_earned | Measure-Object -Minimum).Minimum
                $Growth6 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDateTime.AddHours(-6) }).total_earned | Measure-Object -Minimum).Minimum
                $Growth24 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDateTime.AddDays(-1) }).total_earned | Measure-Object -Minimum).Minimum
            }
            If ((($CurDateTime - ($BalanceObjects[0].Date)).TotalDays) -lt 1) { 
                $Growth1 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDateTime.AddHours(-1) }).total_earned | Measure-Object -Minimum).Minimum
                $Growth6 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDateTime.AddHours(-6) }).total_earned | Measure-Object -Minimum).Minimum
                $Growth24 = (($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($CurDateTime - ($BalanceObjects[0].Date)).TotalHours) * 24
            }
            If ((($CurDateTime - ($BalanceObjects[0].Date)).TotalHours) -lt 6) { 
                $Growth1 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDateTime.AddHours(-1) }).total_earned | Measure-Object -Minimum).Minimum
                $Growth6 = (($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($CurDateTime - ($BalanceObjects[0].Date)).TotalHours) * 6
            }
            If ((($CurDateTime - ($BalanceObjects[0].Date)).TotalHours) -lt 1) { 
                $Growth1 = (($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($CurDateTime - ($BalanceObjects[0].Date)).TotalMinutes) * 60
            }

            $AvgBTCHour = If ((($CurDateTime - ($BalanceObjects[0].Date)).TotalHours) -ge 1) { (($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($CurDateTime - ($BalanceObjects[0].Date)).TotalHours) } Else { $Growth1 }
            $EarningsObject = [PSCustomObject]@{ 
                Pool                  = $Pool
                Wallet                = $Wallet
                Uri                   = $PoolAccountUri
                Date                  = $CurDateTime.ToShortDateString()
                StartTime             = ($BalanceObjects[0].Date).ToLongTimeString()
                Balance               = $BalanceObject.balance
                Unsold                = $BalanceObject.unsold
                Total_unpaid          = $BalanceObject.total_unpaid
                Total_paid            = $BalanceObject.total_paid
                Total_earned          = $BalanceObject.total_earned
                Currency              = $BalanceObject.currency
                GrowthSinceStart      = $BalanceObject.total_earned - $BalanceObjects[0].total_earned
                Growth1               = $Growth1
                Growth6               = $Growth6
                Growth24              = $Growth24
                AvgHourlyGrowth       = $AvgBTCHour
                BTCD                  = $AvgBTCHour * 24
                EstimatedEndDayGrowth = If ((($CurDateTime - ($BalanceObjects[0].Date)).TotalHours) -ge 1) { ($AvgBTCHour * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $CurDateTime).Hours) } Else { $Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $CurDateTime).Hours }
                EstimatedPayDate      = If ($PaymentThreshold) { If ($BalanceObject.balance -lt $PaymentThreshold) { If ($AvgBTCHour -gt 0) { $CurDateTime.AddHours(($PaymentThreshold - $BalanceObject.balance) / $AvgBTCHour) } Else { "Unknown" } } Else { "Next Payout !" } } Else { "Unknown" }
                TrustLevel            = $((($CurDateTime - ($BalanceObjects[0].Date)).TotalMinutes / 360), 1 | Measure-Object -Minimum).Minimum
                PaymentThreshold      = $PaymentThreshold
                TotalHours            = ($CurDateTime - ($BalanceObjects[0].Date)).TotalHours
                LastUpdated           = $CurDateTime
            }
            $EarningsObject
            If ($EarningsTrackerConfig.EnableLog) { $EarningsObject | Export-Csv -NoTypeInformation -Append ".\Logs\EarningTrackerLog.csv" }

            # Read existing earning data
            $DailyEarnings = @()
            If (Test-Path -Path ".\Logs\DailyEarnings.csv" -PathType Leaf) { $DailyEarnings = @(Import-Csv ".\Logs\DailyEarnings.csv" -ErrorAction SilentlyContinue) }

            If (@($DailyEarnings | Where-Object Pool -EQ $Pool | Where-Object { [DateTime]::parseexact($_.Date, (Get-Culture).DateTimeFormat.ShortDatePattern, $null).ToShortDateString() -match $CurDateTime.ToShortDateString() }).Count -gt 1) {
                # Must not be an array, remove todays data
                $DailyEarnings = $DailyEarnings | Where-Object { [DateTime]::parseexact($_.Date, (Get-Culture).DateTimeFormat.ShortDatePattern, $null).ToShortDateString() -lt $CurDateTime.ToShortDateString() }
                $DailyEarnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation -Force
            }

            If ($DailyEarning = ($DailyEarnings | Where-Object Pool -EQ $Pool | Where-Object { [DateTime]::parseexact($_.Date, (Get-Culture).DateTimeFormat.ShortDatePattern, $null).ToShortDateString() -match $CurDateTime.ToShortDateString() }) | Select-Object -First 1) {
                # pool may have reduced estimated balance, use new balance as start value to avoid negative values
                $DailyEarning.StartValue = ($DailyEarning.StartValue, $BalanceObject.total_earned | Measure-Object -Minimum).Minimum
                $DailyEarning.DailyEarnings = $BalanceObject.total_earned - $DailyEarning.StartValue
                $DailyEarning.EndTime = ($BalanceObject.Date).ToLongTimeString()
                $DailyEarning.EndValue = $BalanceObject.total_earned
                If ($BalanceObject.total_earned -lt ($BalanceObjects[$BalanceObjects.Count - 2].total_earned / 2)) { 
                    $DailyEarning.PrePaymentDayValue = $BalanceObjects[$BalanceObjects.Count - 2].total_earned
                    If ($DailyEarning.PrePaymentDayValue -gt 0) { 
                        #Payment occured
                        $DailyEarning.DailyEarnings += $DailyEarning.PrePaymentDayValue
                    }
                }
                $DailyEarning.Balance = $BalanceObject.balance
                $DailyEarning.BTCD = $BalanceObject.Growth24
                Remove-Variable DailyEarning
            }
            Else { 
                $DailyEarnings += [PSCustomObject]@{ 
                    Date               = $CurDateTime.ToShortDateString()
                    Pool               = $Pool
                    DailyEarnings      = 0
                    StartTime          = ($BalanceObject.Date).ToLongTimeString()
                    StartValue         = $BalanceObject.total_earned
                    EndTime            = ($BalanceObject.Date).ToLongTimeString()
                    EndValue           = $BalanceObject.total_earned
                    PrePaymentDayValue = 0
                    Balance            = $BalanceObject.Balance
                    BTCD               = $BalanceObject.Growth24
                }
            }
            $DailyEarnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation -Force
        }
    }

    #Write chart data file (used in Web GUI)
    $DailyEarnings | ForEach-Object { $_.Date = [DateTime]::parseexact($_.Date, (Get-Culture).DateTimeFormat.ShortDatePattern, $null) }
    $DailyEarnings = $DailyEarnings | Sort-Object Date | Group-Object -Property Date | Select-Object -Last 30 #Last 30 days

    $EarningsData = [PSCustomObject]@{}
    #Use dates for x-axis label
    $EarningsData | Add-Member labels @(($DailyEarnings.Group.Date | Sort-Object -Unique).ToShortDateString())

    #Dataset for cumulated earnings
    $EarningsData | Add-Member @{ CumulatedEarnings = [Double[]]@() }

    #One dataset per pool
    $PoolData = [PSCustomObject]@{}
    $DailyEarnings.Group.Pool | Sort-Object -Unique | ForEach-Object { 
        $PoolData | Add-Member @{ $_ = [Double[]]@() }
    }

    #Fill dataset
    ForEach ($DailyEarning in $DailyEarnings) { 
        $EarningsData.CumulatedEarnings += ([Double]($DailyEarning.Group | Measure-Object DailyEarnings -Sum).Sum)
        $PoolData | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
            $PoolData.$_ += [Double]($DailyEarning.Group | Where-Object Pool -EQ $_).DailyEarnings
        }
    }
    $EarningsData | Add-Member Pools $PoolData
    $Data = ConvertTo-Json ($EarningsData | Select-Object) | Out-File ".\Logs\EarningsChartData.json"

    # Some pools do reset "Total" after payment (zpool)
    # Results in showing bad negative earnings
    # Detecting if current is more than 50% less than previous and reset history if so
    If ($BalanceObject.total_earned -lt ($BalanceObjects[$BalanceObjects.Count - 2].total_earned / 2)) { $AllBalanceObjects = $AllBalanceObjects | Where-Object { $_.Pool -ne $Pool }; $AllBalanceObjects += $BalanceObject }
    Remove-Variable BalanceData
    If ($AllBalanceObjects.Count -gt 1) { $AllBalanceObjects = $AllBalanceObjects | Where-Object { $_.Date -ge $CurDateTime.AddDays(-7) } }

    # Save data only at defined interval. Limit disk access
    If ((Get-Date) -gt $WriteAt) { 
        $WriteAt = (Get-Date).AddMinutes($EarningsTrackerConfig.WriteEvery)
        If ($AllBalanceObjects.Count -ge 1) { $AllBalanceObjects | ConvertTo-Json | Out-File ".\Logs\EarningTrackerData.json" }
    }

    # Sleep until next update based on $Interval
    If ($BalanceObject.Date -and ($CurDateTime - $BalanceObject.Date).TotalMinutes -le 20) { 
        $Sleep = [Int](60 * ($Interval / 2))
    }
    Else { 
        $Sleep = [Int](60 * ($Interval))
    }

    #Sleep at least 30 seconds
    Start-Sleep -Seconds (30, $Sleep | Measure-Object -Maximum).Maximum
    Remove-Variable Sleep
}
