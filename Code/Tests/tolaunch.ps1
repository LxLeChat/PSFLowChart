$x=[nodeutility]::ParseFile("$PWD\Complex_example_1.ps1")
$x.FindDescription($True)
$string=$x.graph($false)
$s = $string | out-string
$plop = [scriptblock]::Create($s).invoke()
$graph = graph "lol" {$plop}
$graph | show-psgraph



$i=0
$tmp = $false
while ( $i -lt $e.count ) {
    If ( $e[$i].GetType() -in [nodeutility]::GetASTitems() ) {
        Write-Verbose "AAAAAAA"
        $tmp = $true
    } else {
        Write-Verbose "BBBBBB"
        if ( $tmp -and ($i -gt 0) )  {
            Write-Verbose "CCCCCCCCC"
            $tmp = $false
        }

        If ( ( ($i -eq 0) -or ($i -eq $e.count) ) ) {
            Write-Verbose "DDDDDDD"
        }
    }
    $i++
}

# $string=$x[0].graph()
# $string=$string+";"+$x[1].graph()
# $string=$string+";"+$x[2].graph()
# $string=$string+";"+$x[0].Children[0].graph()
# $string=$string+";"+$x[0].Children[1].graph()
# $string=$string+";"+$x[0].Children[0].Children[0].graph()

# $plop = [scriptblock]::Create($s).invoke()
# $graph = graph "lol" {$plop}
# $graph | show-psgraph


# $string=$x[0].graph()
# $string=$string+";"+$x[0].Children[0].graph()
# $string=$string+";"+$x[0].Children[1].graph()
# $string=$string+";"+$x[0].Children[2].graph()
# $string=$string+";"+$x[0].Children[0].Children[0].graph()
# $x[0].Children[0].Children[0].Children[0].graph()