function New-FCGraph {
    [CmdletBinding()]
    param (
        [node[]]$node
    )
    
    begin {
        
    }
    
    process {
        $string=$node.graph()
        $s = $string | out-string
        $plop = [scriptblock]::Create($s).invoke()
        $graph = graph "lol" {$plop}
        $graph
    }
    
    end {

    }
}
