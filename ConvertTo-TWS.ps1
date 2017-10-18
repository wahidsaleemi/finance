
$inputFile = ".\vvsymbols.csv"
$outputFile = ".\twssymbols.csv"

#Get the VectorVest Watchlist
$symbols = Get-Content $inputFile

#Remove top row
$symbols = ($symbols[2..($symbols.Count -1)])

#Add "SYM" in first column in each row and "SMART/AMEX" as last column
$symbols | 
      Foreach-Object { 
           $_ -replace $_, "SYM,$_,SMART/AMEX"
  } | Set-Content( $outputFile ) -Force

#Invoke-Expression $outputFile

