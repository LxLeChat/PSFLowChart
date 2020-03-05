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
        [Parameter(Mandatory=$False,
        ValueFromPipelineByPropertyName=$True,Position=0,ParameterSetName="File")]
        [Alias("FullName")]
        [String[]]
        $File,
        [Parameter(Mandatory=$False,ParameterSetName="ScriptBlock"]
        [Scriptblock]$ScritpBlock
    )
    
    begin {
        ## Check if PSGRAPH is loaded or available ?
    }
    
    process {
        
        Switch ($PsCmdlet.ParameterSetName) {
            "File" {
                $FileInfo = Get-Item $File
                $x=[node]::ParseFile($FileInfo.FullName)
            }
            
            "ScriptBlock" {
                $x=[node]::ParseScriptBlock($ScriptBlock)
            }
        }
        
        return ,$x

    }
    
    end {
        
    }
}
