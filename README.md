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
  - "Mobile First": se eligió Flutter (Dart) por su compatibilidad multiplataforma, y Riverpod se encarga de la gestión del estado.
  - Edge AI: TensorFlow Lite permite la inferencia en el dispositivo, lo que reduce la dependencia de una conectividad constante a la nube y los costes de servidor.
  - Base de datos con capacidad offline: Realm proporciona una persistencia local rápida para el historial meteorológico, los datos de los sensores y las predicciones.
  - Comunicación modular: El handshake y el protocolo BLE se han abstraído (IHandshakeModule), lo que permite desarrollar el firmware de IoT (Cesar) de forma independiente mientras que la aplicación móvil utiliza marcadores de posición.

# 3. Desarrollo
El desarrollo se llevó a cabo de forma incremental a través de fases establecidas:
  - Fase 1: Infraestructura. Se planificó y configuró la inicialización del proyecto, los permisos y las dependencias (BLE, ML, DB).
  - Fase 2: Adquisición de datos. Se implementó OpenMeteoClient para obtener el historial de las últimas 24 horas y la previsión para las próximas 48 horas. Se añadieron herramientas de estadística.
  - Fase 3: Puente BLE. Se estableció BleService. Se verificó con éxito el flujo bidireccional con un script de prueba de concepto de Micropython ejecutado sobre una Raspberry Pi Pico 2W. Se verificó la compatibilidad en Android y Linux.
  
  [!] Fase 4: Inferencia. Dado que el entrenamiento sigue en curso, se han creado flujos de trabajo teóricos para normalizar el historial de la base de datos en tensores [1, 10, 1] para futuros modelos (¿GRU/LSTM?). 

# 4. Estado actual
A día de hoy, la aplicación se encuentra en una fase de prueba de concepto (PoC) con el modelo listo y con una automatización completa del flujo de datos:
  - Interfaz de usuario: un panel de control para desarrolladores funcional que incluye monitorización en tiempo real, controles BLE y un conjunto de herramientas de gestión de la ubicación.
  - Canalización BLE: totalmente verificada y automatizada.
    - ffe1: protocolo de enlace verificado.
    - ffe2: 0x01 (sincronización) y 0x02 (puente de datos ambientales) están operativos.
    - ffe3: 0x11 (recepción de datos de humedad del suelo) analiza correctamente y almacena los datos en Realm.
  - Gestión de la ubicación: Se ha implementado la adquisición dinámica de GPS y el selector interactivo de OpenStreetMap. Las coordenadas se almacenan en Realm y controlan el cliente Open-Meteo.
  - Estrategia de automatización:
    - Fase 2: La actualización meteorológica se activa al conectarse y cada 6 horas.
    - Fase 3: El puente meteorológico Auto-0x02 envía datos tras una solicitud de sincronización.
    - Fase 4: La inferencia automática se activa al recibir datos 0x11.

# 5. Trabajo futuro
  - Fase 5: Mejoras en la interfaz de usuario y la experiencia de usuario.
    - Implementar gráficos históricos (sincronizando los datos de Realm con los gráficos).
    - Panel de configuración para umbrales e intervalos de sincronización.
    - Rework apto para usuario final.
  - Seguridad y protocolo: Sustituir 0xDEADBEEF por el protocolo de handshake definitivo desarrollado con César.
  - Integración de ML: Integrar modelos .tflite de producción, perfeccionar la normalización de InferenceBridge, y ajustar el pipeline según sea necesario.
  - Validación: Realizar pruebas de integración de extremo a extremo (Meteo -> App -> Pico -> Predicción) y análisis de batería/esfuerzo e iterar sobre la optimización.

