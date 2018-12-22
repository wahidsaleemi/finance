Write-Output "PowerShell Timer trigger function executed at:$(get-date)";

$token = "000000000000000000000000"
$q = "123456"

$request = "https://gdcdyn.interactivebrokers.com/Universal/servlet/FlexStatementService.SendRequest?t=$token&q=$q&v=3"

$response = Invoke-WebRequest $request -UseBasicParsing

if ($response.StatusCode -ne '200')
                    {
    Write-Verbose "Status code not 200-OK" 4>&1
    $response.StatusCode
    $response.StatusDescription
}
else
                                                                    {
    [xml]$xml = $response.Content
    [string]$refCode = $xml.ChildNodes.ReferenceCode
    [string]$flexUrl = $xml.ChildNodes.Url

    $reqData = $flexUrl + "?q=$refCode&t=$token&v=3"
    $responseData = Invoke-WebRequest $reqData -UseBasicParsing
    if ($responseData.StatusCode -ne '200')
        {
            Write-Verbose "Status code not 200-OK" 4>&1
            $response.StatusCode
            $response.StatusDescription
        }
    else
        {
        $content = $responseData.Content
        }
}

Out-File -Encoding ASCII -FilePath $outputFile -inputObject $content