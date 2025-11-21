# Flutter WebRTC Video Call App 📱📹

Esta aplicación es una prueba técnica que implementa videollamadas 1 a 1 en tiempo real utilizando **Flutter**, **WebRTC** para la transmisión de media y **Firebase Firestore** para el proceso de señalización.

La app sigue una arquitectura limpia basada en **Bloc/Cubit** para la gestión de estado.

## 🧪 Probar la App Ahora

He desplegado la aplicación para facilitar la prueba inmediata sin necesidad de compilar código:

- 🌐 **Versión Web:** [https://yourvideocallvideo.web.app](https://yourvideocallvideo.web.app)
- 📱 **Android APK:** Puedes descargar el instalable directamente desde la sección de [Releases](https://github.com/DelaRosaJose/videocallapp/releases) de este repositorio.

### ⚠️ Notas Importantes para la Prueba

Para garantizar la mejor experiencia durante la evaluación, se recomienda realizar las pruebas entre **Android y Web** o **Android y Android**.

Existen algunas limitaciones conocidas en otros escenarios debido a restricciones de plataforma:

- **Web a Web (Mismo dispositivo):** Si se prueba abriendo dos pestañas en la misma PC, es posible que el video del _Guest_ no se renderice en el _Caller_.
- **iOS:** El enrutamiento de audio en iOS presenta limitaciones en la versión actual (el audio podría no escucharse correctamente por los altavoces).

## 🚀 Características Implementadas

- **Creación de Sala:** Generación automática de IDs únicos.
- **Unirse a Sala:** Conexión mediante ID compartido.
- **Video 1 a 1:** Transmisión de Audio y Video en tiempo real.
- **Gestión de Estado Reactiva:** Uso de `flutter_bloc`.
- **Señalización:** Intercambio de Ofertas, Respuestas y Candidatos ICE mediante Firestore.
- **Limpieza de Recursos:** Borrado automático de la sala y desconexión de streams al finalizar.

### 🌟 Bonus / Extras Incluidos

- **Soporte Multiplataforma:** Probado en **Android**, **IOS** y **Web**.
- **Swap de Vistas:** Tocar la cámara pequeña intercambia su posición con la grande.
- **Indicador de Conexión:** Feedback visual (colores y texto) del estado de la conexión P2P.
- **Controles Avanzados:** Mute/Unmute, Cambio de cámara (Frontal/Trasera) y Copiado de ID al portapapeles.
- **Manejo de Errores:** Feedback visual mediante SnackBars ante fallos de conexión.

## ⚙️ Configuración e Instalación

### Prerrequisitos

- Flutter SDK instalado.
- Un dispositivo físico Android o Emulador.
- (Opcional) Navegador Chrome para pruebas Web.

### Pasos

1.  **Clonar el repositorio:**

    ```bash
    git clone https://github.com/DelaRosaJose/videocallapp.git
    cd videocallapp
    ```

2.  **Instalar dependencias:**

    ```bash
    flutter pub get
    ```

3.  **Configuración de Firebase:**

    - El proyecto utiliza `flutterfire_cli` y **ya está totalmente configurado**.
    - **Nota para el evaluador:** He incluido los archivos de configuración (`firebase_options.dart`, `google-services.json`, etc.) en el repositorio para que la aplicación sea **Plug & Play**.
    - No es necesario crear un proyecto en Firebase ni generar nuevas credenciales; la app está lista para conectarse al entorno de pruebas.

4.  **Ejecutar la App:**
    ```bash
    flutter run
    ```

### Explicación breve del Flujo de Señalización:

1.  **Caller** crea oferta SDP, la guarda en Firestore y escucha `guestCandidates`.
2.  **Guest** lee la oferta, crea una respuesta SDP, la sube a Firestore y escucha `callerCandidates`.
3.  Ambos pares sincronizan sus descripciones locales y remotas.
4.  Los candidatos ICE se intercambian a través de las subcolecciones para atravesar NATs/Firewalls hasta establecer la conexión P2P (`RTCPeerConnectionState.connected`).

---

Hecho con 💙 y Flutter.
