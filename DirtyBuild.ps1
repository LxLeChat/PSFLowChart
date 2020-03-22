Remove-Module psflowchart -Force -ErrorAction SilentlyContinue
Remove-Item .\PSFlowchart\psflowchart.psm1 -ErrorAction SilentlyContinue
Get-Content .\PSFlowchart\Code\Classes\classes.psm1 >> .\PSFlowchart\PSFlowchart.psm1

Foreach ( $File in (Gci .\PSflowchart\Code\Functions -Filter *.ps1) ) {
    Get-Content $File.FullName -raw >> .\PSFlowchart\PSFlowchart.psm1
}

Import-Module .\PSFlowChart
"cool3a"