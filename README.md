
## 📌 DOCUMENTACIÓN IMPORTANTE

**[📖 ABRIR CONTEXTO DEL PROYECTO AVISOS](docs/CONTEXTO_PROYECTO_AVISOS.md)**

Aquí se encuentra toda la información necesaria para mantener, actualizar y modificar la aplicación con ayuda de IA.

---

# Frases Personales — aplicación nativa iOS (SwiftUI)

Proyecto personal para iPhone, desarrollado con **SwiftUI**, compilado en **GitHub Actions** sin firma y preparado para instalación desde **Windows con Sideloadly**.

## 1. Qué incluye

- Agregar, editar y eliminar frases propias en el iPhone.
- Guardarlas localmente mediante `UserDefaults`.
- Activar o desactivar notificaciones.
- Elegir intervalos de **5, 10, 15, 20, 30, 45, 60, 90, 120, 180, 240, 360, 720 y 1440 minutos**.
- Elegir hora inicial y final, incluso si el horario termina al día siguiente.
- Programar notificaciones locales que se **repiten a diario**, sin internet ni app abierta.
- Presentar las notificaciones también mientras la aplicación está abierta.
- Botón **Guardar y programar**: recalcula y sustituye los avisos al modificar frases u horarios.

> **Límite importante:** se admiten **64 horarios diarios como máximo**. El sistema iOS limita el número de solicitudes de notificación pendientes. Si eliges una combinación superior (por ejemplo, 24 horas cada 15 minutos = 96), la aplicación muestra un error y te pide modificar la frecuencia o el horario.
>
> **Otro límite:** cada horario repite **la misma frase en días posteriores**, hasta que pulsas «Guardar y programar» de nuevo. Las frases se distribuyen aleatoriamente al programar y se alternan sin repetir hasta agotar la colección; iOS no garantiza ejecutar código cada vez que aparece una notificación para cambiar su texto.

## 2. Requisitos

- Una computadora **Windows 10/11** y acceso a https://github.com.
- Un **iPhone con iOS 16 o posterior**.
- Una cuenta de GitHub para compilar en una Mac alojada por GitHub.
- **Sideloadly** para Windows, desde https://sideloadly.io.
- Una **cuenta de Apple** (gratuita o de desarrollador) para firmar e instalar.
- Cable USB entre PC e iPhone para la primera instalación.

No se necesita Xcode ni macOS en tu computadora. No se necesita pagar una membresía de Apple Developer para usar la ruta gratuita de 7 días. GitHub puede imponer límites de uso de Actions según tu plan, tipo de repositorio y consumo.

## 3. Preparar un repositorio en GitHub (desde Windows)

1. Descarga `Frases_Personales_SwiftUI_Proyecto.zip` y **extráelo** en Windows.
2. En https://github.com/new, crea un repositorio, por ejemplo `frases-personales-ios`.
3. **Recomendado para este caso:** selecciona **Public** si quieres aprovechar los minutos públicos gratuitos de GitHub Actions. El repositorio contendrá código, **no** las frases que después captures en tu teléfono. Si eliges **Private**, revisa las cuotas de minutos para macOS.
4. Crea el repositorio, entra a **Add file → Upload files** y arrastra el **contenido de la carpeta extraída**, no la carpeta contenedora. Deben quedar en la raíz `project.yml`, `README.md`, la carpeta `Frases` y la carpeta **`.github`**.
5. Confirma con **Commit changes**.
6. Comprueba que existe la ruta exacta **`.github/workflows/compilar-ipa.yml`** en la rama predeterminada. Si la carpeta `.github` no subió, tendrás que crear esa ruta manualmente.

### Estructura esperada

```text
frases-personales-ios/
├── .github/
│   └── workflows/
│       └── compilar-ipa.yml
├── Frases/
│   ├── Assets.xcassets/
│   │   └── AppIcon.appiconset/
│   │       ├── AppIcon.png
│   │       └── Contents.json
│   ├── ContentView.swift
│   ├── FrasesApp.swift
│   └── PhraseStore.swift
├── .gitignore
├── LICENSE
├── project.yml
└── README.md
```

## 4. Compilar el archivo IPA en GitHub Actions

1. En el repositorio, abre la pestaña **Actions**.
2. Si GitHub solicita habilitar Actions, habilítalas.
3. En la lista lateral selecciona **Compilar IPA de Frases Personales**.
4. Haz clic en **Run workflow**, elige la rama predeterminada y vuelve a pulsar **Run workflow**.
5. Abre la ejecución nueva. Espera a que la ejecución indique éxito (marca verde).
6. Abajo, en **Artifacts**, descarga **`Frases-Personales-IPA`**.
7. Extrae el archivo ZIP descargado de GitHub y localiza **`Frases-Personales-unsigned.ipa`**.

El archivo IPA está **sin firmar** intencionalmente: Sideloadly lo firma para tu dispositivo con tu cuenta de Apple. El workflow no solicita ni almacena tu usuario o contraseña de Apple.

Si una compilación da error, copia el texto del paso rojo del workflow. No hace falta reinstalar nada en el iPhone hasta identificar el error.

## 5. Instalar el IPA desde Windows con Sideloadly

