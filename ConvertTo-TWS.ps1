﻿[CmdletBinding()]
#Must use Desktop edition, HTML Parsing require Internet Explorer
#Requires -PSEdition Desktop
Param(
$inputFile = ".\vvsymbols.csv",
$outputFile = ".\twssymbols.csv",
[switch]$CheckEarnings
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


#Get the VectorVest Watchlist
Write-Verbose "Reading input file: $inputfile..."
$symbols = Get-Content $inputFile

#Remove top row
Write-Verbose "Removing heading from CSV..."
$symbols = ($symbols[1..($symbols.Count -1)])

#Clean up earnings
if ($CheckEarnings)
    {
        Write-Host "-CheckEarnings switch specified. Running function"
        $cleansymbols = Remove-ClosebyEarnings -symbols $symbols
    }
else
    {
        Write-Host "-CheckEarnings not specified. Skipping check of earnings dates."
        $cleansymbols = $symbols
    }


#Add "SYM" in first column in each row and "SMART/AMEX" as last column
Write-Host "Converting to Interactive Brokers format..."  -ForegroundColor Yellow
$cleansymbols | 
      Foreach-Object { 
           $_ -replace $_, "SYM,$_,SMART/AMEX"
  } | Set-Content( $outputFile ) -Force

Write-Host "Done." -ForegroundColor Yellow



