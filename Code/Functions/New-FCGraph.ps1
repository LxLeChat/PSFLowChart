function New-FCGraph {
    [CmdletBinding()]
    param (
        [node[]]$node,
        [switch]$DescriptionAsLabel
    )
    
    begin {
        
    }
    
    process {
        If ( $DescriptionAsLabel ) {
            $node.FindDescription($True)
        }

        $string=$node.graph($DescriptionAsLabel)
        $s = $string | out-string
        $plop = [scriptblock]::Create($s).invoke()
        $graph = graph "lol" {$plop}
        $graph | show-psgraph
    }
    
    end {

    }
}
