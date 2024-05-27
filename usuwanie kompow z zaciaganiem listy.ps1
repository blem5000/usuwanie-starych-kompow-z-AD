function Wait-AndDoSomething {
    param (
        [int]$CountdownSeconds = 1800,
        [string]$Message = "Countdown complete! Doing something now..."
    )

    #Write-Host "Starting countdown for $CountdownSeconds seconds..."
    for ($i = $CountdownSeconds; $i -gt 0; $i--) {
        Write-Progress -Activity "Odliczanie do następnego usunięcia" -Status " pozostało $i sekund" -SecondsRemaining $i
        Start-Sleep -Seconds 1
    }
    Write-Host $Message
}

function Start-Sleep2($seconds) {
    $doneDT = (Get-Date).AddSeconds($seconds)
    while($doneDT -gt (Get-Date)) {
        $secondsLeft = $doneDT.Subtract((Get-Date)).TotalSeconds
        $percent = ($seconds - $secondsLeft) / $seconds * 100
        Write-Progress -Activity "Sleeping" -Status "Sleeping..." -SecondsRemaining $secondsLeft -PercentComplete $percent
        [System.Threading.Thread]::Sleep(500)
    }
    Write-Progress -Activity "Sleeping" -Status "Sleeping..." -SecondsRemaining 0 -Completed
}


$licznik=1
$liczba_usunietych_w_petli=0
$liczba_usunietych_suma=0

while($true) {

        $lista1 = Get-ADComputer -Filter * -Properties Name, LastLogonDate -SearchBase "OU=LGEMA,OU=POLAND,OU=EIC,OU=Computer,DC=LGE,DC=NET" -Server MAMFAPDS01 | Select-Object Name | Format-Table -HideTableHeaders | Out-String
        $lista = $lista1 -split "`r`n"
        $lista = $lista | Where-Object { $_ -ne "" }
        $lista = $lista.replace(' ','')
        $Days = 90
        $licznikDlaForEach = 0

        foreach ($ComputerName in $lista) {
    
            $LastLogon = Get-ADComputer -Identity $ComputerName -Properties LastLogonDate -Server MAMFAPDS01 | Select-Object -ExpandProperty LastLogonDate
            $DaysSinceLastLogon = (Get-Date) - $LastLogon

            if ($DaysSinceLastLogon.Days -gt $Days) {
                Write-Host "Usuwam $ComputerName ktory nie logowal sie od $($DaysSinceLastLogon.Days) dni." -ForegroundColor Cyan
                Remove-ADComputer -Identity $ComputerName -Server MAMFAPDS01 -Confirm:$false
                Wait-AndDoSomething -CountdownSeconds 2880 -Message "Usuwam nastepny komputer!"
                $liczba_usunietych++
            }
            else
            {
            Write-Host "Komputer $ComputerName logowal sie wczesniej niz $Days dni temu, nie usuwam!" -ForegroundColor Yellow
            }
            $Pozostalo = $lista.Count - $licznikDlaForEach++
            Write-Host "Pozostało do sprawdzenia $Pozostalo"
        }
    
    ++$licznik
    $liczba_usunietych_w_petli++
    $liczba_usunietych_suma++
    Write-Host "W tej petli usunalem $liczba_usunietych_w_petli komputerow"
    Write-Host "Od uruchomienia skryptu usunalem $liczba_usunietych_suma komputerow"
    Write-Host "Petla $licznik"
    $liczba_usunietych_w_petli=0
    Start-Sleep2 21600
    Clear-Host
    }


