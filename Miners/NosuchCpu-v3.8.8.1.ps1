using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\cpuminer-aes-sse2.exe"
$Uri = "https://github.com/patrykwnosuch/cpuminer-nosuch/releases/download/3.8.8.1-nosuch-m4/cpu-nosuch-m4-win64.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "BinariumV1"; Command = " --algo binarium-v1" }
    [PSCustomObject]@{ Algorithm = "m7m";        Command = " --algo m7m" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    If ($Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 

        If ($Miner_Devices.CpuFeatures -match "sha")      { $Path = ".\Bin\$($Name)\cpuminer-avx2-sha.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "avx2") { $Path = ".\Bin\$($Name)\cpuminer-avx2.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "aes")  { $Path = ".\Bin\$($Name)\cpuminer-aes-sse2.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "sse2") { $Path = ".\Bin\$($Name)\cpuminer-sse2.exe" }
        Else { Return }

        $Miner_Devices | Select-Object Model -Unique | ForEach-Object { 
            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            $Commands | ForEach-Object {

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Type       = "CPU"
                    Path       = $Path
                    Arguments  = ("$($_.Command) --url $($Pools.($_.Algorithm).Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --cpu-affinity AAAA --quiet --threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
                    Algorithm  = $_.Algorithm
                    API        = "Ccminer"
                    Port       = $MinerAPIPort
                    URI        = $Uri
                    WarmupTime = 60 #seconds
                }
            }
        }
    }
}