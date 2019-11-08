function Set-FCNodeDescription {
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
        [node[]]$Node,
        [Switch]$Recurse
    )
    
    begin {
        
    }
    
    process {
        $Node.SetDescription($Recurse)
        return ,$Node
    }
    
    end {
        
    }
}