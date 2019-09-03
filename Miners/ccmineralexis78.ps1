if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1;RegisterLoaded(".\Includes\include.ps1")}

$Path = ".\Bin\NVIDIA-Alexis78151\ccminer.exe"
$Uri = "https://github.com/Minerx117/ccmineralexis78/releases/download/v1.5.1/ccminerAlexis78cuda75x64.7z"

$Commands = [PSCustomObject]@{
     "skein2" = " -i 30 -d $($Config.SelGPUCC)" #Skein2
     "x15" = " -d $($Config.SelGPUCC)" #X15
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-N 1 -R 1 -b $($Variables.NVIDIAMinerAPITCPPort) -a $_ -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)" #--cuda-schedule 2 --cuda-schedule 3
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day}
        API = "ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap = $false
        URI = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
