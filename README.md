# FLowChart
- ne fonctionne pour l'instant que sur des script "purs" ... pas des modules ou des scriptblock (fonctions ou autres)
- les formes sont temporaires, ainsi que le contenu des "noeuds". A terme il y aura des formes dédiés et vous pourrez setter une description, ou bien à l'aide d un block comment spécial dans votre code, automatiquement setter le contenu noeud.
-testez testez testez :)

# Notes
- Utilisation:
```powershell
Import-Module .\psflowchart.psm1
$a=Find-FCNodes .\plop.ps1
New-FCGraph $a
```
Manfez c'est pret.
