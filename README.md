# Revisión del proyecto: Sistema de riego predictivo (TFM)

---

# 1. Objetivos iniciales
El objetivo principal de este proyecto es desarrollar un sistema de riego inteligente y predictivo. El sistema se basa en una aplicación móvil que actúa como centro logístico. Se conecta con una estación IoT a través de BLE. Llega a una veredicto de riego combinando modelos especializados de aprendizaje automático y previsiones meteorológicas. La aplicación se encarga de:
  - Obtener y preprocesar datos ambientales de las previsiones meteorológicas desde Open-Meteo.
  - Transmitir estos datos a la estación IoT para proporcionar contexto ambiental.
  - Recibir datos de humedad del suelo en tiempo real desde la estación.
  - Ejecutar un modelo predictivo de aprendizaje automático para pronosticar la humedad y recomendar acciones de riego.
El usuario es responsable de la decisión final.

# 2. Fundamentos y arquitectura
  - **Soporte multiplataforma**: La aplicación se ejecuta de forma nativa (Android, Linux, iOS, macOS, Windows) y en la Web (Flutter Web) mediante el uso de exportaciones condicionales en Dart durante la compilación:
    - **Base de datos (`DatabaseService`)**: Utiliza Realm DB (`default.realm`) en plataformas nativas para soporte offline, y una base de datos en memoria en la Web para eludir las limitaciones de Realm en el navegador.
    - **BLE (`BleService`)**: Utiliza `flutter_blue_plus` en nativo, y un servicio BLE simulado (Mock) en la Web para recrear los flujos de emparejamiento, sincronización horaria, transferencia de datos e inferencia.
    - **Intérprete ML (`TfliteService`)**: Utiliza `tflite_flutter` en nativo, y `tflite_web` (inicializando TFLite JS WebAssembly vía CDN) en la Web para inferencias en el navegador. Incluye una lógica heurística pura de Dart como respaldo (fallback).
  - **Edge AI**: El modelo de recomendación de riego Random Forest se ejecuta localmente en el dispositivo. El modelo de predicción de humedad LSTM se ejecuta en la estación IoT.
  - **Gestión de estado y localización**: Riverpod gestiona de manera reactiva el estado de la aplicación. Se incluye traducción multiidioma dinámica (inglés y español) controlada mediante `localeProvider` y un diccionario de traducciones.

# 3. Desarrollo
El desarrollo se llevó a cabo de forma incremental a través de fases:
  - **Fase 1: Infraestructura**: Inicialización del proyecto, gestión de permisos y configuración de dependencias básicas.
  - **Fase 2: Adquisición de datos**: Implementación de OpenMeteoClient (historial de 24h y previsión de 48h). Gestión de ubicación mediante GPS automático (intervalo de 30s) y selector manual interactivo basado en OpenStreetMap.
  - **Fase 3: Puente BLE**: Protocolo BLE seguro de autenticación HMAC-SHA256 (Protocolo de Cesar v=1). Sincronización horaria automática (`0x11`) y carga de la previsión de temperatura de 24h (`0x12`) al conectar.
  - **Fase 4: Capa de inferencia**: Inferencia cruzada. La estación calcula la humedad futura (LSTM) y la app ejecuta la decisión de riego (Random Forest en TFLite) combinando la predicción con la radiación solar.
  - **Fase 5: UI/UX y Gráfico Analítico**: Diseño de panel analítico integrado con un gráfico único y scrollable que visualiza humedad histórica, predicción LSTM y pronóstico de radiación.
  - **Fase 7: Optimización y confiabilidad**: Batching de escritura de Realm, negociación de MTU, respuesta de UI reactiva a la desconexión BLE, aislamiento del trigger de RF y reintentos para peticiones HTTP.

# 4. Estado actual
La aplicación se encuentra en un estado funcional de Prueba de Concepto (PoC) con flujo de datos completamente automatizado y optimizado:
  - **Interfaz de usuario rediseñada**: Adaptada a especificaciones técnicas simplificadas:
    - **Estado 0 (Sin Sensor)**: Pantalla con menú inferior de pestañas (Telemetría / Ajustes) y botón central para buscar estaciones IoT.
    - **Estado 1 (Sensor Emparejado)**: Visualización de fecha/ubicación, gráfico analítico interactivo, recomendación visible de riego (Random Forest), y lista vertical con lazy loading del historial.
    - **Vista de Ajustes**: Selector de idioma, estado de permisos (Internet, BLE, GPS), interruptor de ubicación automática/manual, y limpiador de base de datos por dispositivo.
  - **Flujo de comunicación BLE**:
    - Lectura de nonce de desafío (`0x10`), autenticación HMAC en `0x20`, sincronización horaria (`0x11`), envío de clima (`0x12`), descarga de telemetría (`0x20` kind `raw`/`pred`), y disparo de inferencia LSTM (`0x20` op `infer`).
    - Las respuestas largas (`0x21`) se dividen en fragmentos de 128 bytes y se reensamblan en la app.
  - **Corrección de compilación y parches de sistema**:
    - Alineación JVM en Android y configuración de `compileSdkVersion` a 34 para compatibilidad del plugin de Realm con Java 26.
    - Instalación de `libtensorflowlite_c-linux.so` en blobs del bundle Linux.
    - Parche en el paquete local `flutter_blue_plus_linux` para corregir la actualización de dispositivos en caché.
    - Soporte completo para HMAC y decodificación CBOR en el simulador MicroPython (`pico_mock.py` / `pico2W.py`).

# 5. Trabajo futuro
  - **Validación del sistema completo**: Pruebas de campo de extremo a extremo con el hardware físico final (Pico 2W, FPGA).
  - **Perfilado de batería y consumo**: Medir el impacto de cómputo derivado de los escaneos BLE y la ejecución de modelos TFLite.
  - **Mantenimiento de modelos**: Actualizar el intérprete de TFLite ante futuros cambios en los modelos de Machine Learning.


