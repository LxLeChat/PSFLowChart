If ( $a -eq 1 ) {
    If ( $b -eq 1) {
        "plop"
    }
    "process"
    "process"
    "process"
} ElseIf ( $a -eq 2 ) {
    "process"
    If ( $b -eq 1) {
        "plop"
    }
    "process"
    "process"
} Else {
    "process"
    "process"
    If ( $b -eq 1) {
        "plop"
    }
    "process"
}

if ( $a -eq 2 ) {
    Foreach ($a in $b) {
        "aaaa"
    }
}