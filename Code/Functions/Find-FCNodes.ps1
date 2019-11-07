function Find-FCNodes {
    <#
    .SYNOPSIS
        Short description
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>

    [CmdletBinding()]
    param (
        $File
    )
    
    begin {
        
    }
    
    process {
        $FilePath = Get-Item $File
        $x=[nodeutility]::ParseFile($FilePath.FullName)
        return ,$x
    }
    
    end {
        
    }
}