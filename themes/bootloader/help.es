helpUtilización del sistema de ayudaLa ayuda en línea del cargador de arranque es de carácter contextual y le proporciona información sobre el elemento de menú seleccionado o, durante la edición de las opciones de arranque, busca información acerca de la opción sobre la que está colocado el cursor.

Teclas de navegación

  Flecha arriba: seleccionar enlace anterior
  Flecha abajo: seleccionar enlace siguiente
  Flecha izquierda, Retroceso: volver al punto anterior
  Flecha derecha, Intro, Espacio: seguir enlace
  Re. Pág.: retroceder una página
  Av. Pág.: avanzar una página
  Inicio: ir al principio de la página
  Fin: ir al final de la página
  Esc: abandonar la ayuda

Volver a las optopcionesdearranquestartupSelección de la pantalla de bienvenidaCon F3 puede cambiar el modo de la pantalla de bienvenida. Si lo prefiere, también puede utilizar directamente la opción o_splashsplash del kernel.

native desactiva la pantalla de bienvenida (equivale a splash=0)

silent suprime todos los mensajes de arranque y del kernel y muestra en su lugar una barra de progreso.

verbose muestra una imagen y los mensajes de arranque y del kernel.

Volver a las optopcionesdearranquekeytableSelección del idioma y de la distribución del tecladoCon F2 puede cambiar el idioma y la distribución del teclado del cargador de arranque.

Volver a las optopcionesdearranqueprofileSeleccionar perfilCon F4 puede seleccionar un perfil. El sistema se iniciará entonces con la configuración guardada en ese perfil.

Volver a las optopcionesdearranqueoptOpciones de arranqueo_splashsplash -- determina el comportamiento de la pantalla de bienvenida
  o_apmapm -- cambia la gestión de energía
  o_acpiacpi -- Advanced Configuration and Power Interface
  o_ideide -- controla el subsistema IDEo_splashOpciones del kernel: splashLa pantalla de bienvenida es la imagen mostrada durante el inicio del sistema.

splash=0
La pantalla de bienvenida está desactivada. Esta opción puede resultar de utilidad en caso de tener un monitor muy viejo o de que se produzca algún error.

splash=verbose
Activa la pantalla de bienvenida mostrando al mismo tiempo los mensajes de arranque y del kernel.

splash=silent
Activa la pantalla de bienvenida sin mostrar ningún mensaje. En su lugar aparece en pantalla una barra de progreso.

Volver a las optopcionesdearranqueo_apmOpciones del kernel: apmAPM es uno de los dos métodos de gestión de energía utilizados en los ordenadores actuales. Aunque se emplea principalmente en portátiles para funciones como 'suspend to disk', también puede encargarse de desconectar el ordenador después de apagar el sistema. APM depende de que la BIOS funcione correctamente. Si la BIOS tiene una avería, las funciones de APM pueden verse restringidas o APM puede hacer incluso que el ordenador deje de funcionar. Así pues, puede desconectarlo con el parámetro

  apm=off -- desactiva APM completamente

Algunos ordenadores de fabricación reciente pueden sacarle más partido al método o_acpiACPI, más moderno.

Volver a las optopcionesdearranqueo_acpiOpciones del kernel: acpiACPI (Advanced Configuration and Power Interface) es un estándar que define las interfaces de gestión de energía y configuración entre el sistema operativo y la BIOS. Por defecto, acpi se activa cuando se detecta una BIOS de fabricación posterior al año 2000. Existen diversos parámetros de uso extendido para determinar el comportamiento de ACPI:

  pci=noacpi -- no utilizar ACPI para enrutar interrupciones PCI
  acpi=oldboot -- sólo permanecen activadas las partes de ACPI relevantes    para el arranque
  acpi=off -- desactiva ACPI completamente
  acpi=force -- activa ACPI aunque la BIOS sea anterior a 2000

Sustituye al antiguo sistema o_apmapm especialmente en ordenadores de fabricación reciente.

Volver a las optopcionesdearranqueo_ideOpciones del kernel: ideAl contrario que SCSI, IDE se suele utilizar en la mayoría de los sistemas de sobremesa. Para evitar algunos problemas de hardware que afectan a los sistemas IDE, utilice el parámetro del kernel:

  ide=nodma -- desactiva dma para los dispositivos IDE


Volver a las optopcionesdearranque. 