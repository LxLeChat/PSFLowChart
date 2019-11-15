function Find-FCNode {
    <#
    .SYNOPSIS
        Find "nodes" present in script
    .DESCRIPTION
        Find "nodes" present in script
    .EXAMPLE
        PS C:\> Find-FCNode -File .\basic_example_1.ps1

        Type        : If
        Statement   : If ( $a -eq 10 )
        Description :
        Children    : {ForeachNode, ElseNode}
        Parent      :
        Depth       : 1
        File        : C:\basic_example_1.ps1

        Return all the nodes present in the basic_example_1.ps1
    .INPUTS
        ps1 file path
    .OUTPUTS
        [node[]]
    .NOTES
        Pipeline is accepted, so Gci c:\temp -filter "*.ps1" | Find-FCNode should Work
    #>

    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory=$True,
        ValueFromPipelineByPropertyName=$True,Position=1)]
        [Alias("FullName")]
        [String[]]
        $File,
        # Whether you want ton find associated node description
        [Parameter(Mandatory=$False,ParameterSetName='Description')]
        [Switch]
        $FindDescription,
        # The KeyWord representing the begining of your comment, default: Description
        [Parameter(Mandatory=$False,ParameterSetName='Description')]
        [String]
        $KeyWord = $null
    )
    
    begin {
        ## Check if PSGRAPH is loaded or available ?
    }
    
    process {

        $FileInfo = Get-Item $File
        $x=[nodeutility]::ParseFile($FileInfo.FullName)

        If ( $FindDescription ) {
            If ( $KeyWord ) {
                $X.FindDescription($True,$KeyWord)
            } Else {
                $X.FindDescription($True)
            }
        }
        return ,$x

    }
    
    end {
        
    }
}