1. Descarga Sideloadly **solo** de https://sideloadly.io y sigue su preparación para Windows. Su documentación indica instalar las versiones de escritorio de **iTunes** e **iCloud** desde la web (no las versiones de Microsoft Store).
2. Conecta tu iPhone por USB, desbloquéalo y acepta **Confiar en esta computadora** si aparece.
3. Abre Sideloadly. Selecciona tu iPhone en la lista de dispositivos.
4. Arrastra el archivo **`Frases-Personales-unsigned.ipa`** a Sideloadly.
5. Introduce tu cuenta de Apple en la interfaz de Sideloadly y pulsa **Start**. Completa la verificación requerida por Apple. No compartas contraseñas ni códigos de verificación en GitHub, ni en este chat.
6. En el iPhone, si aparece una advertencia de desarrollador no confiable, entra en **Ajustes → General → VPN y gestión de dispositivos** (la etiqueta puede variar ligeramente) y autoriza el perfil asociado a tu cuenta.
7. Si iOS lo solicita para aplicaciones instaladas desde desarrollo, habilita **Modo de desarrollador** en **Ajustes → Privacidad y seguridad**, reinicia y confirma la activación.
8. Abre **Mis Frases** desde la pantalla de inicio del iPhone.

### Renovación a los siete días

Con una cuenta gratuita, la firma de desarrollo suele ser válida **7 días**. Sideloadly ofrece **auto-refresh** mediante Sideloadly Daemon: actívalo cuando instales, mantén Windows disponible y utiliza USB o la conexión Wi-Fi compatible. No está garantizado si la computadora está apagada o desconectada. Si la app deja de abrirse, vuelve a firmarla e instalarla **con la misma cuenta y el mismo identificador**.

**No desinstales la app para renovarla**: como las frases se guardan localmente, al eliminarla puedes perderlas. La primera versión aún no incluye exportación ni copia de seguridad.

## 6. Configurar las frases y las notificaciones

1. Abre **Mis Frases** y agrega tus frases con **+**.
2. Para editar una, tócala; para borrarla, deslízala a la izquierda.
3. Activa **Activar notificaciones**.
4. Elige **Frecuencia**, **Desde** y **Hasta**.
5. Observa **Avisos diarios**. Deben ser **64 o menos**.
6. Pulsa **Guardar y programar** y permite las notificaciones cuando lo solicite iOS.
7. Comprueba que aparece **«Programados X avisos diarios»**.

Ejemplos:

| Configuración | Avisos al día | ¿Admitida? |
|---|---:|---|
| 08:00–22:00, cada 30 min | 28 | Sí |
| 08:00–22:00, cada 15 min | 56 | Sí |
| 00:00–00:00, cada 30 min | 48 | Sí |
| 00:00–00:00, cada 15 min | 96 | No, supera 64 |
| 22:00–08:00, cada 60 min | 10 | Sí |

**Nota:** por diseño la hora final es exclusiva: en el intervalo 08:00–22:00, la última notificación cada 30 minutos aparece a las 21:30. Si «Desde» y «Hasta» son iguales, el sistema interpreta un ciclo de 24 horas.

## 7. Problemas frecuentes

**No encuentro Actions / Run workflow.** Comprueba que `.github/workflows/compilar-ipa.yml` está en la raíz del repositorio y en la rama predeterminada y que Actions están habilitadas.

**No encuentro el IPA.** Abre el resultado de la ejecución; el IPA viene *dentro* del ZIP de **Artifacts**. El nombre interno es `Frases-Personales-unsigned.ipa`.

**El iPhone no aparece en Sideloadly.** Desbloquéalo, cambia de cable/puerto y verifica que confiaste en la computadora. Revisa los requisitos de iTunes/iCloud de Sideloadly.

**La app no abre.** Comprueba la confianza del perfil y el modo desarrollador; si ya pasaron 7 días, renueva la firma.

**Las notificaciones no aparecen.** Comprueba el permiso en Ajustes → Notificaciones → Mis Frases; desactiva filtros Focus/Concentración o Resumen programado para probar; verifica que esté activado el interruptor y que hayas pulsado **Guardar y programar**. Si quedan cero avisos programados, abre la app y aplícalos de nuevo.

**Las frases no cambian cada día.** Es deliberado: las notificaciones locales recurrentes mantienen el contenido asignado hasta que vuelves a programar. Cambiar la frase en el editor sin pulsar «Guardar y programar» no modifica avisos ya registrados.

**Quiero notificaciones cada cinco minutos las 24 horas.** Necesitaría 288 avisos al día: **no lo permite esta estrategia fiable de repetición diaria**. Una versión futura podría estudiar un servidor de notificaciones push, con más infraestructura y otras limitaciones.

## 8. Privacidad y mantenimiento

- Las frases se almacenan en `UserDefaults` dentro del contenedor de la app, no en GitHub.
- No se solicitan permisos de contactos, localización, fotos ni micrófono.
- El código no incluye compras, anuncios, servidores ni recopilación de estadísticas.
- El workflow sube el IPA generado como un artefacto de GitHub durante 30 días.
- Las notificaciones locales pueden verse afectadas por la configuración de iOS (Concentración, resumen, permisos o entrega del sistema).
- Las actualizaciones del IPA deberían instalarse sobre el mismo bundle ID para intentar conservar los datos. **Elimina la app solo si aceptas perder el contenido local.**

## 9. Estado de verificación

Los archivos de Swift y YAML se revisaron sintácticamente en un entorno Linux. **La compilación iOS real en Xcode y la instalación en un iPhone no se pueden ejecutar en este entorno**; el paso de GitHub Actions es la validación definitiva del proyecto y puede requerir ajustes si cambian Xcode, GitHub o Sideloadly.

### Fuentes oficiales

- [Apple — Notificaciones locales](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- [Apple — UNCalendarNotificationTrigger](https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger)
- [GitHub — Imágenes macOS para Actions](https://github.com/actions/runner-images)
- [XcodeGen — Especificación `project.yml`](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
- [Sideloadly — sitio oficial](https://sideloadly.io)
- [Sideloadly — preguntas frecuentes](https://sideloadly.io/faq.html)
