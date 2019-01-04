# ConvertTo-TWS

This small script is to convert a list of symbols into an Interactive Brokers compatible watchlist.

## Overview

1. From VectorVest, export your watchlist and take only the Symbols (no other fields). Save it as "vvsymbols.csv".
2. Place this script in the same folder.
3. Run the script. In Windows 10, you can just right-click and click "Run with PowerShell," not sure about Win7/8.
4. It will create a file called "twssymbols.csv" that you can import into the Interactive Brokers watchlist.

It takes seconds to convert.

## Notes

If you've never used PowerShell on your system, you may get an error about unsigned scripts. Just open PowerShell as an Administrator and type:

    Set-ExecutionPolicy Unrestricted -Scope CurrentUser
    
For more info see:  https://docs.microsoft.com/en-au/powershell/module/microsoft.powershell.core/about/about_execution_policies

Because of cookie warning, we need to add a Current User Registry setting. Run the following (in an Administrator Command Prompt):

    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /t REG_DWORD /v 1A10 /f /d 0
