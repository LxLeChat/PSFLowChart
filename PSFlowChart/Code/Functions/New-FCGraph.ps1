function New-FCGraph {
    [CmdletBinding()]
    param (
        # Array of nodes
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [Node[]]
        $Node,
        ## Define GraphMode
        [Parameter(Mandatory=$False)]
        [String]
        [ValidateSet('Debug','Standard','Description')]
        $GraphMode,
        # Passthru
        [Parameter(Mandatory=$False)]
        [Switch]
        $PassThru,
        # HtmlLink for debug
        [Parameter(Mandatory=$False)]
        [Switch]
        $HtmlLink
    )
    
    begin {

    }
    
    process {

        Switch ($GraphMode) {
            "Debug" { $mode = [GraphMode]::Debug }
            "Standard" { $mode = [GraphMode]::Standard }
            "Description" { $mode = [GraphMode]::Description }
            Default { $mode = [GraphMode]::Standard }
        }

        $x=[scriptblock]::Create($node.graph($mode)).invoke()
        $graph = graph 'plop' {
            $x
        } | Out-String

        If ( $PassThru ) {
            $graph
        } Else {
            If ( $HtmlLink ) {
                $("https://dreampuf.github.io/GraphvizOnline/#" + ([System.Web.HttpUtility]::UrlEncode($graph)).replace("+","%20"))
            } else {
                $graph | show-psgraph
            }
        }
    }
    
    end {

    }
}
