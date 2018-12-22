
param (
    $file = "C:\temp\trades.csv",
    $token = "123456789", #Goto Reports --> Settings --> Flexweb. In new UI, Menu -> Settings -> Account Settings
    $q = "123456" #In new UI, go to Menu --> Reports --> Flex Queries. 
)
#Comment for "q" - query:
# Create trade confirmation query. Comma separated, don't include headers, section code or canceled trades. 
# Create only one section "Trade Confirmations." Select the following:
# Date/Time, Symbol, Quantity, Price, amount, commission, OrderType (optional).

function New-IBReport {
    $request = "https://gdcdyn.interactivebrokers.com/Universal/servlet/FlexStatementService.SendRequest?t=$token&q=$q&v=3"

    $response = Invoke-WebRequest $request

    if ($response.StatusCode -ne '200')
                        {
        Write-Host "Status code not 200-OK"
        $response.StatusCode
        $response.StatusDescription
    }
    else
                                                                        {
       [xml]$xml = $response.Content
       [string]$refCode = $xml.ChildNodes.ReferenceCode
       [string]$flexUrl = $xml.ChildNodes.Url

       $reqData = $flexUrl + "?q=$refCode&t=$token&v=3"
       $responseData = Invoke-WebRequest $reqData
       if ($responseData.StatusCode -ne '200')
           {
                Write-Host "Status code not 200-OK"
                $response.StatusCode
                $response.StatusDescription
            }
        else
            {
            $content = $responseData.Content
            }
    }

    $csv = ConvertFrom-Csv -InputObject $content
 
    $csv | Export-Csv -Path $file -NoTypeInformation -Force
}
New-IBReport

Invoke-Item $file

