Remove-Item .\psflowchart.psm1 -ErrorAction SilentlyContinue
Get-Content .\Code\Classes\classes.psm1 >> .\psflowchart.psm1

Foreach ( $File in (Gci .\Code\Functions -Filter *.ps1) ) {
    Get-Content $File.FullName -raw >> .\psflowchart.psm1
}