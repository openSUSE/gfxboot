helpInformatie over het Help systeem gebruikDe bootloader online help is context gevoelig. Het geeft informatie over het geselecteerde menu item of, indien u de boot opties aan het wijzigen bent, probeert informatie te vinden over de optie waar de cursor zich bij bevindt.

Navigatie toetsen

  Pijl omhoog: vorige link benadrukken
  Pijl omlaag: volgende link benadrukken
  Pijl naar links, Backspace: keer terug naar vorige onderwerp
  Pijl naar rechts, Enter, Spatiebalk: volg link
  Page Up: scroll één pagina omhoog
  Page Down: scroll één pagina omlaag
  Home: ga naar het begin van de pagina
  End: ga naar het einde van de pagina
  Esc: help verlaten

Keer terug naar optBootoptiesstartupOpstart mode selectieF3 biedt u de mogelijkheid om de opstartscherm mode te wijzigen. Mocht u dat prefereren, dan kunt u de o_splashsplash kernel optie ook rechtstreeks gebruiken.

native zet het opstartscherm uit (identiek aan splash=0)

silent onderdrukt alle kernel en boot berichten en laat in plaats daarvan een voortgangsbalk zien

verbose laat een mooi plaatje met kernel en boot berichten zien

Terug naar optBootoptieskeytableTaal en toetsenbord layout selectieDruk op F2 om de, door de bootloader gebruikte, taal en het toetsenbord layout te wijzigen.

Terug naar optBootoptiesprofileKies een profielDruk op F4 om een profiel te selecteren. Uw systeem zal met de in dit profiel opgeslagen configuratie opgestart worden.

Terug naar optBootoptiesoptBoot optieso_splashsplash -- beïnvloedt het gedrag van het opstartscherm
  o_apmapm -- energiebeheer aan/uit
  o_acpiacpi -- geavanceerde configuratie en energie interface
  o_ideide -- IDE subsysteem besturingo_splashKernel opties: splashHet opstartscherm is de afbeelding wat tijdens het opstarten van het systeem zal worden weergegeven.

splash=0
Het opstartscherm is uitgezet. Soms zinvol bij erg oude monitoren of bij een opgetreden fout.

splash=verbose
Activeert opstartscherm, kernel en boot berichten blijven zichtbaar.

splash=silent
Activeert opstartscherm, geen berichten. In plaats daarvan wordt een voortgangsbalk zichtbaar.

Terug naar optBootoptieso_apmKernel opties: apmAPM is één van de twee energiebeheer strategieën die bij de computers van tegenwoordig gebruikt worden. Echter hoofdzakelijk bij laptops ten behoeve van functies zoals de slaapstand mode. Ook kan het verantwoordelijk zijn voor het uitschakelen van de computer bij een wegvallende voedingsspanning. APM heeft een correct werkende BIOS nodig. Bij een defecte BIOS zal APM slechts gedeeltelijk werken of zelfs de computer zo beïnvloeden dat deze niet meer werkt. Met de volgende parameter is het eventueel uit te schakelen:

  apm=off -- APM geheel uitschakelen

Moderne computers hebben meer voordeel bij het nieuwere o_acpiACPI.

Terug naar optBootoptieso_acpiKernel opties: acpiACPI (Advanced Configuration and Power Interface) is een standaard dat de energie en configuratie beheer interfaces definieert tussen het operating systeem en de BIOS. Standaard wordt acpi geactiveerd als er een BIOS is gedetecteerd dat na het jaar 2000 gemaakt is. Er zijn diverse algemeen te gebruiken parameters die het gedrag van ACPI beïnvloeden:

  pci=noacpi -- ACPI niet gebruiken om PCI interrupts af te handelen
  acpi=oldboot -- alleen die ACPI-onderdelen gebruiken die voor het booten relevant zijn
  acpi=off -- ACPI geheel uitschakelen
  acpi=force -- ACPI inschakelen, zelfs als uw BIOS voor 2000 gedateerd is

Vooral bij nieuwe computers zal dit het oude o_apmapm systeem prima vervangen.

Terug naar optBootoptieso_ideKernel opties: ideGewoonlijk wordt IDE, in tegenstelling tot SCSI, bij de meeste desktop werkstations gebruikt. Gebruik de volgende kernel parameter om enkele hardware problemen, die bij IDE systemen zouden kunnen optreden, te voorkomen:

  ide=nodma -- dma voor IDE drives uitschakelen


Terug naar optBootopties. 