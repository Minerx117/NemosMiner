using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$PoolConfig
)

If ($PoolConfig.Wallet) { 
    Try { 
        $Request = Get-Content ((Split-Path -Parent (Get-Item $script:MyInvocation.MyCommand.Path).Directory) + "\Brains\zergpoolcoins\zergpoolcoins.json") | ConvertFrom-Json
        $CoinsRequest = Invoke-RestMethod -Uri "http://api.zergpool.com:8080/api/currencies" -Headers @{"Cache-Control" = "no-cache" }
    }
    Catch { Return }

    If ((-not $Request) -or (-not $CoinsRequest)) { Return }

    $Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
    $HostSuffix = "103.249.70.7"

    $PriceField = "Plus_Price"
    #$PriceField = "actual_last24h"
    #$PriceField = "estimate_current"
    $DivisorMultiplier = 1000000

    $PoolRegions = "US"

    $AllMiningCoins = @()
    ($CoinsRequest | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name) | ForEach-Object { $CoinsRequest.$_ | Add-Member -Force @{Symbol = If ($CoinsRequest.$_.Symbol) { $CoinsRequest.$_.Symbol } Else { $_ } } ; $AllMiningCoins += $CoinsRequest.$_ }

    #Uses BrainPlus calculated price
    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Request.$_.hashrate -gt 0 } | Where-Object { [Double]($Request.$_.actual_last24h) -gt 0 } | ForEach-Object { 
        $PoolHost = "$($HostSuffix)"
        $PoolPort = $Request.$_.port
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        # Find best coin for algo
        If ($TopCoin = $AllMiningCoins | Where-Object { ($_.noautotrade -eq 0) -and ((Get-Algorithm $_.algo) -eq $Algorithm_Norm) } | Sort-Object -Property @{Expression = { $_.estimate / ($DivisorMultiplier * [Double]$_.mbtc_mh_factor) } } -Descending | Select-Object -first 1) { 

            $Fee = [Decimal]($Request.$_.Fees / 100)
            $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

            $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)-$($TopCoin.Symbol)_Profit" -Value ([Double]($Request.$_.$PriceField / $Divisor)) -FaultDetection $true

            If ($TopCoin.Name -eq "BitcoinInterest") { $Algorithm_Norm = "BitcoinInterest" } # Temp fix

            Try { $EstimateFactor = [Decimal](($Request.$_.actual_last24h / 1000) / $Request.$_.estimate_last24h) }
            Catch { $EstimateFactor = [Decimal]1 }
        
            $PoolRegions | ForEach-Object { 
                $Region = $_
                $Region_Norm = Get-Region $Region

                [PSCustomObject]@{ 
                    Algorithm          = [String]$Algorithm_Norm
                    CoinName           = [String]$TopCoin.Name
                    Currency           = [String]$TopCoin.Symbol
                    Price              = [Double]$Stat.Live
                    StablePrice        = [Double]$Stat.Week
                    MarginOfError      = [Double]$Stat.Week_Fluctuation
                    PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
                    Protocol           = "stratum+tcp"
                    Host               = [String]$PoolHost
                    Port               = [UInt16]$PoolPort
                    User               = $PoolConfig.Wallet
                    Pass               = "$($PoolConfig.WorkerName),c=$($PoolConfig.PayoutCurrency),mc=$($TopCoin.Symbol)"
                    Region             = [String]$Region_Norm
                    SSL                = [Bool]$false
                    Fee                = $Fee
                    EstimateFactor     = $EstimateFactor
                }
            }
        }
    }
}