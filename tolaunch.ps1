$x=[nodeutility]::ParseFile("$PWD\plop.ps1")


$string=$x[0].graph()
$string=$string+";"+$x[1].graph()
$string=$string+";"+$x[2].graph()
$string=$string+";"+$x[0].Children[0].graph()
$string=$string+";"+$x[0].Children[1].graph()

$plop = [scriptblock]::Create($string).invoke()
$graph = graph "lol" {$plop}
$graph | show-psgraph