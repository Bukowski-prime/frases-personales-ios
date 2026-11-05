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
- **Documento de contexto:** `docs/CONTEXTO_PROYECTO_AVISOS.md`.

### Estado del proyecto

La última compilación exitosa confirmada durante el desarrollo anterior fue la **#13**.

Este dato es histórico y debe actualizarse cuando se confirme una compilación más reciente.

Antes de realizar modificaciones, verifica siempre:

- El código más reciente del repositorio.
- La última compilación exitosa de GitHub Actions.
- Qué versión está instalada actualmente en el iPhone.
- Cuáles funciones están implementadas y cuáles han sido probadas.

No supongas que una compilación exitosa significa que todas las funciones se han probado correctamente.

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
12. Mostrar las frases directamente en la pantalla bloqueada del iPhone.

### Configuración habitual

- **Frecuencia:** cada 30 minutos.
- **Inicio:** 7:00 a. m.
- **Finalización:** 8:00 p. m.
- **Total:** 27 avisos diarios.

Estos valores son configurables dentro de la aplicación.

## 3. Funcionamiento de las notificaciones

La versión actual utiliza una cola de hasta **64 notificaciones locales pendientes**, con renovación cuando se abre la aplicación o cuando iOS permite ejecutar tareas en segundo plano.

La renovación automática no está garantizada por iOS. Por eso, anteriormente se recomendó abrir la aplicación cada uno o dos días para mantener la programación.

### Aleatoriedad

El sistema utiliza una mezcla por rondas.

Su objetivo es:

1. Seleccionar frases sin seguir el orden en que fueron agregadas.
2. Mostrar todas las frases antes de comenzar una nueva ronda, siempre que existan suficientes avisos.
3. Evitar repeticiones consecutivas cuando existan al menos dos frases diferentes.
4. Generar nuevas distribuciones para los avisos de distintas jornadas.
5. Conservar la continuidad de la mezcla durante la renovación de las notificaciones.

### Limitaciones importantes

- iOS limita el número de notificaciones locales pendientes.
- Las tareas de actualización en segundo plano no tienen una ejecución garantizada.
- Las notificaciones programadas pueden agotarse si la aplicación no consigue renovarlas.
- Las notificaciones recurrentes pueden mejorar la continuidad, pero reutilizan el contenido asignado hasta que se reprograme.
- La instalación mediante una cuenta gratuita de Apple puede requerir renovar periódicamente la firma mediante Sideloadly.

**No cambies el mecanismo de notificaciones sin explicar previamente las consecuencias para la continuidad, la aleatoriedad y la conservación de los datos.**

## 4. Apariencia y privacidad

La aplicación tiene un icono discreto con dos cuadrados superpuestos y una variante para la apariencia oscura de iOS.

### Nombre invisible

Una característica importante es el uso experimental de un carácter Unicode invisible (`U+200B`) como nombre visible de la aplicación.

Se utilizó para evitar que apareciera «Avisos» en la cabecera de las notificaciones.

**Esta solución fue probada y funcionó en mi iPhone.**

Quiero conservarla en futuras actualizaciones.

Ten en cuenta que este comportamiento no está garantizado por Apple para todas las versiones de iOS.

### Presentación de las notificaciones

- El contenido de las frases debe permanecer visible en la pantalla bloqueada.
- No quiero títulos adicionales innecesarios.
- Quiero conservar el nombre invisible mientras continúe funcionando.
- El icono debe permanecer discreto.
- Las frases deben guardarse completas, aunque iOS pueda recortar visualmente las más largas.

### Privacidad y almacenamiento

Las frases se guardan localmente en el iPhone.

La aplicación también permite exportar e importar copias de seguridad JSON.

Las copias de seguridad pueden contener información personal y deben almacenarse en ubicaciones privadas.

**No publiques mis frases personales, credenciales, identificadores sensibles ni archivos de respaldo en el repositorio público de GitHub.**

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
13. Antes de reemplazar archivos, comprueba que la nueva versión no elimine funciones incorporadas anteriormente.
14. Si una modificación provoca errores, identifica primero su causa exacta en los registros de compilación.
15. No modifiques varios componentes simultáneamente si el problema puede resolverse cambiando uno solo.
16. Antes de introducir cambios importantes, recomienda conservar una copia funcional del IPA y un respaldo de las frases.

Si no puedes consultar directamente el repositorio, indícame qué archivos debo proporcionarte.

### Criterios para recomendar mejoras

Antes de realizar cualquier modificación:

- Evalúa si realmente es necesaria.
- Explica sus beneficios y limitaciones.
- Identifica los riesgos para las funciones existentes.
- Prioriza la estabilidad y la fiabilidad.
- Evita agregar complejidad innecesaria.

**La prioridad es mantener Avisos funcionando correctamente, no incorporar funciones nuevas constantemente.**

## 6. Mantenimiento del contexto del proyecto

Este documento es la referencia principal para continuar desarrollando y manteniendo Avisos con ayuda de inteligencia artificial.

**Cada vez que se complete una modificación importante de la aplicación, la IA deberá ayudarme a actualizar este mismo documento.**

### Reglas de mantenimiento

1. Revisar el estado actual del proyecto antes de proponer cambios.
2. Actualizar las funciones, configuraciones y archivos afectados.
3. Registrar brevemente qué se modificó, por qué y cuándo.
4. Distinguir entre cambios pendientes, compilados y probados en el iPhone.
5. Eliminar o corregir información obsoleta para evitar contradicciones.
6. Conservar la información técnica importante de versiones anteriores cuando siga siendo relevante.
7. Proporcionarme el texto exacto que debo agregar o reemplazar en `docs/CONTEXTO_PROYECTO_AVISOS.md`.
8. Recordarme actualizar el documento únicamente después de confirmar que la modificación funciona correctamente.
9. Actualizar la referencia de la última compilación exitosa cuando corresponda.
10. Mantener el documento organizado, conciso y coherente con el código existente.
11. No duplicar información innecesariamente.
12. No eliminar información crítica sobre compatibilidad, almacenamiento, firma o notificaciones.

### Registro de futuras actualizaciones

Cuando se complete una modificación importante, registrar:

- **Fecha:** día en que se confirmó el cambio.
- **Modificación:** qué función se agregó, corrigió o eliminó.
- **Motivo:** por qué se realizó.
- **Archivos afectados:** nombres y ubicaciones.
- **Compilación:** número de ejecución de GitHub Actions.
- **Estado:** pendiente, compilado o probado en iPhone.
- **Observaciones:** limitaciones o precauciones importantes.

Mantener el registro breve y conservar los cambios históricos relevantes sin convertir el documento en una lista excesivamente larga.

### Procedimiento al finalizar una actualización

1. Confirmar que GitHub Actions haya compilado correctamente.
2. Instalar la actualización en el iPhone.
3. Comprobar que la nueva función funciona.
4. Verificar que las funciones anteriores sigan disponibles.
5. Confirmar que los mensajes y configuraciones se hayan conservado.
6. Actualizar este documento para reflejar el estado real del proyecto.
7. Guardar la documentación actualizada en GitHub mediante **Commit changes**.

**No considerar terminada una actualización importante hasta que el contexto del proyecto refleje el estado real de la aplicación.**
