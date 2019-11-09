<#
    This an example with node description
#>

If ( $a -eq 10 ) {
    # Descritpion: VALUE OF A
    Foreach ( $File in $CollectionsOfFiles ) {
        # Descritpion: FILE IN COLLECTION
        "This has no sense"
    }
} Else {
    # Description: A NOT 10
    "No sense at all ..."
}