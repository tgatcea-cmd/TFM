/// Application Internationalization & String Dictionary
/// Supports English (en) and Spanish (es) with system language resolution.
library;

enum AppLanguage { en, es }

class AppDictionary {
  static AppLanguage currentLanguage = AppLanguage.en;

  /// Retrieve a localized string by [key] with optional parameter interpolation.
  /// Example: AppDictionary.get('home.connected', args: {'name': 'Pico 1'})
  static String get(String key, {Map<String, String>? args}) {
    final langMap = _strings[currentLanguage] ?? _strings[AppLanguage.en]!;
    String text = langMap[key] ?? _strings[AppLanguage.en]![key] ?? key;
    
    if (args != null) {
      args.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }

  static const Map<AppLanguage, Map<String, String>> _strings = {
    AppLanguage.en: {
      // --- Navigation & Shell ---
      'nav.home': 'Home',
      'nav.nearby': 'Nearby',
      'nav.localDb': 'Local DB',
      'nav.cloud': 'Cloud',
      'nav.config': 'Config',
      'shell.statusPrefix': 'STATUS: {msg}',
      'shell.statusReady': 'Ready',
      'shell.bleConnected': 'BLE Connected',
      'shell.bleDisconnected': 'BLE Disconnected',
      'shell.hide': 'Hide',
      'shell.statusTab': 'Status',

      // --- HomeScreen ---
      'home.noStationTitle': 'No BLE station connected.',
      'home.noStationSubtitle': 'Use the \'Nearby\' tab to pair a Pico device.',
      'home.connectedDevice': 'Connected: {name}',
      'home.clockUnknown': 'Clock status unknown',
      'home.syncTimeTooltip': 'Sync Time',
      'home.gapLabel': '{gap} gap',
      'home.btnReadStatus': 'Read Status',
      'home.btnRequestData': 'Request Data',
      'home.btnTriggerInference': 'Trigger Inference',
      'home.cardPredictionHeader': 'PREDICTION & RECOMMENDATION',
      'home.verdictPrefix': 'VERDICT: {verdict}',
      'home.verdictDoNotIrrigate': 'DO NOT IRRIGATE',
      'home.verdictIrrigate': 'IRRIGATE',
      'home.minPredictedHumidity': 'Minimum predicted humidity: {val}%\nExpected at: {time}',
      'home.noPredictionData': 'No valid prediction time-series found in database.',
      'home.debugTitle': 'DEBUG DANGER ZONE',
      'home.btnClearLogs': 'Clear Logs',
      'home.btnSimulateTelemetry': 'Simulate Telemetry',
      'home.consoleOutputHeader': 'Console Output:',
      'home.consoleInit': 'Console initialized. Awaiting commands...',
      'home.copyTooltip': 'Copy to Clipboard',
      'home.downloadJsonTooltip': 'Download JSON',
      'home.copySuccessSnackbar': 'Console output copied to clipboard!',
      'home.copySuccessStatus': 'Console output copied to clipboard.',
      'home.exportSuccessSnackbar': 'Exported JSON: {file}',
      'home.exportSuccessStatus': 'Console output saved to JSON: {path}',
      'home.exportErrorStatus': 'Failed to export JSON: {error}',

      // --- NearbyScreen ---
      'nearby.title': 'Nearby BLE Stations',
      'nearby.btnScan': 'SCAN FOR STATIONS',
      'nearby.btnStopScan': 'STOP SCAN',
      'nearby.activeHeader': 'Active Station: {name} ({id})',
      'nearby.btnDisconnect': 'DISCONNECT',
      'nearby.discoveredHeader': 'Discovered Stations',
      'nearby.noStationsFound': 'No Pico stations discovered yet. Tap "Scan for Stations" to scan.',
      'nearby.btnConnect': 'Connect',
      'nearby.btnConnecting': 'Connecting...',
      'nearby.btnDisconnecting': 'Disconnecting...',

      // --- LocalDbScreen ---
      'localDb.title': 'Local Database',
      'localDb.btnClearDb': 'CLEAR LOCAL DB',
      'localDb.registeredHeader': 'Registered Devices',
      'localDb.noDevices': 'No devices found in local database.',
      'localDb.recordsCount': 'Records: {count}',
      'localDb.predictionsCount': 'Predictions: {count}',
      'localDb.statusSynced': 'Synced',
      'localDb.statusUnsynced': 'Unsynced',
      'localDb.clearConfirmTitle': 'Clear Local Database?',
      'localDb.clearConfirmMsg': 'This action will wipe all stored telemetry and predictions.',

      // --- CloudScreen ---
      'cloud.title': 'Cloud Services & Emulation',
      'cloud.endpointLabel': 'API Endpoint: {url}',
      'cloud.statusLabel': 'Status: {status}',
      'cloud.btnTestApi': 'Test API Connection',
      'cloud.btnSyncCloud': 'Sync Cloud Devices',
      'cloud.registeredHeader': 'Registered Cloud Stations:',
      'cloud.noStations': 'No registered stations found on Cloud Server.\nTest the connection or run a Sync.',
      'cloud.coordinates': 'Coordinates: {coords}',
      'cloud.btnEmulateStation': 'Emulate Cloud Station',
      'cloud.emulating': 'Emulating...',

      // --- ConfigScreen ---
      'config.title': 'System Configuration',
      'config.envHeader': 'ENVIRONMENT',
      'config.systemDateTime': 'System Date & Time',
      'config.locationSettings': 'Location Settings',
      'config.locationModeTitle': 'Configure Location Mode',
      'config.locAutoGps': 'Automatic (GPS)',
      'config.locAutoGpsSub': 'Acquire current position using device GPS hardware',
      'config.locManualMap': 'Manual (Interactive Map)',
      'config.locManualMapSub': 'Tap on an interactive map to pick exact field coordinates',
      'config.mapTitle': 'Select Location on Map',
      'config.mapTapInstruction': 'Tap anywhere on the map to place point:\nLat: {lat}, Lon: {lon}',
      'config.btnConfirmLocation': 'Confirm Location',
      'config.networkHeader': 'NETWORK SERVICES',
      'config.openMeteoStatus': 'Open-Meteo API Status',
      'config.cloudPingStatus': 'TFM Cloud Ping',
      'config.agronomicHeader': 'AGRONOMIC SCHEDULE',
      'config.predictionPeriod': 'Prediction Period (LSTM)',
      'config.irrigationPeriod': 'Irrigation Period',
      'config.btnCancel': 'Cancel',
      'config.btnUpdate': 'Update',
      'config.btnApplySave': 'Apply & Save',
    },

    AppLanguage.es: {
      // --- Navigation & Shell ---
      'nav.home': 'Inicio',
      'nav.nearby': 'Cercanos',
      'nav.localDb': 'BD Local',
      'nav.cloud': 'Nube',
      'nav.config': 'Configuración',
      'shell.statusPrefix': 'ESTADO: {msg}',
      'shell.statusReady': 'Listo',
      'shell.bleConnected': 'BLE Conectado',
      'shell.bleDisconnected': 'BLE Desconectado',
      'shell.hide': 'Ocultar',
      'shell.statusTab': 'Estado',

      // --- HomeScreen ---
      'home.noStationTitle': 'Sin estación BLE conectada.',
      'home.noStationSubtitle': 'Use la pestaña \'Cercanos\' para emparejar una estación Pico.',
      'home.connectedDevice': 'Conectado: {name}',
      'home.clockUnknown': 'Estado del reloj desconocido',
      'home.syncTimeTooltip': 'Sincronizar Hora',
      'home.gapLabel': 'desfase {gap}',
      'home.btnReadStatus': 'Leer Estado',
      'home.btnRequestData': 'Solicitar Datos',
      'home.btnTriggerInference': 'Iniciar Inferencia',
      'home.cardPredictionHeader': 'PREDICCIÓN Y RECOMENDACIÓN',
      'home.verdictPrefix': 'VEREDICTO: {verdict}',
      'home.verdictDoNotIrrigate': 'NO REGAR',
      'home.verdictIrrigate': 'REGAR',
      'home.minPredictedHumidity': 'Humedad mínima predicha: {val}%\nEsperada a las: {time}',
      'home.noPredictionData': 'No se encontraron series temporales válidas de predicción.',
      'home.debugTitle': 'ZONA DE PRUEBAS Y CONTROL',
      'home.btnClearLogs': 'Limpiar Logs',
      'home.btnSimulateTelemetry': 'Simular Telemetría',
      'home.consoleOutputHeader': 'Salida de Consola:',
      'home.consoleInit': 'Consola inicializada. Esperando comandos...',
      'home.copyTooltip': 'Copiar al portapapeles',
      'home.downloadJsonTooltip': 'Descargar JSON',
      'home.copySuccessSnackbar': '¡Salida de consola copiada al portapapeles!',
      'home.copySuccessStatus': 'Salida de consola copiada al portapapeles.',
      'home.exportSuccessSnackbar': 'JSON exportado: {file}',
      'home.exportSuccessStatus': 'Consola guardada en JSON: {path}',
      'home.exportErrorStatus': 'Error al exportar JSON: {error}',

      // --- NearbyScreen ---
      'nearby.title': 'Estaciones BLE Cercanas',
      'nearby.btnScan': 'BUSCAR ESTACIONES',
      'nearby.btnStopScan': 'DETENER BÚSQUEDA',
      'nearby.activeHeader': 'Estación Activa: {name} ({id})',
      'nearby.btnDisconnect': 'DESCONECTAR',
      'nearby.discoveredHeader': 'Estaciones Descubiertas',
      'nearby.noStationsFound': 'No se descubrieron estaciones Pico. Pulse "Buscar Estaciones" para escanear.',
      'nearby.btnConnect': 'Conectar',
      'nearby.btnConnecting': 'Conectando...',
      'nearby.btnDisconnecting': 'Desconectando...',

      // --- LocalDbScreen ---
      'localDb.title': 'Base de Datos Local',
      'localDb.btnClearDb': 'VACIAR BD LOCAL',
      'localDb.registeredHeader': 'Dispositivos Registrados',
      'localDb.noDevices': 'No se encontraron dispositivos en la BD local.',
      'localDb.recordsCount': 'Registros: {count}',
      'localDb.predictionsCount': 'Predicciones: {count}',
      'localDb.statusSynced': 'Sincronizado',
      'localDb.statusUnsynced': 'Pendiente',
      'localDb.clearConfirmTitle': '¿Vaciar Base de Datos Local?',
      'localDb.clearConfirmMsg': 'Esta acción eliminará toda la telemetría y predicciones almacenadas.',

      // --- CloudScreen ---
      'cloud.title': 'Servicios Nube y Emulación',
      'cloud.endpointLabel': 'Endpoint API: {url}',
      'cloud.statusLabel': 'Estado: {status}',
      'cloud.btnTestApi': 'Probar Conexión API',
      'cloud.btnSyncCloud': 'Sincronizar Nube',
      'cloud.registeredHeader': 'Estaciones Registradas en la Nube:',
      'cloud.noStations': 'No se encontraron estaciones en el servidor Nube.\nPruebe la conexión o ejecute una Sincronización.',
      'cloud.coordinates': 'Coordenadas: {coords}',
      'cloud.btnEmulateStation': 'Emular Estación Nube',
      'cloud.emulating': 'Emulando...',

      // --- ConfigScreen ---
      'config.title': 'Configuración del Sistema',
      'config.envHeader': 'ENTORNO',
      'config.systemDateTime': 'Fecha y Hora del Sistema',
      'config.locationSettings': 'Configuración de Ubicación',
      'config.locationModeTitle': 'Configurar Modo de Ubicación',
      'config.locAutoGps': 'Automático (GPS)',
      'config.locAutoGpsSub': 'Obtener posición actual con el hardware GPS del dispositivo',
      'config.locManualMap': 'Manual (Mapa Interactivo)',
      'config.locManualMapSub': 'Toque en el mapa interactivo para seleccionar coordenadas exactas',
      'config.mapTitle': 'Seleccionar Ubicación en Mapa',
      'config.mapTapInstruction': 'Toque en cualquier punto del mapa para colocar el marcador:\nLat: {lat}, Lon: {lon}',
      'config.btnConfirmLocation': 'Confirmar Ubicación',
      'config.networkHeader': 'SERVICIOS DE RED',
      'config.openMeteoStatus': 'Estado API Open-Meteo',
      'config.cloudPingStatus': 'Ping Nube TFM',
      'config.agronomicHeader': 'HORARIO AGRONÓMICO',
      'config.predictionPeriod': 'Periodo de Predicción (LSTM)',
      'config.irrigationPeriod': 'Periodo de Riego',
      'config.btnCancel': 'Cancelar',
      'config.btnUpdate': 'Actualizar',
      'config.btnApplySave': 'Aplicar y Guardar',
    },
  };
}
