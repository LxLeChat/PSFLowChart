$x=[nodeutility]::ParseFile("$PWD\plop.ps1")

$string=$x.graph()
$s = $string | out-string
$plop = [scriptblock]::Create($s).invoke()
$graph = graph "lol" {$plop}
$graph | show-psgraph

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