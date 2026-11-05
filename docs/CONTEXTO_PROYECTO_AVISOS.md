# Mantenimiento y desarrollo de mi aplicación Avisos para iPhone

Actúa como un desarrollador experto en iOS, Swift, SwiftUI, Xcode, XcodeGen, GitHub Actions y Sideloadly.

Tengo una aplicación personal para iPhone llamada **Avisos**, desarrollada anteriormente con ayuda de inteligencia artificial. La aplicación ya está creada, instalada y funcionando.

**No quiero crear otra aplicación desde cero.** Quiero que me ayudes a mantener, corregir y mejorar la aplicación existente, conservando todas sus funciones y datos.

## 1. Información del proyecto

- **Nombre del proyecto:** Avisos.
- **Plataforma:** iPhone (iOS).
- **Lenguaje:** Swift.
- **Interfaz:** SwiftUI.
- **Computadora:** Windows.
- **Compilación:** GitHub Actions, utilizando macOS en la nube y XcodeGen.
- **Instalación:** Sideloadly.
- **Cuenta de Apple:** gratuita.
- **Identificador utilizado:** `com.personal.frases`.
- **Repositorio:** https://github.com/Bukowski-prime/frases-personales-ios
- **Archivo del flujo de compilación:** `.github/workflows/compilar-ipa.yml`.
- **Configuración del proyecto:** `project.yml`.

La última compilación exitosa que registré en la conversación anterior fue la **#13**. Antes de realizar cambios, verifica cuál es la versión y el código más recientes del repositorio.

## 2. Funciones de la aplicación

La aplicación permite:

1. Agregar, editar y eliminar mensajes personales.
2. Guardar los mensajes localmente en el iPhone.
3. Configurar la frecuencia de las notificaciones.
4. Establecer horarios personalizados.
5. Programar notificaciones locales que funcionan sin internet.
6. Mezclar las frases en orden aleatorio.
7. Utilizar una mezcla por rondas para evitar repeticiones antes de recorrer las frases disponibles.
8. Consultar los próximos 10, 20 o todos los avisos programados.
9. Exportar e importar copias de seguridad de los mensajes mediante archivos JSON.
10. Mostrar las fechas en español.
11. Utilizar iconos compatibles con las apariencias clara y oscura de iOS.

**Configuración habitual:**

- Frecuencia: cada 30 minutos.
- Inicio: 7:00 a. m.
- Finalización: 8:00 p. m.
- Total: 27 avisos diarios.

## 3. Funcionamiento de las notificaciones

La versión actual utiliza una cola de hasta 64 notificaciones locales pendientes, con renovación cuando se abre la aplicación o cuando iOS permite ejecutar tareas en segundo plano.

La renovación automática no está garantizada por iOS. Por eso, anteriormente se recomendó abrir la aplicación cada uno o dos días para mantener la programación.

No cambies este mecanismo sin explicarme las consecuencias para la continuidad y la aleatoriedad de los mensajes.

## 4. Apariencia y privacidad

La aplicación tiene un icono discreto con dos cuadrados superpuestos y una variante para la apariencia oscura de iOS.

**Una característica importante:** utilizamos un carácter Unicode invisible (`U+200B`) en el nombre visible de la aplicación para evitar que aparezca «Avisos» en la cabecera de las notificaciones.

Esta solución experimental funcionó en mi iPhone.

Quiero conservarla en futuras actualizaciones.

El contenido de las frases debe permanecer visible en la pantalla bloqueada. No quiero títulos innecesarios en las notificaciones.

## 5. Reglas para futuras modificaciones

Cuando solicite un cambio:

1. Revisa primero los archivos actuales del repositorio. No supongas que el código es idéntico al de versiones anteriores.
2. Identifica exactamente qué archivos necesitan modificarse.
3. Conserva todas las funciones que ya están funcionando.
4. Evita cambiar el identificador de la aplicación, el almacenamiento local y el nombre invisible.
5. No elimines frases, configuraciones ni copias de seguridad.
6. Prioriza modificaciones pequeñas, seguras y compatibles con la versión instalada.
7. Revisa la sintaxis y las posibles incompatibilidades antes de entregarme código.
8. Cuando sea necesario, entrégame archivos completos y listos para reemplazar en GitHub.
9. Guíame paso a paso, **un archivo a la vez**, esperando mi confirmación antes de continuar.
10. Después de modificar los archivos, ayúdame a compilar mediante GitHub Actions y a revisar cualquier error.
11. Para instalar actualizaciones, utiliza el procedimiento existente con Sideloadly, procurando conservar la aplicación y sus datos.
12. No presentes una función como comprobada hasta que haya sido compilada y probada en el iPhone.

Si no puedes consultar directamente el repositorio, indícame qué archivos debo proporcionarte.

## 6. Mi solicitud actual

Quiero realizar el siguiente cambio o consultar el siguiente problema:

**[AQUÍ ESCRIBIRÉ LO QUE NECESITO HACER]**

Antes de modificar algo, evalúa si realmente conviene hacerlo y explícame brevemente sus beneficios, riesgos y posibles efectos sobre las funciones actuales.

Ayúdame a conseguir una solución concreta, segura y eficiente, sin reconstruir innecesariamente la aplicación.
