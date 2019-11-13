function Set-FCNodeDescription {
    <#
    .SYNOPSIS
        Set Description on nodes
    .DESCRIPTION
        Set Description on nodes
    .EXAMPLE
        PS C:\> Set-FCNodeDescription -Node $a -Recurse
        Set description for If ( $a -eq 10 ): Describe Me!
        Set description for Foreach ( $File in $CollectionsOfFiles ): stuff describing
        Set description for ProcessBlock: something
        Set description for Else From If ( $a -eq 10 ): !
        Set description for ProcessBlock:


        Type        : If
        Statement   : If ( $a -eq 10 )
        Description : Describe Me!
        Children    : {ForeachNode, ElseNode}
        Parent      :
        Depth       : 1
        File        : C:\Temp\FLowChart-test_new_base_parsing\Code\Tests\basic_example_1.ps1

        The function will prompt you for description! 
    .INPUTS
        [node[]]
    .OUTPUTS
        [node[]]
    .NOTES
        General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [Node[]]
        $Node,
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