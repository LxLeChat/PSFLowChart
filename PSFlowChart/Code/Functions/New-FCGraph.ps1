function New-FCGraph {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory=$False,ValueFromPipeline=$True)]
        [Node[]]
        $Node,
        # DebugMode
        [Parameter(Mandatory=$False,ParameterSetName="DebugMode")]
        [Switch]
        $DebugMode,
        # StandardMode
        [Parameter(Mandatory=$False,ParameterSetName="StandardMode")]
        [Switch]
        $StandardMode,
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

        If ( $DebugMode ) {
            $mode = [GraphMode]::Debug
        }

        If ( $StandardMode ) {
            $mode = [GraphMode]::Standard
        }

        $x=[scriptblock]::Create($node.graph($mode)).invoke()
        $graph = graph "pester" {
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
