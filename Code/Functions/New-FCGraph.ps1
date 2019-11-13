function New-FCGraph {
    <#
    .SYNOPSIS
        Draw a script flowchart
    .DESCRIPTION
        Draw a script flowchart
    .EXAMPLE
        PS C:\> New-FCGraph -Node $a -Name test
        Draw a script flowchart. $a contains all the nodes present in a ps1 script file.
    .EXAMPLE
        PS C:\> Find-FCNode -File .\basic_example_1.ps1 -FindDescription | New-FCGraph -DescriptionAsLabe
        Draw a script flowchart. Will user node(s) descirption as Label(s).
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory=$False,ValueFromPipeline=$True)]
        [Node[]]
        $Node,
        # Name of the graph
        [Parameter(Mandatory=$False)]
        [String]
        $Name="NewGraph",
        # Parameter help description
        [Parameter(Mandatory=$False)]
        [Switch]
        $DescriptionAsLabel,
        # Passthru
        [Parameter(Mandatory=$False)]
        [Switch]
        $PassThru
    )
    
    begin {

    }
    
    process {

        $GraphName = [System.Io.Path]::GetFileName(($node | Where-Object file -ne $null | Select-Object -first 1).File)

        If ( $DescriptionAsLabel ) {
            $string = $node.graph($True)
        } Else {
            $string=$node.graph($False)
        }
        Write-Host "GraphName: $GraphName"
        $s = $string | out-string
        $plop = [scriptblock]::Create($s).invoke()
        $graph = graph "$Name" {
                $plop
        } -Attributes @{label="Script: $($GraphName.ToUpper())"}

        If ( $PassThru ) {
            $graph
        } Else {
            $graph | show-psgraph
        }
    }
    
    end {

    }
}
