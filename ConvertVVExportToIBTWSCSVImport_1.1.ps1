<# *****************************************************
TITLE           :  Convert VV Export To IB TWS CSV Import 1.1
DESCRIPTION     :  This script will convert VectorVest watchlist symbols 
                   only exported as a CSV into a CSV format that can be 
                   imported into Interactive Brokers TraderWorkstation
                   (TWS), whilst filtering out stock symbols with earnings
                   in 1-14 days away (refer to the Options Paycheck course
                   material) if you so choose from one of two earnings
                   web site sources.
AUTHOR(S)       :  Wahid Saleemi and Charles "Chucky!" Warda
VERSION x.x     :  1.1
DATE YYYY MM DD :  2019 09 06
TEMPLATE        :  0.1
CREDITS 
-Individuals    :  Authors only.
-Web Links      :  https://www.earningswhispers.com/
                   https://stocksearning.com/
********************************************************#>


[CmdletBinding()]
#Must use Desktop edition, HTML Parsing require Internet Explorer
#Requires -PSEdition Desktop
Param(
$inputFile = ".\vvsymbols.csv",
$outputFile = ".\twssymbols.csv",
[switch]$CheckEarnings,          #use earningswhispers.com - most accurate
[switch]$UseLegacyEarningsSource #use stocksearning.com - less accurate
)

$symbols = $null
$cleansymbols = @()

function Remove-ClosebyEarnings($symbols) 
    {
        
        $symbols | ForEach-Object {
                Write-Verbose "Retrieving symbol information from stocksearning.com..."
                $result = Invoke-WebRequest "https://stocksearning.com/q.aspx?Sys=$_" -Method Get -TimeoutSec 5
                Write-Verbose "Done accessing stocksearning.com!"
                Write-Verbose "Parsing results..."
                $text = $result.AllElements |
                    Where-Object Class -eq "upcoming-predicationbox detailcontainer detail-topspace" |
                    Select-Object -First 1 -ExpandProperty innerText
                Write-Verbose "Cleaning earnings data..."
                $earningsDescription = $text.Split("`n") | select-string "Earnings Date" #Find the earnings date ("Earnings Date : Wed 17 Jan (In 91 Days)")
                
                if ($earningsDescription -like "*To*")
                    {
                        Write-Host "$_ has earnings today or tomorrow. Removing from list." -ForegroundColor Yellow
                    }
                else {
                        Write-Verbose "Getting number of days until earnings..."
                        $earningsDays = $earningsDescription[0].ToString().Split("(")[1].Split(")")[0]
                        [int]$numOfDays = $earningsDays.Replace("In ","").Replace(" Days","")
                        if ($numOfDays -ge 14)
                            {
                                Write-Host "$_ has earnings in $numOfDays days" -ForegroundColor Green
                                $cleansymbols += $_
                            }
                        else {
                                Write-Host "$_ has earnings less than 14 days, in $numOfDays. Removing from list." -ForegroundColor Yellow
                        }
                        
                    }
                }
        return $cleansymbols
    }

function Remove-NearEarnings($symbols) 
    {
        
        $symbols | ForEach-Object {
                Write-Verbose "Retrieving symbol information from earningswhispers.com..."
                $result = Invoke-RestMethod "https://beta.earningswhispers.com/jsdata/ical.aspx?symbol=$_" -Method Get | ConvertFrom-Csv -Delimiter ":"
                Write-Verbose "Done accessing earningswhispers.com!"
                $text = $result | Where-Object {$_.BEGIN -eq "DTSTART"} | Select-Object -ExpandProperty VCALENDAR
                Write-Verbose "Parsing results..."
                #Custom format is get-date -Format yyyyMMddTHHmmssZ
                $date = [DateTime]::ParseExact($text, 'yyyyMMddTHHmmssZ',[CultureInfo]::InvariantCulture)

                Write-Verbose "Cleaning earnings data..."
                $earningsDescription = $text.Split("`n") | select-string "Earnings Date" #Find the earnings date ("Earnings Date : Wed 17 Jan (In 91 Days)")
                
                Write-Verbose "Getting number of days until earnings..."
                [int]$numOfDays = $date - (Get-Date) | select -ExpandProperty Days
                if ($numOfDays -gt 14) #this loop will save stock symbols with greater than 14 days to earnings
                    {
                        Write-Host "$_ has earnings in $numOfDays days" -ForegroundColor Green
                        $cleansymbols += $_
                    }
                elseif ($numOfDays -lt 1) #this loop will save stock symbols with earnings that happened today (0) or just passed (negative number)
                    {
                        Write-Host "$_ had earnings $numOfDays days ago, IV could be falling from elevated levels!" -ForegroundColor White -BackgroundColor Black
                        $cleansymbols += $_ 
                    }
                else {  #this loop will remove stock symbols with 14 (to 1) days to earnings
                        Write-Host "$_ has earnings less than 14 days, in $numOfDays. Removing from list." -ForegroundColor Yellow
                }
        }
    return $cleansymbols
    }

#Get the VectorVest Watchlist Export
Write-Verbose "Reading input file: $inputfile..."
$symbols = Get-Content $inputFile

#Remove top row
Write-Verbose "Removing heading from CSV..."
$symbols = ($symbols[1..($symbols.Count -1)])

#Clean up earnings
##NOTE, because of cookie warning, we need add modify registry
## Use: reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /t REG_DWORD /v 1A10 /f /d 0
if ($CheckEarnings -and $UseLegacyEarningsSource)
    {
        Write-Host "-CheckEarnings and -UseLegacyEarningsSource switch specified. Running legacy function"
        $cleansymbols = Remove-ClosebyEarnings -symbols $symbols
    }
elseif ($CheckEarnings)
    {
        Write-Host "-CheckEarnings switch specified. Running function"
        $cleansymbols = Remove-NearEarnings -symbols $symbols
    }
else
    {
        Write-Host "-CheckEarnings not specified. Skipping check of earnings dates."
        $cleansymbols = $symbols
    }


#Add "SYM" in first column in each row and "SMART/AMEX" as last column
Write-Host "Converting to Interactive Brokers TWS CSV format for importing." -ForegroundColor Yellow
$cleansymbols | 
      Foreach-Object { 
           $_ -replace $_, "SYM,$_,SMART/AMEX"
  } | Set-Content( $outputFile ) -Force

Write-Host "Done." -ForegroundColor Magenta
