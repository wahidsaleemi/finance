
##NOTE, because of cookie warning, we need add modify registry
## Use: reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /t REG_DWORD /v 1A10 /f /d 0
$stockSymbol = "AXP"
$result = Invoke-WebRequest "https://stocksearning.com/q.aspx?Sys=$stockSymbol" -Method Get
$text = $result.AllElements |
    Where-Object Class -eq "upcoming-predicationbox detailcontainer" |
    Select -First 1 -ExpandProperty innerText
$split = $text.Split("`n") #Split the block of text into individual lines
$earningsDescription = $split | select-string "Earnings Date" #Find the earnings date ("Earnings Date : Wed 17 Jan (In 91 Days)")


if ($earningsDescription -like "*today*")
    {
        Write-Host $earningsDescription
    }
else {
    $numOfDays = $earningsDays.Replace("In ","").Replace(" Days","")
    [int]$numOfDays
    }

$earningsDays = $earningsDescription.ToString().Split("(")[1].Split(")")[0]


