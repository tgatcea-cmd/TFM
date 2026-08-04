import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Terralink Dashboard'**
  String get appTitle;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'STATUS: {msg}'**
  String statusLabel(String msg);

  /// No description provided for @verdictLstmIrrigate.
  ///
  /// In en, this message translates to:
  /// **'IRRIGATE: Soil moisture threshold drop predicted'**
  String get verdictLstmIrrigate;

  /// No description provided for @verdictLstmHealthy.
  ///
  /// In en, this message translates to:
  /// **'HEALTHY: Soil moisture level sufficient'**
  String get verdictLstmHealthy;

  /// No description provided for @verdictRfSaturation.
  ///
  /// In en, this message translates to:
  /// **'SATURATION RISK: Irrigation perjudicial tomorrow. DO NOT IRRIGATE.'**
  String get verdictRfSaturation;

  /// No description provided for @verdictRfHealthy.
  ///
  /// In en, this message translates to:
  /// **'HEALTHY: Irrigation safe / Not perjudicial.'**
  String get verdictRfHealthy;

  /// No description provided for @verdictEmuPerjudicial.
  ///
  /// In en, this message translates to:
  /// **'Perjudicial'**
  String get verdictEmuPerjudicial;

  /// No description provided for @verdictEmuHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get verdictEmuHealthy;

  /// No description provided for @mainScreenError.
  ///
  /// In en, this message translates to:
  /// **'Unknown Screen'**
  String get mainScreenError;

  /// No description provided for @mainStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get mainStatusReady;

  /// No description provided for @mainStatusBleConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to Savia station'**
  String get mainStatusBleConnected;

  /// No description provided for @mainStatusBleDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from Savia station'**
  String get mainStatusBleDisconnected;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @nearbyTab.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyTab;

  /// No description provided for @localDbTab.
  ///
  /// In en, this message translates to:
  /// **'Local DB'**
  String get localDbTab;

  /// No description provided for @cloudTab.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloudTab;

  /// No description provided for @configTab.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get configTab;

  /// No description provided for @homeConsoleInit.
  ///
  /// In en, this message translates to:
  /// **'Console initialized. Awaiting commands...'**
  String get homeConsoleInit;

  /// No description provided for @homeConsoleCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Console output copied to clipboard!'**
  String get homeConsoleCopiedSnack;

  /// No description provided for @homeConsoleCopiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Console output copied to clipboard.'**
  String get homeConsoleCopiedStatus;

  /// No description provided for @homeExportJsonSnack.
  ///
  /// In en, this message translates to:
  /// **'Exported JSON: {fileName}'**
  String homeExportJsonSnack(String fileName);

  /// No description provided for @homeExportJsonStatus.
  ///
  /// In en, this message translates to:
  /// **'Console output saved to JSON: {path}'**
  String homeExportJsonStatus(String path);

  /// No description provided for @homeExportJsonFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export JSON: {error}'**
  String homeExportJsonFailed(String error);

  /// No description provided for @homeBleAsyncData.
  ///
  /// In en, this message translates to:
  /// **'Received Async BLE Data:\n{data}'**
  String homeBleAsyncData(String data);

  /// No description provided for @homeGapYears.
  ///
  /// In en, this message translates to:
  /// **'{years} year(s)'**
  String homeGapYears(String years);

  /// No description provided for @homeGapDays.
  ///
  /// In en, this message translates to:
  /// **'{days} day(s)'**
  String homeGapDays(String days);

  /// No description provided for @homeGapHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hour(s)'**
  String homeGapHours(String hours);

  /// No description provided for @homeGapMins.
  ///
  /// In en, this message translates to:
  /// **'{mins} min(s)'**
  String homeGapMins(String mins);

  /// No description provided for @homeGapSecs.
  ///
  /// In en, this message translates to:
  /// **'{secs} sec'**
  String homeGapSecs(String secs);

  /// No description provided for @homeExecutingSync.
  ///
  /// In en, this message translates to:
  /// **'Executing Sync Time...'**
  String get homeExecutingSync;

  /// No description provided for @homeSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Time Synced. New internal clock: {date}'**
  String homeSyncSuccess(String date);

  /// No description provided for @homeSyncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync Time Completed.'**
  String get homeSyncCompleted;

  /// No description provided for @homeSyncErrorConsole.
  ///
  /// In en, this message translates to:
  /// **'Error during Sync Time:\n{error}'**
  String homeSyncErrorConsole(String error);

  /// No description provided for @homeSyncFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Time Failed.'**
  String get homeSyncFailedStatus;

  /// No description provided for @homeVoidOutput.
  ///
  /// In en, this message translates to:
  /// **'Success (Void/No Output)'**
  String get homeVoidOutput;

  /// No description provided for @homeExecutingAction.
  ///
  /// In en, this message translates to:
  /// **'Executing {name}...'**
  String homeExecutingAction(String name);

  /// No description provided for @homeActionRes.
  ///
  /// In en, this message translates to:
  /// **'Result for {name}:\n{res}'**
  String homeActionRes(String name, String res);

  /// No description provided for @homeActionCompleted.
  ///
  /// In en, this message translates to:
  /// **'{name} Completed.'**
  String homeActionCompleted(String name);

  /// No description provided for @homeActionError.
  ///
  /// In en, this message translates to:
  /// **'Error during {name}:\n{error}'**
  String homeActionError(String name, String error);

  /// No description provided for @homeActionFailed.
  ///
  /// In en, this message translates to:
  /// **'{name} Failed.'**
  String homeActionFailed(String name);

  /// No description provided for @homeDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE: DEBUG ONLY (REMOVE BEFORE PROD)'**
  String get homeDebugTitle;

  /// No description provided for @homeBtnMock.
  ///
  /// In en, this message translates to:
  /// **'Force Mock 72h'**
  String get homeBtnMock;

  /// No description provided for @homeBtnClearStorage.
  ///
  /// In en, this message translates to:
  /// **'Clear Station Storage'**
  String get homeBtnClearStorage;

  /// No description provided for @homeAiTitleYellow.
  ///
  /// In en, this message translates to:
  /// **'AI RECOMMENDATION (YELLOW ZONE)'**
  String get homeAiTitleYellow;

  /// No description provided for @homeAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI RECOMMENDATION'**
  String get homeAiTitle;

  /// No description provided for @homeAiYellowWarning.
  ///
  /// In en, this message translates to:
  /// **'[DATA GATHERING PHASE] System gathering telemetry ({endH}:00 - {startH}:00). Prediction is not in optimal 19:00+ window.'**
  String homeAiYellowWarning(int endH, int startH);

  /// No description provided for @homeAiMinHum.
  ///
  /// In en, this message translates to:
  /// **'Minimum predicted humidity: {humidity}%\nExpected at: {date}'**
  String homeAiMinHum(String humidity, String date);

  /// No description provided for @homeAiNoData.
  ///
  /// In en, this message translates to:
  /// **'No valid prediction time-series found in database.'**
  String get homeAiNoData;

  /// No description provided for @homeNoBleConnected.
  ///
  /// In en, this message translates to:
  /// **'No BLE station connected.\nUse the \'Nearby\' tab to pair a Pico device.'**
  String get homeNoBleConnected;

  /// No description provided for @homeConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected: {devName}'**
  String homeConnectedTitle(String devName);

  /// No description provided for @homeClockUnknown.
  ///
  /// In en, this message translates to:
  /// **'Clock status unknown'**
  String get homeClockUnknown;

  /// No description provided for @homeTooltipSync.
  ///
  /// In en, this message translates to:
  /// **'Sync Time'**
  String get homeTooltipSync;

  /// No description provided for @homeGapLabel.
  ///
  /// In en, this message translates to:
  /// **'{gap} gap'**
  String homeGapLabel(String gap);

  /// No description provided for @homeBtnReadStatus.
  ///
  /// In en, this message translates to:
  /// **'Read Status'**
  String get homeBtnReadStatus;

  /// No description provided for @homeBtnRequestData.
  ///
  /// In en, this message translates to:
  /// **'Request Data'**
  String get homeBtnRequestData;

  /// No description provided for @homeBtnTriggerInference.
  ///
  /// In en, this message translates to:
  /// **'Trigger Inference'**
  String get homeBtnTriggerInference;

  /// No description provided for @homeConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Console Output:'**
  String get homeConsoleTitle;

  /// No description provided for @homeTooltipCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get homeTooltipCopy;

  /// No description provided for @homeTooltipDownload.
  ///
  /// In en, this message translates to:
  /// **'Download JSON'**
  String get homeTooltipDownload;

  /// No description provided for @dbSyncingCloud.
  ///
  /// In en, this message translates to:
  /// **'Syncing with Cloud API...'**
  String get dbSyncingCloud;

  /// No description provided for @dbSyncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync completed. Loaded {count} devices from cloud/local DB.'**
  String dbSyncCompleted(int count);

  /// No description provided for @dbSyncError.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync Error: Connection unavailable or failed ({error})'**
  String dbSyncError(String error);

  /// No description provided for @dbNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No device selected! Select a device first.'**
  String get dbNoSelection;

  /// No description provided for @dbRunningInference.
  ///
  /// In en, this message translates to:
  /// **'Running Random Forest Inference for {name} ({id})...'**
  String dbRunningInference(String name, String id);

  /// No description provided for @dbInferenceFinished.
  ///
  /// In en, this message translates to:
  /// **'RF Inference Finished: {verdict}'**
  String dbInferenceFinished(String verdict);

  /// No description provided for @dbInferenceFailed.
  ///
  /// In en, this message translates to:
  /// **'Inference Failed: {error}'**
  String dbInferenceFailed(String error);

  /// No description provided for @dbClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Local Database?'**
  String get dbClearTitle;

  /// No description provided for @dbClearDesc.
  ///
  /// In en, this message translates to:
  /// **'This will delete all saved station telemetry and prediction records stored locally.'**
  String get dbClearDesc;

  /// No description provided for @dbBtnClearData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get dbBtnClearData;

  /// No description provided for @dbClearSuccess.
  ///
  /// In en, this message translates to:
  /// **'Local DB records cleared successfully.'**
  String get dbClearSuccess;

  /// No description provided for @dbRfNotCalculated.
  ///
  /// In en, this message translates to:
  /// **'NOT CALCULATED'**
  String get dbRfNotCalculated;

  /// No description provided for @dbRfYellowTitle.
  ///
  /// In en, this message translates to:
  /// **'RANDOM FOREST RECOMMENDATION (YELLOW ZONE)'**
  String get dbRfYellowTitle;

  /// No description provided for @dbRfTitle.
  ///
  /// In en, this message translates to:
  /// **'RANDOM FOREST RECOMMENDATION'**
  String get dbRfTitle;

  /// No description provided for @dbRfYellowWarning.
  ///
  /// In en, this message translates to:
  /// **'[DATA GATHERING PHASE] System is in Yellow Zone ({endH}:00 - {startH}:00). Stored predictions are for observation only.'**
  String dbRfYellowWarning(int endH, int startH);

  /// No description provided for @dbRfMinHum.
  ///
  /// In en, this message translates to:
  /// **'Minimum predicted humidity: {humidity}%\nExpected at: {date}'**
  String dbRfMinHum(String humidity, String date);

  /// No description provided for @dbRfNoPredictions.
  ///
  /// In en, this message translates to:
  /// **'No predictions stored for this device yet.'**
  String get dbRfNoPredictions;

  /// No description provided for @dbScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Local DB Devices'**
  String get dbScreenTitle;

  /// No description provided for @dbBtnSyncCloud.
  ///
  /// In en, this message translates to:
  /// **'Sync Cloud'**
  String get dbBtnSyncCloud;

  /// No description provided for @dbBtnClearDb.
  ///
  /// In en, this message translates to:
  /// **'Clear DB'**
  String get dbBtnClearDb;

  /// No description provided for @dbNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No saved devices found in Local DB.\nPair a BLE station or run sync with Cloud to populate.'**
  String get dbNoDevices;

  /// No description provided for @dbStateSynced.
  ///
  /// In en, this message translates to:
  /// **'SYNCED'**
  String get dbStateSynced;

  /// No description provided for @dbStateUnsynced.
  ///
  /// In en, this message translates to:
  /// **'UNSYNCED'**
  String get dbStateUnsynced;

  /// No description provided for @dbTelemetryInfo.
  ///
  /// In en, this message translates to:
  /// **'Telemetry Records: {records}  |  Predictions: {predictions}'**
  String dbTelemetryInfo(int records, int predictions);

  /// No description provided for @dbLocationInfo.
  ///
  /// In en, this message translates to:
  /// **'  |  Lat: {lat}, Lon: {lon}'**
  String dbLocationInfo(String lat, String lon);

  /// No description provided for @dbBtnRunInference.
  ///
  /// In en, this message translates to:
  /// **'Run RF Inference'**
  String get dbBtnRunInference;

  /// No description provided for @nbFoundDevices.
  ///
  /// In en, this message translates to:
  /// **'Found {count} devices...'**
  String nbFoundDevices(int count);

  /// No description provided for @nbRefreshingScan.
  ///
  /// In en, this message translates to:
  /// **'Refreshing BLE scan...'**
  String get nbRefreshingScan;

  /// No description provided for @nbConnectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to {name}'**
  String nbConnectDialogTitle(String name);

  /// No description provided for @nbDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID: {id}'**
  String nbDeviceId(String id);

  /// No description provided for @nbSavedSecret.
  ///
  /// In en, this message translates to:
  /// **'Saved secret: {secret}'**
  String nbSavedSecret(String secret);

  /// No description provided for @nbTooltipShowSaved.
  ///
  /// In en, this message translates to:
  /// **'Show saved secret'**
  String get nbTooltipShowSaved;

  /// No description provided for @nbTooltipHideSaved.
  ///
  /// In en, this message translates to:
  /// **'Hide saved secret'**
  String get nbTooltipHideSaved;

  /// No description provided for @nbLeaveBlankHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use the saved secret.'**
  String get nbLeaveBlankHint;

  /// No description provided for @nbSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Handshake Secret'**
  String get nbSecretLabel;

  /// No description provided for @nbTooltipShowSecret.
  ///
  /// In en, this message translates to:
  /// **'Show secret'**
  String get nbTooltipShowSecret;

  /// No description provided for @nbTooltipHideSecret.
  ///
  /// In en, this message translates to:
  /// **'Hide secret'**
  String get nbTooltipHideSecret;

  /// No description provided for @nbBtnConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get nbBtnConnect;

  /// No description provided for @nbConnectingStatus.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {name}...'**
  String nbConnectingStatus(String name);

  /// No description provided for @nbConnectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully to {name}!'**
  String nbConnectedSuccess(String name);

  /// No description provided for @nbConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please check the secret or device range.'**
  String get nbConnectionFailed;

  /// No description provided for @nbDisconnectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from station.'**
  String get nbDisconnectedStatus;

  /// No description provided for @nbScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby BLE Stations'**
  String get nbScreenTitle;

  /// No description provided for @nbBtnDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get nbBtnDisconnect;

  /// No description provided for @nbBtnScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get nbBtnScan;

  /// No description provided for @nbCurrentConnection.
  ///
  /// In en, this message translates to:
  /// **'Currently connected to: {name}'**
  String nbCurrentConnection(String name);

  /// No description provided for @nbNegotiatingStatus.
  ///
  /// In en, this message translates to:
  /// **'Negotiating handshake...'**
  String get nbNegotiatingStatus;

  /// No description provided for @nbNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices found.\nEnsure your Pico station is powered and advertising.'**
  String get nbNoDevices;

  /// No description provided for @nbDeviceSub.
  ///
  /// In en, this message translates to:
  /// **'{id}  •  RSSI: {rssi} dBm'**
  String nbDeviceSub(String id, int rssi);

  /// No description provided for @nbUnknownDev.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get nbUnknownDev;

  /// No description provided for @nbUnnamedDev.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Device'**
  String get nbUnnamedDev;

  /// No description provided for @cfgChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get cfgChecking;

  /// No description provided for @cfgAcquiringGps.
  ///
  /// In en, this message translates to:
  /// **'Acquiring GPS location...'**
  String get cfgAcquiringGps;

  /// No description provided for @cfgGpsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated automatically via GPS: Lat {lat}, Lon {lon}'**
  String cfgGpsUpdated(String lat, String lon);

  /// No description provided for @cfgGpsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get GPS location. Check location permissions/services.'**
  String get cfgGpsFailed;

  /// No description provided for @cfgGpsError.
  ///
  /// In en, this message translates to:
  /// **'GPS Location Error: {error}'**
  String cfgGpsError(String error);

  /// No description provided for @cfgMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Location on Map'**
  String get cfgMapTitle;

  /// No description provided for @cfgMapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere on the map to place point:\nLat: {lat}, Lon: {lon}'**
  String cfgMapHint(String lat, String lon);

  /// No description provided for @cfgBtnConfirmLoc.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get cfgBtnConfirmLoc;

  /// No description provided for @cfgMapUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location manually set: Lat {lat}, Lon {lon}'**
  String cfgMapUpdated(String lat, String lon);

  /// No description provided for @cfgLocModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure Location Mode'**
  String get cfgLocModeTitle;

  /// No description provided for @cfgLocModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic (GPS)'**
  String get cfgLocModeAuto;

  /// No description provided for @cfgLocModeAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Acquire current position using device GPS hardware'**
  String get cfgLocModeAutoDesc;

  /// No description provided for @cfgLocModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual (Interactive Map)'**
  String get cfgLocModeManual;

  /// No description provided for @cfgLocModeManualDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap on an interactive map to pick exact field coordinates'**
  String get cfgLocModeManualDesc;

  /// No description provided for @cfgPredStartUpdated.
  ///
  /// In en, this message translates to:
  /// **'Prediction start updated to {start}:00.'**
  String cfgPredStartUpdated(int start);

  /// No description provided for @cfgPredLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit reached: Prediction start can only be adjusted ±3h from base ({base}:00).'**
  String cfgPredLimit(int base);

  /// No description provided for @cfgIrrEndUpdated.
  ///
  /// In en, this message translates to:
  /// **'Irrigation end updated to {end}:00.'**
  String cfgIrrEndUpdated(int end);

  /// No description provided for @cfgIrrLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit reached: Irrigation end can only be adjusted ±3h from base ({base}:00).'**
  String cfgIrrLimit(int base);

  /// No description provided for @cfgMeteoOk.
  ///
  /// In en, this message translates to:
  /// **'OK (200)'**
  String get cfgMeteoOk;

  /// No description provided for @cfgMeteoError.
  ///
  /// In en, this message translates to:
  /// **'Error ({code})'**
  String cfgMeteoError(int code);

  /// No description provided for @cfgMeteoOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline / Failed'**
  String get cfgMeteoOffline;

  /// No description provided for @cfgPingTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get cfgPingTesting;

  /// No description provided for @cfgPingRes.
  ///
  /// In en, this message translates to:
  /// **'{status} ({ms} ms)'**
  String cfgPingRes(String status, int ms);

  /// No description provided for @cfgPingFailed.
  ///
  /// In en, this message translates to:
  /// **'Unreachable / Failed'**
  String get cfgPingFailed;

  /// No description provided for @cfgSavedStatus.
  ///
  /// In en, this message translates to:
  /// **'Configuration applied and saved to database & live ApiClient!'**
  String get cfgSavedStatus;

  /// No description provided for @cfgEndpointTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Cloud Endpoint'**
  String get cfgEndpointTitle;

  /// No description provided for @cfgEndpointLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get cfgEndpointLabel;

  /// No description provided for @cfgEndpointHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. {hint}'**
  String cfgEndpointHint(String hint);

  /// No description provided for @cfgBtnUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get cfgBtnUpdate;

  /// No description provided for @cfgEndpointUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cloud endpoint updated. Remember to press Apply & Save.'**
  String get cfgEndpointUpdated;

  /// No description provided for @cfgLocString.
  ///
  /// In en, this message translates to:
  /// **'Lat: {lat}, Lon: {lon} ({type})'**
  String cfgLocString(String lat, String lon, String type);

  /// No description provided for @cfgScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'System Configuration'**
  String get cfgScreenTitle;

  /// No description provided for @cfgBtnApplySave.
  ///
  /// In en, this message translates to:
  /// **'Apply & Save'**
  String get cfgBtnApplySave;

  /// No description provided for @cfgEnvSection.
  ///
  /// In en, this message translates to:
  /// **'ENVIRONMENT'**
  String get cfgEnvSection;

  /// No description provided for @cfgSysTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'System Date & Time'**
  String get cfgSysTimeLabel;

  /// No description provided for @cfgLocSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Location Settings'**
  String get cfgLocSettingsLabel;

  /// No description provided for @cfgTooltipLoc.
  ///
  /// In en, this message translates to:
  /// **'Configure Location Mode'**
  String get cfgTooltipLoc;

  /// No description provided for @cfgNetSection.
  ///
  /// In en, this message translates to:
  /// **'NETWORK SERVICES'**
  String get cfgNetSection;

  /// No description provided for @cfgMeteoLabel.
  ///
  /// In en, this message translates to:
  /// **'Open-Meteo API Status'**
  String get cfgMeteoLabel;

  /// No description provided for @cfgCloudLabel.
  ///
  /// In en, this message translates to:
  /// **'Cloud Server Endpoint'**
  String get cfgCloudLabel;

  /// No description provided for @cfgTooltipEditEnd.
  ///
  /// In en, this message translates to:
  /// **'Edit Endpoint'**
  String get cfgTooltipEditEnd;

  /// No description provided for @cfgAgroSection.
  ///
  /// In en, this message translates to:
  /// **'AGRONOMIC SCHEDULE (24H)'**
  String get cfgAgroSection;

  /// No description provided for @cfgIrrPeriod.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Period'**
  String get cfgIrrPeriod;

  /// No description provided for @cfgPeriodRange.
  ///
  /// In en, this message translates to:
  /// **'{start}hrs to {end}hrs'**
  String cfgPeriodRange(String start, String end);

  /// No description provided for @cfgShiftBtn.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get cfgShiftBtn;

  /// No description provided for @cfgPredPeriod.
  ///
  /// In en, this message translates to:
  /// **'Prediction Period'**
  String get cfgPredPeriod;

  /// No description provided for @cloudTestingConnection.
  ///
  /// In en, this message translates to:
  /// **'Testing connection to Cloud Server...'**
  String get cloudTestingConnection;

  /// No description provided for @cloudStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get cloudStatusConnected;

  /// No description provided for @cloudStatusUnreachable.
  ///
  /// In en, this message translates to:
  /// **'UNREACHABLE'**
  String get cloudStatusUnreachable;

  /// No description provided for @cloudStatusError.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get cloudStatusError;

  /// No description provided for @cloudStatusConnectionUnknown.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN'**
  String get cloudStatusConnectionUnknown;

  /// No description provided for @cloudStatusTesting.
  ///
  /// In en, this message translates to:
  /// **'TESTING...'**
  String get cloudStatusTesting;

  /// No description provided for @cloudApiOnline.
  ///
  /// In en, this message translates to:
  /// **'Cloud API server is online and responding.'**
  String get cloudApiOnline;

  /// No description provided for @cloudApiNoResponse.
  ///
  /// In en, this message translates to:
  /// **'Cloud API server returned no response or error.'**
  String get cloudApiNoResponse;

  /// No description provided for @cloudApiTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud API test failed: {error}'**
  String cloudApiTestFailed(String error);

  /// No description provided for @cloudSyncInitiating.
  ///
  /// In en, this message translates to:
  /// **'Initiating Cloud Synchronization...'**
  String get cloudSyncInitiating;

  /// No description provided for @cloudSyncFinished.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync finished.'**
  String get cloudSyncFinished;

  /// No description provided for @cloudSyncError.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync error: {error}'**
  String cloudSyncError(String error);

  /// No description provided for @cloudEmulationAbortedNoStation.
  ///
  /// In en, this message translates to:
  /// **'Emulation Aborted: No registered station found on Cloud server.'**
  String get cloudEmulationAbortedNoStation;

  /// No description provided for @cloudEmulationNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No station selected! Please select a cloud station first.'**
  String get cloudEmulationNoSelection;

  /// No description provided for @cloudEmulationExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing Local RF Recommendation in RAM for [{name}] ({id})...'**
  String cloudEmulationExecuting(String name, String id);

  /// No description provided for @cloudEmulationFinished.
  ///
  /// In en, this message translates to:
  /// **'In-Memory Cloud Emulation Finished: {verdict}'**
  String cloudEmulationFinished(String verdict);

  /// No description provided for @cloudEmulationError.
  ///
  /// In en, this message translates to:
  /// **'In-Memory Cloud Emulation Error: {error}'**
  String cloudEmulationError(String error);

  /// No description provided for @cloudApiStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'API CONNECTION STATUS'**
  String get cloudApiStatusTitle;

  /// No description provided for @cloudBtnTestApi.
  ///
  /// In en, this message translates to:
  /// **'Test API'**
  String get cloudBtnTestApi;

  /// No description provided for @cloudBtnSync.
  ///
  /// In en, this message translates to:
  /// **'Sync ({count} dirty)'**
  String cloudBtnSync(int count);

  /// No description provided for @cloudTargetEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Target Endpoint : {url}'**
  String cloudTargetEndpoint(String url);

  /// No description provided for @cloudApiAuthLabel.
  ///
  /// In en, this message translates to:
  /// **'API Authorization: {status}'**
  String cloudApiAuthLabel(String status);

  /// No description provided for @cloudApiAuthConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured [OK]'**
  String get cloudApiAuthConfigured;

  /// No description provided for @cloudApiAuthMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing/Empty'**
  String get cloudApiAuthMissing;

  /// No description provided for @cloudConnectionStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection State : '**
  String get cloudConnectionStateLabel;

  /// No description provided for @cloudEmuYellowZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'IN-MEMORY CLOUD EMULATION (YELLOW ZONE)'**
  String get cloudEmuYellowZoneTitle;

  /// No description provided for @cloudEmuNormalTitle.
  ///
  /// In en, this message translates to:
  /// **'IN-MEMORY CLOUD EMULATION'**
  String get cloudEmuNormalTitle;

  /// No description provided for @cloudEmuYellowZoneWarning.
  ///
  /// In en, this message translates to:
  /// **'[DATA GATHERING PHASE] System in Yellow Zone ({endH}:00 - {startH}:00). Emulated RAM prediction is for observation only.'**
  String cloudEmuYellowZoneWarning(int endH, int startH);

  /// No description provided for @cloudEmuMinHumidity.
  ///
  /// In en, this message translates to:
  /// **'Minimum predicted humidity: {humidity}%\nExpected at: {date}'**
  String cloudEmuMinHumidity(String humidity, String date);

  /// No description provided for @cloudEmuRadSum.
  ///
  /// In en, this message translates to:
  /// **'48h Radiation Sum: {sum} J/m²'**
  String cloudEmuRadSum(String sum);

  /// No description provided for @cloudEmuRefTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Reference Timestamp: {date}'**
  String cloudEmuRefTimestamp(String date);

  /// No description provided for @cloudCoordsLatLon.
  ///
  /// In en, this message translates to:
  /// **'Lat {lat}, Lon {lon}'**
  String cloudCoordsLatLon(String lat, String lon);

  /// No description provided for @cloudCoordsNA.
  ///
  /// In en, this message translates to:
  /// **'Lat N/A, Lon N/A'**
  String get cloudCoordsNA;

  /// No description provided for @cloudCoordinatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: {coords}'**
  String cloudCoordinatesLabel(String coords);

  /// No description provided for @cloudHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Services & Emulation'**
  String get cloudHeaderTitle;

  /// No description provided for @cloudRegisteredStationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered Cloud Stations:'**
  String get cloudRegisteredStationsTitle;

  /// No description provided for @cloudNoStationsFound.
  ///
  /// In en, this message translates to:
  /// **'No registered stations found on Cloud Server.\nTest the connection or run a Sync.'**
  String get cloudNoStationsFound;

  /// No description provided for @cloudSelectedStationMsg.
  ///
  /// In en, this message translates to:
  /// **'Selected Cloud Station: {name}'**
  String cloudSelectedStationMsg(String name);

  /// No description provided for @cloudBtnEmulateStation.
  ///
  /// In en, this message translates to:
  /// **'Emulate Cloud Station'**
  String get cloudBtnEmulateStation;

  /// No description provided for @cloudValNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get cloudValNA;

  /// No description provided for @cloudValUnknown.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN'**
  String get cloudValUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
