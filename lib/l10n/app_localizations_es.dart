// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Panel Predictivo Savia';

  @override
  String get hide => 'Ocultar';

  @override
  String get status => 'Estado';

  @override
  String get cancel => 'Cancelar';

  @override
  String statusLabel(String msg) {
    return 'ESTADO: $msg';
  }

  @override
  String get verdictLstmIrrigate => 'REGAR: Caída de humedad prevista';

  @override
  String get verdictLstmHealthy => 'SALUDABLE: Nivel de humedad suficiente';

  @override
  String get verdictRfSaturation =>
      'RIESGO DE SATURACIÓN: Riego perjudicial mañana. NO REGAR.';

  @override
  String get verdictRfHealthy => 'SALUDABLE: Riego seguro / No perjudicial.';

  @override
  String get verdictEmuPerjudicial =>
      'RIESGO DE SATURACIÓN: Riego perjudicial mañana. NO REGAR.';

  @override
  String get verdictEmuHealthy => 'SALUDABLE: Riego seguro / No perjudicial.';

  @override
  String get mainScreenError => 'Menú Desconocido';

  @override
  String get mainStatusReady => 'Listo';

  @override
  String get mainStatusBleConnected => 'Conectado a la estación';

  @override
  String get mainStatusBleDisconnected => 'Desconectado de la estación';

  @override
  String get homeTab => 'Inicio';

  @override
  String get nearbyTab => 'Cercanos';

  @override
  String get localDbTab => 'BD Local';

  @override
  String get cloudTab => 'Nube';

  @override
  String get configTab => 'Configuración';

  @override
  String get homeConsoleInit =>
      'Consola Inicializada. Los resultados de los comandos aparecerán aquí...';

  @override
  String get homeConsoleCopiedSnack => 'Copiado al portapapes!';

  @override
  String get homeConsoleCopiedStatus => 'Consola copiada al portapapeles';

  @override
  String homeExportJsonSnack(String fileName) {
    return 'JSON de consola exportado $fileName';
  }

  @override
  String homeExportJsonStatus(String path) {
    return ' JSON de consola exportado: $path';
  }

  @override
  String homeExportJsonFailed(String error) {
    return 'Error al exportar JSON: $error';
  }

  @override
  String homeBleAsyncData(String data) {
    return 'Recibida telemetría de la estación de forma asíncrona:\n$data';
  }

  @override
  String homeGapYears(String years) {
    return '$years año(s)';
  }

  @override
  String homeGapDays(String days) {
    return '$days día(s)';
  }

  @override
  String homeGapHours(String hours) {
    return '$hours hora(s)';
  }

  @override
  String homeGapMins(String mins) {
    return '$mins min';
  }

  @override
  String homeGapSecs(String secs) {
    return '$secs seg';
  }

  @override
  String get homeExecutingSync => 'Sincronizando el reloj de la estación...';

  @override
  String homeSyncSuccess(String date) {
    return 'Sincronización del reloj completada. La nueva fecha es: $date';
  }

  @override
  String get homeSyncCompleted => 'Sincronización del reloj completada.';

  @override
  String homeSyncErrorConsole(String error) {
    return 'Error al sincronizar reloj de la estación:\n$error';
  }

  @override
  String get homeSyncFailedStatus =>
      'Fallo al sincronizar reloj de la estación.';

  @override
  String get homeVoidOutput => 'Éxito (Sin más información)';

  @override
  String homeExecutingAction(String name) {
    return 'Ejecutando $name...';
  }

  @override
  String homeActionRes(String name, String res) {
    return 'Resultado de $name:\n$res';
  }

  @override
  String homeActionCompleted(String name) {
    return '$name Completado.';
  }

  @override
  String homeActionError(String name, String error) {
    return 'Error durante $name:\n$error';
  }

  @override
  String homeActionFailed(String name) {
    return 'Fallo durante $name.';
  }

  @override
  String get homeDebugTitle => 'DEBUG ONLY';

  @override
  String get homeBtnMock => 'Forzar rellenado de datos';

  @override
  String get homeBtnClearStorage => 'Limpiar almacenamiento de la estación';

  @override
  String get homeAiTitleYellow => 'RECOMENDACIÓN DEL SISTEMA | Precaución';

  @override
  String get homeAiTitle => 'RECOMENDACIÓN DEL SISTEMA';

  @override
  String homeAiYellowWarning(int endH, int startH) {
    return 'FASE DE RECOGIDA DE DATOS ($endH:00 - $startH:00). La predicción óptima es en el periodo de Predicción.';
  }

  @override
  String homeAiMinHum(String humidity, String date) {
    return 'Humedad mínima predicha: $humidity%\nEsperado para el: $date';
  }

  @override
  String get homeAiNoData =>
      'No se han encontrado datos para la predicción en la base de datos.';

  @override
  String get homeNoBleConnected =>
      'No estás conectado a una estación.\nUsa el menú de \'Cercanía\' para conectarte a una estación válida.';

  @override
  String homeConnectedTitle(String devName) {
    return 'Conectado: $devName';
  }

  @override
  String get homeClockUnknown => 'Estado del reloj desconocido.';

  @override
  String get homeTooltipSync => 'Sincronizar Reloj';

  @override
  String homeGapLabel(String gap) {
    return 'Hueco $gap';
  }

  @override
  String get homeBtnReadStatus => 'Obtener Estado';

  @override
  String get homeBtnRequestData => 'Obtener Telemetría';

  @override
  String get homeBtnTriggerInference => 'Lanzar Predicción';

  @override
  String get homeConsoleTitle => 'Salida de Consola:';

  @override
  String get homeTooltipCopy => 'Copiar al Portapapeles';

  @override
  String get homeTooltipDownload => 'Descargar JSON';

  @override
  String get dbSyncingCloud => 'Syncing with Cloud API...';

  @override
  String dbSyncCompleted(int count) {
    return 'Cloud sync completed. Loaded $count devices from cloud/local DB.';
  }

  @override
  String dbSyncError(String error) {
    return 'Cloud Sync Error: Connection unavailable or failed ($error)';
  }

  @override
  String get dbNoSelection => 'No device selected! Select a device first.';

  @override
  String dbRunningInference(String name, String id) {
    return 'Running Random Forest Inference for $name ($id)...';
  }

  @override
  String dbInferenceFinished(String verdict) {
    return 'RF Inference Finished: $verdict';
  }

  @override
  String dbInferenceFailed(String error) {
    return 'Inference Failed: $error';
  }

  @override
  String get dbClearTitle => 'Clear Local Database?';

  @override
  String get dbClearDesc =>
      'This will delete all saved station telemetry and prediction records stored locally.';

  @override
  String get dbBtnClearData => 'Clear All Data';

  @override
  String get dbClearSuccess => 'Local DB records cleared successfully.';

  @override
  String get dbRfNotCalculated => 'NOT CALCULATED';

  @override
  String get dbRfYellowTitle => 'RANDOM FOREST RECOMMENDATION (YELLOW ZONE)';

  @override
  String get dbRfTitle => 'RANDOM FOREST RECOMMENDATION';

  @override
  String dbRfYellowWarning(int endH, int startH) {
    return '[DATA GATHERING PHASE] System is in Yellow Zone ($endH:00 - $startH:00). Stored predictions are for observation only.';
  }

  @override
  String dbRfMinHum(String humidity, String date) {
    return 'Minimum predicted humidity: $humidity%\nExpected at: $date';
  }

  @override
  String get dbRfNoPredictions => 'No predictions stored for this device yet.';

  @override
  String get dbScreenTitle => 'Local DB Devices';

  @override
  String get dbBtnSyncCloud => 'Sync Cloud';

  @override
  String get dbBtnClearDb => 'Clear DB';

  @override
  String get dbNoDevices =>
      'No saved devices found in Local DB.\nPair a BLE station or run sync with Cloud to populate.';

  @override
  String get dbStateSynced => 'SYNCED';

  @override
  String get dbStateUnsynced => 'UNSYNCED';

  @override
  String dbTelemetryInfo(int records, int predictions) {
    return 'Telemetry Records: $records  |  Predictions: $predictions';
  }

  @override
  String dbLocationInfo(String lat, String lon) {
    return '  |  Lat: $lat, Lon: $lon';
  }

  @override
  String get dbBtnRunInference => 'Run RF Inference';

  @override
  String nbFoundDevices(int count) {
    return 'Found $count devices...';
  }

  @override
  String get nbRefreshingScan => 'Refreshing BLE scan...';

  @override
  String nbConnectDialogTitle(String name) {
    return 'Connect to $name';
  }

  @override
  String nbDeviceId(String id) {
    return 'Device ID: $id';
  }

  @override
  String nbSavedSecret(String secret) {
    return 'Saved secret: $secret';
  }

  @override
  String get nbTooltipShowSaved => 'Show saved secret';

  @override
  String get nbTooltipHideSaved => 'Hide saved secret';

  @override
  String get nbLeaveBlankHint => 'Leave blank to use the saved secret.';

  @override
  String get nbSecretLabel => 'Handshake Secret';

  @override
  String get nbTooltipShowSecret => 'Show secret';

  @override
  String get nbTooltipHideSecret => 'Hide secret';

  @override
  String get nbBtnConnect => 'Connect';

  @override
  String nbConnectingStatus(String name) {
    return 'Connecting to $name...';
  }

  @override
  String nbConnectedSuccess(String name) {
    return 'Connected successfully to $name!';
  }

  @override
  String get nbConnectionFailed =>
      'Connection failed. Please check the secret or device range.';

  @override
  String get nbDisconnectedStatus => 'Disconnected from station.';

  @override
  String get nbScreenTitle => 'Nearby BLE Stations';

  @override
  String get nbBtnDisconnect => 'Disconnect';

  @override
  String get nbBtnScan => 'Scan';

  @override
  String nbCurrentConnection(String name) {
    return 'Currently connected to: $name';
  }

  @override
  String get nbNegotiatingStatus => 'Negotiating handshake...';

  @override
  String get nbNoDevices =>
      'No devices found.\nEnsure your Pico station is powered and advertising.';

  @override
  String nbDeviceSub(String id, int rssi) {
    return '$id  •  RSSI: $rssi dBm';
  }

  @override
  String get nbUnknownDev => 'Unknown';

  @override
  String get nbUnnamedDev => 'Unnamed Device';

  @override
  String get cfgChecking => 'Checking...';

  @override
  String get cfgAcquiringGps => 'Acquiring GPS location...';

  @override
  String cfgGpsUpdated(String lat, String lon) {
    return 'Location updated automatically via GPS: Lat $lat, Lon $lon';
  }

  @override
  String get cfgGpsFailed =>
      'Failed to get GPS location. Check location permissions/services.';

  @override
  String cfgGpsError(String error) {
    return 'GPS Location Error: $error';
  }

  @override
  String get cfgMapTitle => 'Select Location on Map';

  @override
  String cfgMapHint(String lat, String lon) {
    return 'Tap anywhere on the map to place point:\nLat: $lat, Lon: $lon';
  }

  @override
  String get cfgBtnConfirmLoc => 'Confirm Location';

  @override
  String cfgMapUpdated(String lat, String lon) {
    return 'Location manually set: Lat $lat, Lon $lon';
  }

  @override
  String get cfgLocModeTitle => 'Configure Location Mode';

  @override
  String get cfgLocModeAuto => 'Automatic (GPS)';

  @override
  String get cfgLocModeAutoDesc =>
      'Acquire current position using device GPS hardware';

  @override
  String get cfgLocModeManual => 'Manual (Interactive Map)';

  @override
  String get cfgLocModeManualDesc =>
      'Tap on an interactive map to pick exact field coordinates';

  @override
  String cfgPredStartUpdated(int start) {
    return 'Prediction start updated to $start:00.';
  }

  @override
  String cfgPredLimit(int base) {
    return 'Limit reached: Prediction start can only be adjusted ±3h from base ($base:00).';
  }

  @override
  String cfgIrrEndUpdated(int end) {
    return 'Irrigation end updated to $end:00.';
  }

  @override
  String cfgIrrLimit(int base) {
    return 'Limit reached: Irrigation end can only be adjusted ±3h from base ($base:00).';
  }

  @override
  String get cfgMeteoOk => 'OK (200)';

  @override
  String cfgMeteoError(int code) {
    return 'Error ($code)';
  }

  @override
  String get cfgMeteoOffline => 'Offline / Failed';

  @override
  String get cfgPingTesting => 'Testing...';

  @override
  String cfgPingRes(String status, int ms) {
    return '$status ($ms ms)';
  }

  @override
  String get cfgPingFailed => 'Unreachable / Failed';

  @override
  String get cfgSavedStatus =>
      'Configuration applied and saved to database & live ApiClient!';

  @override
  String get cfgEndpointTitle => 'Edit Cloud Endpoint';

  @override
  String get cfgEndpointLabel => 'Server URL';

  @override
  String cfgEndpointHint(String hint) {
    return 'e.g. $hint';
  }

  @override
  String get cfgBtnUpdate => 'Update';

  @override
  String get cfgEndpointUpdated =>
      'Cloud endpoint updated. Remember to press Apply & Save.';

  @override
  String cfgLocString(String lat, String lon, String type) {
    return 'Lat: $lat, Lon: $lon ($type)';
  }

  @override
  String get cfgScreenTitle => 'System Configuration';

  @override
  String get cfgBtnApplySave => 'Apply & Save';

  @override
  String get cfgEnvSection => 'ENVIRONMENT';

  @override
  String get cfgSysTimeLabel => 'System Date & Time';

  @override
  String get cfgLocSettingsLabel => 'Location Settings';

  @override
  String get cfgTooltipLoc => 'Configure Location Mode';

  @override
  String get cfgNetSection => 'NETWORK SERVICES';

  @override
  String get cfgMeteoLabel => 'Open-Meteo API Status';

  @override
  String get cfgCloudLabel => 'Cloud Server Endpoint';

  @override
  String get cfgTooltipEditEnd => 'Edit Endpoint';

  @override
  String get cfgAgroSection => 'AGRONOMIC SCHEDULE (24H)';

  @override
  String get cfgIrrPeriod => 'Irrigation Period';

  @override
  String cfgPeriodRange(String start, String end) {
    return '${start}hrs to ${end}hrs';
  }

  @override
  String get cfgShiftBtn => 'Shift';

  @override
  String get cfgPredPeriod => 'Prediction Period';

  @override
  String get cloudTestingConnection => 'Testing connection to Cloud Server...';

  @override
  String get cloudStatusConnected => 'CONNECTED';

  @override
  String get cloudStatusUnreachable => 'UNREACHABLE';

  @override
  String get cloudStatusError => 'ERROR';

  @override
  String get cloudStatusConnectionUnknown => 'UNKNOWN';

  @override
  String get cloudStatusTesting => 'TESTING...';

  @override
  String get cloudApiOnline => 'Cloud API server is online and responding.';

  @override
  String get cloudApiNoResponse =>
      'Cloud API server returned no response or error.';

  @override
  String cloudApiTestFailed(String error) {
    return 'Cloud API test failed: $error';
  }

  @override
  String get cloudSyncInitiating => 'Initiating Cloud Synchronization...';

  @override
  String get cloudSyncFinished => 'Cloud sync finished.';

  @override
  String cloudSyncError(String error) {
    return 'Cloud sync error: $error';
  }

  @override
  String get cloudEmulationAbortedNoStation =>
      'Emulation Aborted: No registered station found on Cloud server.';

  @override
  String get cloudEmulationNoSelection =>
      'No station selected! Please select a cloud station first.';

  @override
  String cloudEmulationExecuting(String name, String id) {
    return 'Executing Local RF Recommendation in RAM for [$name] ($id)...';
  }

  @override
  String cloudEmulationFinished(String verdict) {
    return 'In-Memory Cloud Emulation Finished: $verdict';
  }

  @override
  String cloudEmulationError(String error) {
    return 'In-Memory Cloud Emulation Error: $error';
  }

  @override
  String get cloudApiStatusTitle => 'API CONNECTION STATUS';

  @override
  String get cloudBtnTestApi => 'Test API';

  @override
  String cloudBtnSync(int count) {
    return 'Sync ($count dirty)';
  }

  @override
  String cloudTargetEndpoint(String url) {
    return 'Target Endpoint : $url';
  }

  @override
  String cloudApiAuthLabel(String status) {
    return 'API Authorization: $status';
  }

  @override
  String get cloudApiAuthConfigured => 'Configured [OK]';

  @override
  String get cloudApiAuthMissing => 'Missing/Empty';

  @override
  String get cloudConnectionStateLabel => 'Connection State : ';

  @override
  String get cloudEmuYellowZoneTitle =>
      'IN-MEMORY CLOUD EMULATION (YELLOW ZONE)';

  @override
  String get cloudEmuNormalTitle => 'IN-MEMORY CLOUD EMULATION';

  @override
  String cloudEmuYellowZoneWarning(int endH, int startH) {
    return '[DATA GATHERING PHASE] System in Yellow Zone ($endH:00 - $startH:00). Emulated RAM prediction is for observation only.';
  }

  @override
  String cloudEmuMinHumidity(String humidity, String date) {
    return 'Minimum predicted humidity: $humidity%\nExpected at: $date';
  }

  @override
  String cloudEmuRadSum(String sum) {
    return '48h Radiation Sum: $sum J/m²';
  }

  @override
  String cloudEmuRefTimestamp(String date) {
    return 'Reference Timestamp: $date';
  }

  @override
  String cloudCoordsLatLon(String lat, String lon) {
    return 'Lat $lat, Lon $lon';
  }

  @override
  String get cloudCoordsNA => 'Lat N/A, Lon N/A';

  @override
  String cloudCoordinatesLabel(String coords) {
    return 'Coordinates: $coords';
  }

  @override
  String get cloudHeaderTitle => 'Cloud Services & Emulation';

  @override
  String get cloudRegisteredStationsTitle => 'Registered Cloud Stations:';

  @override
  String get cloudNoStationsFound =>
      'No registered stations found on Cloud Server.\nTest the connection or run a Sync.';

  @override
  String cloudSelectedStationMsg(String name) {
    return 'Selected Cloud Station: $name';
  }

  @override
  String get cloudBtnEmulateStation => 'Emulate Cloud Station';

  @override
  String get cloudValNA => 'N/A';

  @override
  String get cloudValUnknown => 'UNKNOWN';
}
