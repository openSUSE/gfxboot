helpPoužívání nápovědyNápověda zavaděče je citlivá na obsah. Poskytuje informace o zvolené nabídce nebo pokud editujete parametry jádra, snaží se poskytnout informace o dané volbě.

Navigační klávesy

  Up Arrow: návrat na předešlý odkaz
  Down Arrow: přechod na následující odkaz
  Left Arrow, Backspace: návrat k předešlému tématu
  Right Arrow, Enter, Space: přejít na označený odkaz
  Page Up: o stránku nahoru
  Page Down: o stránku dolů
  Home: přechod na začátek stránky
  End: přechod na konec stránky
  Esc: ukončení nápovědy

Návrat do optstartovacínabídkystartupVýběr režimu splasheSplash režim můžete měnit pomocí klávesy F3. Použít můžete také parametr jádra o_splashsplash.

native vypne splash screen (stejně jako splash=0)

silent zakryje všechna hlášení jádra a zobrazí místo toho animaci znázorňující pokrok při stratu nebo ukončení systému

verbose Zobrazí hlášení jádra na grafickém pozadí

Návrat do optstartovacínabídkykeytableVýběr jazyka a klávesové mapyStisknutím klávesy F2 získáte seznam klávesových map a dostupných jazyků.

Tato volba je zatím experimentální a nemusí vždy fungovat. (Proto není F2 v zobrazené nabídce.)

Návrat do optstartovacínabídkyprofileVolba profiluStiknutím F4 můžete zvolit profil. Systém se spustí s nastaveními uloženými v tomto profilu.

Návrat do optstartovacínabídkyoptParametryo_splashsplash -- ovládá splash screen
  o_apmapm -- nastavení správy napájení
  o_acpiacpi -- advanced configuration and power interface
  o_ideide -- ovládání IDE subsystémuo_splashParametry jádra: splashSplash screen je obrázek znázorňující průběh spouštění a vypínání.

splash=0
Splash screen je vypnutý. Tato volba je velmi užitečná pro staré monitory a v případě problémů.

splash=verbose
Splash screen je puštěný, ale stále vidíte hlášení jádra.

splash=silent
Splash screen je puštěný a zcela zakrývá hlášení jádra.

Návrat do optstartovacínabídkyo_apmParametry jádra: apmAPM je jedním ze standardů správy napájení používaných na současných počítačích. Obvykle je používán například pro uspání na disk u notebooků a také je odpovědný za vypnutí počítače po ukončení operačního systému. APM je závislé na správně fungujícím BIOSu. V případě poškození BIOSu by měla být funkce APM omezena. Z toho důvodu můžete APM vypnout parametrem:

  apm=off -- kompletní vypnutí APM

Některé velmi nové počítače místo APM používají o_acpiACPI.

Návrat do optstartovacínabídkyo_acpiParametry jádra: acpiACPI (Advanced Configuration and Power Interface) je standard definující nastavení napájení a správu zařízení mezi operačním systémem a BIOSem. Ve výchozím nastavení je acpi zapnuto v případě, že jde o BIOS vydaný po roce 2000. Nejčastěji používané nastavení:

  pci=noacpi -- nepoužívat ACPI k předávání PCI přerušení   acpi=oldboot -- aktivní zůstane pouze ta část ACPI, která je potřebná pro start systému
  acpi=off -- vypnutí ACPI
  acpi=force -- zapnutí ACPI i pro BIOS vydaný před rokem 2000

Na nových počítačích nahrazuje starší o_apmapm systém.

Návrat do optstartovacínabídkyo_ideParametry jádra: ideIDE je na rozdíl od SCSI obvykle používáno na pracovních stanicích. V případě výskytu problémů s IDE systémem můžete použít parametr:

  ide=nodma -- Vypnutí DMA pro všechna IDE zařízení


Návrat do optstartovacínabídky. 