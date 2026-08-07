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
  String get verdictAvoidable => 'RIEGO EVITABLE: Humedad del suelo estable.';

  @override
  String get verdictNeeded =>
      'RIEGO NECESARIO: Humedad del suelo baja. REGAR para restaurar.';

  @override
  String get mainScreenError => 'Menú Desconocido';

  @override
  String get mainStatusReady => 'Listo';

  @override
  String get mainStatusBleConnected => 'Conectado a la estación Savia';

  @override
  String get mainStatusBleDisconnected => 'Desconectado de la estación Savia';

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
  String get homeConsoleCopiedSnack => '¡Copiado al portapapeles!';

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
      'No estás conectado a una estación.\nUsa el menú de \'Cercanos\' para conectarte a una estación válida.';

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
    return 'Diferencia $gap';
  }

  @override
  String get homeBtnReadStatus => 'Obtener Estado';

  @override
  String get homeBtnRequestData => 'Obtener Telemetría';

  @override
  String get homeBtnTriggerInference => 'Ejecutar Inferencia';

  @override
  String get homeConsoleTitle => 'Salida de Consola:';

  @override
  String get homeTooltipCopy => 'Copiar al Portapapeles';

  @override
  String get homeTooltipDownload => 'Descargar JSON';

  @override
  String get dbSyncingCloud => 'Sincronizando con la API en la Nube...';

  @override
  String dbSyncCompleted(int count) {
    return 'Sincronización en la nube completada. Cargados $count dispositivos de la BD local/nube.';
  }

  @override
  String dbSyncError(String error) {
    return 'Error de sincronización en la nube: Conexión no disponible o fallida ($error)';
  }

  @override
  String get dbNoSelection =>
      '¡Ningún dispositivo seleccionado! Seleccione un dispositivo primero.';

  @override
  String dbRunningInference(String name, String id) {
    return 'Ejecutando Inferencia de Random Forest para $name ($id)...';
  }

  @override
  String dbInferenceFinished(String verdict) {
    return 'Inferencia de RF Terminada: $verdict';
  }

  @override
  String dbInferenceFailed(String error) {
    return 'Inferencia Fallida: $error';
  }

  @override
  String get dbClearTitle => '¿Limpiar Base de Datos Local?';

  @override
  String get dbClearDesc =>
      'Esto eliminará permanentemente toda la telemetría guardada de la estación y los registros de predicción almacenados localmente.';

  @override
  String get dbBtnClearData => 'Limpiar Todos los Datos';

  @override
  String get dbClearSuccess => 'Registros de la BD Local limpiados con éxito.';

  @override
  String get dbRfNotCalculated => 'NO CALCULADO';

  @override
  String get dbRfYellowTitle => 'RECOMENDACIÓN RANDOM FOREST (ZONA AMARILLA)';

  @override
  String get dbRfTitle => 'RECOMENDACIÓN RANDOM FOREST';

  @override
  String dbRfYellowWarning(int endH, int startH) {
    return '[FASE DE RECOPILACIÓN DE DATOS] El sistema está en Zona Amarilla ($endH:00 - $startH:00). Las predicciones almacenadas son solo para observación.';
  }

  @override
  String dbRfMinHum(String humidity, String date) {
    return 'Humedad mínima predicha: $humidity%\nEsperada a las: $date';
  }

  @override
  String get dbRfNoPredictions =>
      'Aún no hay predicciones almacenadas para este dispositivo.';

  @override
  String get dbScreenTitle => 'Dispositivos en la Base de Datos Local';

  @override
  String get dbBtnSyncCloud => 'Sincronizar Nube';

  @override
  String get dbBtnClearDb => 'Limpiar BD';

  @override
  String get dbNoDevices =>
      'No se encontraron dispositivos guardados en la BD Local.\nEmpareje una estación BLE o ejecute la sincronización con la Nube para completarla.';

  @override
  String get dbStateSynced => 'SINCRONIZADO';

  @override
  String get dbStateUnsynced => 'NO SINCRONIZADO';

  @override
  String dbTelemetryInfo(int records, int predictions) {
    return 'Registros de Telemetría: $records  |  Predicciones: $predictions';
  }

  @override
  String dbLocationInfo(String lat, String lon) {
    return '  |  Lat: $lat, Lon: $lon';
  }

  @override
  String get dbBtnRunInference => 'Ejecutar Inferencia';

  @override
  String nbFoundDevices(int count) {
    return 'Encontrados $count dispositivos...';
  }

  @override
  String get nbRefreshingScan => 'Actualizando escaneo BLE...';

  @override
  String nbConnectDialogTitle(String name) {
    return 'Conectar a $name';
  }

  @override
  String nbDeviceId(String id) {
    return 'ID del Dispositivo: $id';
  }

  @override
  String nbSavedSecret(String secret) {
    return 'Secreto guardado: $secret';
  }

  @override
  String get nbTooltipShowSaved => 'Mostrar secreto guardado';

  @override
  String get nbTooltipHideSaved => 'Ocultar secreto guardado';

  @override
  String get nbLeaveBlankHint =>
      'Déjalo en blanco para usar el secreto guardado.';

  @override
  String get nbSecretLabel => 'Secreto de Autenticación';

  @override
  String get nbTooltipShowSecret => 'Mostrar secreto';

  @override
  String get nbTooltipHideSecret => 'Ocultar secreto';

  @override
  String get nbBtnConnect => 'Conectar';

  @override
  String nbConnectingStatus(String name) {
    return 'Conectando a $name...';
  }

  @override
  String nbConnectedSuccess(String name) {
    return '¡Conectado exitosamente a $name!';
  }

  @override
  String get nbConnectionFailed =>
      'Conexión fallida. Por favor compruebe el secreto o el rango del dispositivo.';

  @override
  String get nbDisconnectedStatus => 'Desconectado de la estación.';

  @override
  String get nbScreenTitle => 'Estaciones BLE Cercanas';

  @override
  String get nbBtnDisconnect => 'Desconectar';

  @override
  String get nbBtnScan => 'Escanear';

  @override
  String nbCurrentConnection(String name) {
    return 'Actualmente conectado a: $name';
  }

  @override
  String get nbNegotiatingStatus => 'Negociando autenticación...';

  @override
  String get nbNoDevices =>
      'No se encontraron dispositivos.\nAsegúrese de que su estación Pico esté encendida y emitiendo.';

  @override
  String nbDeviceSub(String id, int rssi) {
    return '$id     RSSI: $rssi dBm';
  }

  @override
  String get nbUnknownDev => 'Desconocido';

  @override
  String get nbUnnamedDev => 'Dispositivo sin nombre';

  @override
  String get cfgChecking => 'Comprobando...';

  @override
  String get cfgAcquiringGps => 'Adquiriendo ubicación GPS...';

  @override
  String cfgGpsUpdated(String lat, String lon) {
    return 'Ubicación actualizada automáticamente vía GPS: Lat $lat, Lon $lon';
  }

  @override
  String get cfgGpsFailed =>
      'Fallo al obtener la ubicación GPS. Compruebe los permisos/servicios de ubicación.';

  @override
  String cfgGpsError(String error) {
    return 'Error de Ubicación GPS: $error';
  }

  @override
  String get cfgMapTitle => 'Seleccionar Ubicación en el Mapa';

  @override
  String cfgMapHint(String lat, String lon) {
    return 'Toque en cualquier parte del mapa para poner un punto:\nLat: $lat, Lon: $lon';
  }

  @override
  String get cfgBtnConfirmLoc => 'Confirmar Ubicación';

  @override
  String cfgMapUpdated(String lat, String lon) {
    return 'Ubicación establecida manualmente: Lat $lat, Lon $lon';
  }

  @override
  String get cfgLocModeTitle => 'Configurar Modo de Ubicación';

  @override
  String get cfgLocModeAuto => 'Automático (GPS)';

  @override
  String get cfgLocModeAutoDesc =>
      'Adquiere la posición actual usando el hardware GPS del dispositivo';

  @override
  String get cfgLocModeManual => 'Manual (Mapa Interactivo)';

  @override
  String get cfgLocModeManualDesc =>
      'Toque en un mapa interactivo para elegir las coordenadas exactas del campo';

  @override
  String cfgPredStartUpdated(int start) {
    return 'Inicio de predicción actualizado a $start:00.';
  }

  @override
  String cfgPredLimit(int base) {
    return 'Límite alcanzado: El inicio de predicción solo se puede ajustar ±3h de la base ($base:00).';
  }

  @override
  String cfgIrrEndUpdated(int end) {
    return 'Fin de riego actualizado a $end:00.';
  }

  @override
  String cfgIrrLimit(int base) {
    return 'Límite alcanzado: El fin de riego solo se puede ajustar ±3h de la base ($base:00).';
  }

  @override
  String get cfgMeteoOk => 'OK (200)';

  @override
  String cfgMeteoError(int code) {
    return 'Error ($code)';
  }

  @override
  String get cfgMeteoOffline => 'Desconectado / Fallo';

  @override
  String get cfgPingTesting => 'Probando...';

  @override
  String cfgPingRes(String status, int ms) {
    return '$status ($ms ms)';
  }

  @override
  String get cfgPingFailed => 'Inalcanzable / Fallo';

  @override
  String get cfgSavedStatus =>
      '¡Configuración aplicada y guardada en base de datos & ApiClient en vivo!';

  @override
  String get cfgEndpointTitle => 'Editar Punto de Acceso en la Nube';

  @override
  String get cfgEndpointLabel => 'URL del Servidor';

  @override
  String cfgEndpointHint(String hint) {
    return 'ej. $hint';
  }

  @override
  String get cfgBtnUpdate => 'Actualizar';

  @override
  String get cfgEndpointUpdated =>
      'Endpoint en la nube actualizado. Recuerde pulsar Aplicar y Guardar.';

  @override
  String cfgLocString(String lat, String lon, String type) {
    return 'Lat: $lat, Lon: $lon ($type)';
  }

  @override
  String get cfgScreenTitle => 'Configuración del Sistema';

  @override
  String get cfgBtnApplySave => 'Aplicar y Guardar';

  @override
  String get cfgEnvSection => 'MEDIO AMBIENTE';

  @override
  String get cfgSysTimeLabel => 'Fecha y Hora del Sistema';

  @override
  String get cfgLocSettingsLabel => 'Configuración de Ubicación';

  @override
  String get cfgTooltipLoc => 'Configurar Modo de Ubicación';

  @override
  String get cfgNetSection => 'SERVICIOS DE RED';

  @override
  String get cfgMeteoLabel => 'Estado de la API Open-Meteo';

  @override
  String get cfgCloudLabel => 'Endpoint del Servidor en la Nube';

  @override
  String get cfgTooltipEditEnd => 'Editar Endpoint';

  @override
  String get cfgAgroSection => 'HORARIO AGRONÓMICO (24H)';

  @override
  String get cfgIrrPeriod => 'Período de Riego';

  @override
  String cfgPeriodRange(String start, String end) {
    return 'De ${start}hrs a ${end}hrs';
  }

  @override
  String get cfgShiftBtn => 'Desplazar';

  @override
  String get cfgPredPeriod => 'Período de Predicción';

  @override
  String get cloudTestingConnection =>
      'Probando conexión con el Servidor en la Nube...';

  @override
  String get cloudStatusConnected => 'CONECTADO';

  @override
  String get cloudStatusUnreachable => 'INALCANZABLE';

  @override
  String get cloudStatusError => 'ERROR';

  @override
  String get cloudStatusConnectionUnknown => 'DESCONOCIDO';

  @override
  String get cloudStatusTesting => 'PROBANDO...';

  @override
  String get cloudApiOnline =>
      'El servidor de la API en la nube está en línea y respondiendo.';

  @override
  String get cloudApiNoResponse =>
      'El servidor de la API en la nube no dio respuesta o dio error.';

  @override
  String cloudApiTestFailed(String error) {
    return 'La prueba de la API en la nube falló: $error';
  }

  @override
  String get cloudSyncInitiating => 'Sincronizando con la API en la Nube...';

  @override
  String get cloudSyncFinished => 'Sincronización en la nube completada.';

  @override
  String cloudSyncError(String error) {
    return 'Error de sincronización en la nube: Conexión no disponible o fallida ($error)';
  }

  @override
  String get cloudEmulationAbortedNoStation =>
      'Emulación Abortada: No se encontró estación registrada en el servidor de la Nube.';

  @override
  String get cloudEmulationNoSelection =>
      '¡Ninguna estación seleccionada! Por favor seleccione primero una estación de la nube.';

  @override
  String cloudEmulationExecuting(String name, String id) {
    return 'Ejecutando Inferencia de Random Forest para $name ($id)...';
  }

  @override
  String cloudEmulationFinished(String verdict) {
    return 'Inferencia de RF Terminada: $verdict';
  }

  @override
  String cloudEmulationError(String error) {
    return 'Inferencia Fallida: $error';
  }

  @override
  String get cloudApiStatusTitle => 'ESTADO DE CONEXIÓN API';

  @override
  String get cloudBtnTestApi => 'Probar API';

  @override
  String cloudBtnSync(int count) {
    return 'Sincronizar ($count restantes)';
  }

  @override
  String cloudTargetEndpoint(String url) {
    return 'Endpoint de Destino : $url';
  }

  @override
  String cloudApiAuthLabel(String status) {
    return 'Autorización API: $status';
  }

  @override
  String get cloudApiAuthConfigured => 'Configurado [OK]';

  @override
  String get cloudApiAuthMissing => 'Faltante/Vacío';

  @override
  String get cloudConnectionStateLabel => 'Estado de Conexión : ';

  @override
  String get cloudEmuYellowZoneTitle =>
      'EMULACIÓN DE NUBE EN MEMORIA (ZONA AMARILLA)';

  @override
  String get cloudEmuNormalTitle => 'EMULACIÓN DE NUBE EN MEMORIA';

  @override
  String cloudEmuYellowZoneWarning(int endH, int startH) {
    return '[FASE DE RECOPILACIÓN DE DATOS] Sistema en Zona Amarilla ($endH:00 - $startH:00). La predicción emulada en RAM es solo para observación.';
  }

  @override
  String cloudEmuMinHumidity(String humidity, String date) {
    return 'Humedad mínima predicha: $humidity%\nEsperada a las: $date';
  }

  @override
  String cloudEmuRadSum(String sum) {
    return 'Suma de Radiación 48h: $sum J/m²';
  }

  @override
  String cloudEmuRefTimestamp(String date) {
    return 'Marca de Tiempo de Referencia: $date';
  }

  @override
  String cloudCoordsLatLon(String lat, String lon) {
    return 'Lat $lat, Lon $lon';
  }

  @override
  String get cloudCoordsNA => 'Lat N/A, Lon N/A';

  @override
  String cloudCoordinatesLabel(String coords) {
    return 'Coordenadas: $coords';
  }

  @override
  String get cloudHeaderTitle => 'Dispositivos en la Nube';

  @override
  String get cloudRegisteredStationsTitle =>
      'Estaciones en la Nube Registradas:';

  @override
  String get cloudNoStationsFound =>
      'No se encontraron estaciones registradas en el Servidor de la Nube.\nPruebe la conexión o ejecute una Sincronización.';

  @override
  String cloudSelectedStationMsg(String name) {
    return 'Estación en la Nube Seleccionada: $name';
  }

  @override
  String get cloudBtnEmulateStation => 'Ejecutar Inferencia';

  @override
  String get cloudValNA => 'N/D';

  @override
  String get cloudEmuNoData => 'No se ha ejecutado emulación aún.';

  @override
  String get cloudValUnknown => 'DESCONOCIDO';

  @override
  String get nbWarningBtOff => 'Bluetooth Desactivado';

  @override
  String get nbWarningBtOffDesc =>
      'El Bluetooth debe estar activado para escanear y conectar con el hardware Savia.';

  @override
  String get nbBtnTurnOnBt => 'Activar Bluetooth';

  @override
  String get nbWarningLocOff => 'Ubicación Desactivada';

  @override
  String get nbWarningLocOffDesc =>
      'Los servicios de ubicación deben estar activados para escanear dispositivos BLE en este sistema operativo.';

  @override
  String get nbBtnTurnOnLoc => 'Activar Ubicación';

  @override
  String get nbWarningPerms => 'Permisos Requeridos';

  @override
  String get nbWarningPermsDesc =>
      'Por favor, concede los permisos de Bluetooth y Ubicación necesarios para comunicarse con el hardware.';

  @override
  String get nbBtnGrantPerms => 'Conceder Permisos';

  @override
  String get inferenceRestrictedTitle =>
      'INFERENCIA RESTRINGIDA (ZONA AMARILLA)';

  @override
  String inferenceRestrictedDesc(int startI, int endI, int startH, int endH) {
    return 'Inferencia restringida: los datos de la estación están en fase de recolección ($startI:00 - $endI:00). Las recomendaciones IA solo se ejecutan en la ventana óptima ($startH:00 - $endH:00).';
  }

  @override
  String get inferenceUnrecommendedTitle =>
      'RESULTADO NO RECOMENDADO (FUERA DE VENTANA DE PREDICCIÓN)';

  @override
  String inferenceUnrecommendedWarning(int startH, int endH) {
    return 'Advertencia | Datos fuera de la ventana de predicción óptima: $startH:00 - $endH:00. El resultado es solo a título informativo/depuración.';
  }

  @override
  String get inferenceRecommendedTitle => 'RESULTADO IA RECOMENDADO';

  @override
  String inferenceInfoSource(String source) {
    return 'Origen: $source';
  }
}
