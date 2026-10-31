# Inicio rápido — Frases Personales

**Objetivo:** obtener un IPA en GitHub y usar Sideloadly desde una PC con Windows.

1. **Extrae** `Frases_Personales_SwiftUI_Proyecto.zip`.
2. En https://github.com/new crea un repositorio llamado `frases-personales-ios` (público para no consumir cuota privada de macOS Actions, si te resulta apropiado).
3. Sube **todo el contenido** de la carpeta extraída, incluida `.github`, a la raíz del repositorio.
4. En GitHub entra a **Actions → Compilar IPA de Frases Personales → Run workflow → Run workflow**.
5. Cuando el proceso termine correctamente, entra en la ejecución y descarga **Artifacts → Frases-Personales-IPA**.
6. **Descomprime** el artefacto de GitHub para obtener `Frases-Personales-unsigned.ipa`.
7. En Windows, instala **Sideloadly** desde https://sideloadly.io y los componentes de iTunes/iCloud de escritorio que indica su sitio.
8. Conecta el iPhone por USB, ábrelo en Sideloadly, arrastra el IPA, introduce tu cuenta de Apple y pulsa **Start**.
9. Si iOS lo pide, confía en el perfil en **Ajustes → General → VPN y gestión de dispositivos**, y habilita **Modo de desarrollador** en **Privacidad y seguridad**.
10. Abre **Mis Frases** en el iPhone. Agrega las frases, selecciona intervalo y horario, activa notificaciones y pulsa **Guardar y programar**.

**Ejemplo recomendado de prueba:** 08:00–22:00, cada 30 minutos = **28 notificaciones diarias**.

**Importante:** máximo 64 notificaciones diarias; las frases asignadas a cada hora se conservan hasta reprogramar. La firma gratuita se renueva cada 7 días; Sideloadly ofrece auto-refresh. **No borres la app al renovar, o podrías perder tus frases**.

Para pasos detallados, solución de errores, privacidad y limitaciones, lee `README.md`.
