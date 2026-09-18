# C4 Code Architecture: Core Localization (`lib/core/utils/l10n`)

## 1. Overview Section

- **Name**: Core Localization & Internationalization Subsystem (`l10n`)
- **Description**: Centralized internationalization (i18n) and localization (l10n) module providing bilingual English (`en`) and Spanish Castilian (`es`) string catalogs, dynamic parameter interpolation, and Flutter localization delegates.
- **Location**: [`lib/core/utils/l10n`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n)
- **Language**: Dart (SDK ^3.11.5) with Application Resource Bundle (ARB / JSON) message templates.
- **Purpose**: Provides strongly-typed, compile-time checked access to all UI strings, system notices, agronomic recommendations, BLE status messages, and configuration directives used across the Savia / Terralink mobile and desktop dashboard. The module follows Flutter's standard localization architecture driven by [`l10n.yaml`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/l10n.yaml) and the `gen-l10n` build tool.

---

## 2. Code Elements Section

### 2.1 Abstract Base Class: [`AppLocalizations`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L64-L1372)

The abstract base class defines the public localization API for the application, standardizing message accessors and parameter signatures.

#### Constructors & Properties
- [`AppLocalizations(String locale)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L65-L66): Initializes the instance and assigns `localeName` canonicalized via `intl.Intl.canonicalizedLocale(locale.toString())`.
- [`final String localeName`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L68): Canonical string representation of the current locale.

#### Static Members & Delegates
- [`static AppLocalizations? of(BuildContext context)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L70-L72): Looks up the nearest `AppLocalizations` instance provided in the widget hierarchy using `Localizations.of<AppLocalizations>(context, AppLocalizations)`.
- [`static const LocalizationsDelegate<AppLocalizations> delegate`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L74-L75): Instance of [`_AppLocalizationsDelegate`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1374-L1389).
- [`static const List<LocalizationsDelegate<dynamic>> localizationsDelegates`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L87-L93): Pre-configured composite delegate list containing:
  1. [`AppLocalizations.delegate`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L74-L75)
  2. `GlobalMaterialLocalizations.delegate`
  3. `GlobalCupertinoLocalizations.delegate`
  4. `GlobalWidgetsLocalizations.delegate`
- [`static const List<Locale> supportedLocales`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L96-L99): Supported locale configurations: `[Locale('en'), Locale('es')]`.

#### Localized String Accessors (By Functional Domain)

##### Global Values & Shell State
| Signature | Return Type | Purpose / Message Context |
| :--- | :--- | :--- |
| [`appTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L105) | `String get` | Application header and window title ("Terralink Dashboard" / "Panel Predictivo Savia") |
| [`hide`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L111) | `String get` | General toggle action to hide elements |
| [`status`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L117) | `String get` | Status label |
| [`cancel`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L123) | `String get` | Dismiss dialog or abort ongoing action |
| [`statusLabel(String msg)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L129) | `String` | Formatted status bar text (`STATUS: {msg}`) |
| [`verdictAvoidable`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L135) | `String get` | Irrigation recommendation: soil moisture stable |
| [`verdictNeeded`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L141) | `String get` | Irrigation recommendation: soil moisture critical, irrigate |
| [`mainScreenError`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L147) | `String get` | Unknown navigation target fallback |
| [`mainStatusReady`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L153) | `String get` | System ready state |
| [`mainStatusBleConnected`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L159) | `String get` | Savia BLE station connected notification |
| [`mainStatusBleDisconnected`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L165) | `String get` | Savia BLE station disconnected notification |

##### Navigation Tabs
| Signature | Return Type | Purpose / Message Context |
| :--- | :--- | :--- |
| [`homeTab`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L171) | `String get` | Label for Home / Dashboard tab |
| [`nearbyTab`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L177) | `String get` | Label for BLE Nearby Scanner tab |
| [`localDbTab`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L183) | `String get` | Label for Isar Database tab |
| [`cloudTab`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L189) | `String get` | Label for Cloud API & Emulation tab |
| [`configTab`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L195) | `String get` | Label for System Configuration tab |

##### Home Screen & Live Station Interfacing
| Signature | Return Type | Purpose / Message Context |
| :--- | :--- | :--- |
| [`homeConsoleInit`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L201) | `String get` | Initial message shown in serial/BLE console |
| [`homeConsoleCopiedSnack`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L207) | `String get` | SnackBar when console logs copied to clipboard |
| [`homeConsoleCopiedStatus`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L213) | `String get` | Status message after copying console log |
| [`homeExportJsonSnack(String fileName)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L219) | `String` | SnackBar when exporting console log to JSON file |
| [`homeExportJsonStatus(String path)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L225) | `String` | Status log indicating file path where JSON was written |
| [`homeExportJsonFailed(String error)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L231) | `String` | Error message on JSON export failure |
| [`homeBleAsyncData(String data)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L237) | `String` | Header for incoming unsolicited BLE telemetry notifications |
| [`homeGapYears(String years)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L243) | `String` | Formatted year discrepancy for station clock |
| [`homeGapDays(String days)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L249) | `String` | Formatted day discrepancy for station clock |
| [`homeGapHours(String hours)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L255) | `String` | Formatted hour discrepancy for station clock |
| [`homeGapMins(String mins)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L261) | `String` | Formatted minute discrepancy for station clock |
| [`homeGapSecs(String secs)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L267) | `String` | Formatted second discrepancy for station clock |
| [`homeExecutingSync`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L273) | `String get` | Station RTC sync initiation text |
| [`homeSyncSuccess(String date)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L279) | `String` | Station RTC sync success message with new timestamp |
| [`homeSyncCompleted`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L285) | `String get` | Station RTC sync completion status |
| [`homeSyncErrorConsole(String error)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L291) | `String` | Detailed RTC synchronization error |
| [`homeSyncFailedStatus`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L297) | `String get` | General RTC synchronization failed status |
| [`homeVoidOutput`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L303) | `String get` | Ack for command returning empty body |
| [`homeExecutingAction(String name)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L309) | `String` | Action execution in progress |
| [`homeActionRes(String name, String res)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L315) | `String` | Output payload returned from device action |
| [`homeActionCompleted(String name)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L321) | `String` | Successful command notification |
| [`homeActionError(String name, String error)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L327) | `String` | Command failure error log |
| [`homeActionFailed(String name)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L333) | `String` | Action failure status bar banner |
| [`homeDebugTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L339) | `String get` | Debug panel caution header |
| [`homeBtnMock`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L345) | `String get` | Button: inject 72h mock telemetry |
| [`homeBtnClearStorage`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L351) | `String get` | Button: wipe Pico flash station storage |
| [`homeAiTitleYellow`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L357) | `String get` | Header for yellow-zone (gathering phase) recommendation |
| [`homeAiTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L363) | `String get` | Header for standard AI recommendation |
| [`homeAiYellowWarning(int endH, int startH)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L369) | `String` | Advisory explaining telemetry collection window bounds |
| [`homeAiMinHum(String humidity, String date)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L375) | `String` | Predicted minimum soil humidity and timestamp |
| [`homeAiNoData`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L381) | `String get` | Empty state notice when no prediction exists |
| [`homeNoBleConnected`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L387) | `String get` | Empty state notice prompting user to pair a station |
| [`homeConnectedTitle(String devName)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L393) | `String` | Connected station title |
| [`homeClockUnknown`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L399) | `String get` | Station RTC unknown state |
| [`homeTooltipSync`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L405) | `String get` | Tooltip for RTC synchronize button |
| [`homeGapLabel(String gap)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L411) | `String` | Label showing time offset between phone and station |
| [`homeBtnReadStatus`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L417) | `String get` | Button: trigger status read command |
| [`homeBtnRequestData`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L423) | `String get` | Button: request telemetry packets |
| [`homeBtnTriggerInference`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L429) | `String get` | Button: run on-device / local ML inference |
| [`homeConsoleTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L435) | `String get` | Title for the console window |
| [`homeTooltipCopy`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L441) | `String get` | Tooltip: copy console logs |
| [`homeTooltipDownload`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L447) | `String get` | Tooltip: download console logs |

##### Local Database (`Isar`) & Agronomic Records
| Signature | Return Type | Purpose / Message Context |
| :--- | :--- | :--- |
| [`dbSyncingCloud`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L453) | `String get` | Status message: syncing local DB with backend |
| [`dbSyncCompleted(int count)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L459) | `String` | Sync confirmation with number of processed devices |
| [`dbSyncError(String error)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L465) | `String` | Database cloud sync error details |
| [`dbNoSelection`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L471) | `String get` | Prompt to pick a device before running action |
| [`dbRunningInference(String name, String id)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L477) | `String` | Progress message when executing Random Forest model |
| [`dbInferenceFinished(String verdict)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L483) | `String` | RF execution result text |
| [`dbInferenceFailed(String error)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L489) | `String` | RF execution error log |
| [`dbClearTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L495) | `String get` | Confirmation dialog title for clearing DB |
| [`dbClearDesc`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L501) | `String get` | Confirmation dialog warning description |
| [`dbBtnClearData`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L507) | `String get` | Confirmation dialog destructive button |
| [`dbClearSuccess`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L513) | `String get` | Database wiped success notice |
| [`dbRfNotCalculated`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L519) | `String get` | Empty model inference placeholder |
| [`dbRfYellowTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L525) | `String get` | Yellow zone header for local DB RF card |
| [`dbRfTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L531) | `String get` | Optimal window header for local DB RF card |
| [`dbRfYellowWarning(int endH, int startH)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L537) | `String` | Gathering window notice for local DB record |
| [`dbRfMinHum(String humidity, String date)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L543) | `String` | Historical predicted min humidity and time |
| [`dbRfNoPredictions`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L549) | `String get` | No predictions in DB message |
| [`dbScreenTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L555) | `String get` | Screen title for Local DB view |
| [`dbBtnSyncCloud`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L561) | `String get` | Button: trigger cloud sync |
| [`dbBtnClearDb`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L567) | `String get` | Button: clear database records |
| [`dbNoDevices`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L573) | `String get` | Empty state when no station entries exist in Isar DB |
| [`dbStateSynced`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L579) | `String get` | Badge indicating record is synchronized with Cloud |
| [`dbStateUnsynced`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L585) | `String get` | Badge indicating record has unsynced local mutations |
| [`dbTelemetryInfo(int records, int predictions)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L591) | `String` | Record count indicator (`Telemetry: X \| Predictions: Y`) |
| [`dbLocationInfo(String lat, String lon)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L597) | `String` | Coordinate string (`\| Lat: X, Lon: Y`) |
| [`dbBtnRunInference`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L603) | `String get` | Button: trigger model inference |

##### Nearby BLE Scanner & Permissions
| Signature | Return Type | Purpose / Message Context |
| :--- | :--- | :--- |
| [`nbFoundDevices(int count)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L609) | `String` | Scanner status indicator showing count of discovered peripherals |
| [`nbRefreshingScan`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L615) | `String get` | BLE adapter scanning refresh progress |
| [`nbConnectDialogTitle(String name)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L621) | `String` | Pairing authentication dialog title |
| [`nbDeviceId(String id)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L627) | `String` | Dialog subtitle displaying BLE MAC or identifier |
| [`nbSavedSecret(String secret)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L633) | `String` | Display string for retrieved secure secret |
| [`nbTooltipShowSaved`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L639) | `String get` | Tooltip to reveal stored secret |
| [`nbTooltipHideSaved`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L645) | `String get` | Tooltip to obscure stored secret |
| [`nbLeaveBlankHint`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L651) | `String get` | Form field helper to reuse existing secret |
| [`nbSecretLabel`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L657) | `String get` | Input field label for HMAC handshake secret |
| [`nbTooltipShowSecret`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L663) | `String get` | Tooltip to toggle secret visibility on |
| [`nbTooltipHideSecret`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L669) | `String get` | Tooltip to toggle secret visibility off |
| [`nbBtnConnect`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L675) | `String get` | Button: initiate BLE connection |
| [`nbConnectingStatus(String name)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L681) | `String` | Progress banner while establishing BLE connection |
| [`nbConnectedSuccess(String name)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L687) | `String` | Banner on successful handshake |
| [`nbConnectionFailed`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L693) | `String get` | Notice when BLE connection or authentication drops |
| [`nbDisconnectedStatus`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L699) | `String get` | Manual disconnect status text |
| [`nbScreenTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L705) | `String get` | Title for the Nearby BLE screen |
| [`nbBtnDisconnect`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L711) | `String get` | Button: terminate current BLE link |
| [`nbBtnScan`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L717) | `String get` | Button: restart BLE scan |
| [`nbCurrentConnection(String name)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L723) | `String` | Card title showing active connected device |
| [`nbNegotiatingStatus`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L729) | `String get` | Status message during HMAC-SHA256 challenge negotiation |
| [`nbNoDevices`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L735) | `String get` | Empty list banner advising station power check |
| [`nbDeviceSub(String id, int rssi)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L741) | `String` | Device list tile subtitle (`ID: X RSSI: Y dBm`) |
| [`nbUnknownDev`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L747) | `String get` | Fallback device identifier |
| [`nbUnnamedDev`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L753) | `String get` | Fallback for devices without advertised names |
| [`nbWarningBtOff`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L759) | `String get` | Hardware warning: Bluetooth adapter disabled |
| [`nbWarningBtOffDesc`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L765) | `String get` | Explanation of why Bluetooth must be enabled |
| [`nbBtnTurnOnBt`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L771) | `String get` | Action button to open Bluetooth settings |
| [`nbWarningLocOff`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L777) | `String get` | Hardware warning: Location services disabled |
| [`nbWarningLocOffDesc`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L783) | `String get` | Explanation of BLE requirement for location services |
| [`nbBtnTurnOnLoc`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L789) | `String get` | Action button to open Location settings |
| [`nbWarningPerms`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L795) | `String get` | Warning banner: OS permissions missing |
| [`nbWarningPermsDesc`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L801) | `String get` | Explanation requesting Bluetooth / Location permissions |
| [`nbBtnGrantPerms`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L807) | `String get` | Action button triggering runtime permission prompt |

##### System Configuration & Open-Meteo
| Signature | Return Type | Purpose / Message Context |
| :--- | :--- | :--- |
| [`cfgChecking`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L813) | `String get` | Status when checking endpoint health |
| [`cfgAcquiringGps`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L819) | `String get` | Progress text when polling GPS hardware |
| [`cfgGpsUpdated(String lat, String lon)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L825) | `String` | Confirmation after auto GPS coordinate acquisition |
| [`cfgGpsFailed`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L831) | `String get` | GPS fix timeout or disabled error |
| [`cfgGpsError(String error)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L837) | `String` | Low-level GPS exception message |
| [`cfgMapTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L843) | `String get` | Interactive map modal title |
| [`cfgMapHint(String lat, String lon)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L849) | `String` | Instruction on map screen indicating current tap point |
| [`cfgBtnConfirmLoc`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L855) | `String get` | Button: lock in selected map coordinates |
| [`cfgMapUpdated(String lat, String lon)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L861) | `String` | Confirmation when coordinates set via map |
| [`cfgLocModeTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L867) | `String get` | Dialog header for location mode selection |
| [`cfgLocModeAuto`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L873) | `String get` | Mode option: Automatic GPS |
| [`cfgLocModeAutoDesc`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L879) | `String get` | Description of Automatic GPS mode |
| [`cfgLocModeManual`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L885) | `String get` | Mode option: Manual Map picker |
| [`cfgLocModeManualDesc`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L891) | `String get` | Description of Manual Map mode |
| [`cfgPredStartUpdated(int start)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L897) | `String` | Confirmation after adjusting prediction window start hour |
| [`cfgPredLimit(int base)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L903) | `String` | Validation limit: window can only be shifted ±3h from base |
| [`cfgIrrEndUpdated(int end)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L909) | `String` | Confirmation after adjusting irrigation window end hour |
| [`cfgIrrLimit(int base)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L915) | `String` | Validation limit: window can only be shifted ±3h from base |
| [`cfgMeteoOk`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L921) | `String get` | Open-Meteo HTTP 200 response |
| [`cfgMeteoError(int code)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L927) | `String` | Open-Meteo HTTP error status code |
| [`cfgMeteoOffline`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L933) | `String get` | Open-Meteo network timeout / offline |
| [`cfgPingTesting`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L939) | `String get` | Network latency ping in progress |
| [`cfgPingRes(String status, int ms)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L945) | `String` | Formatted ping latency (`OK (45 ms)`) |
| [`cfgPingFailed`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L951) | `String get` | Ping connection failure |
| [`cfgSavedStatus`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L957) | `String get` | Confirmation when config saved to Isar & Live ApiClient |
| [`cfgEndpointTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L963) | `String get` | Modal title for Cloud URL input |
| [`cfgEndpointLabel`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L969) | `String get` | Form label for Cloud endpoint URL |
| [`cfgEndpointHint(String hint)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L975) | `String` | Placeholder hint for endpoint URL |
| [`cfgBtnUpdate`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L981) | `String get` | Button: update endpoint text |
| [`cfgEndpointUpdated`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L987) | `String get` | Status message reminding user to commit config |
| [`cfgLocString(String lat, String lon, String type)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L993) | `String` | Formatted location summary (`Lat: X, Lon: Y (GPS)`) |
| [`cfgScreenTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L999) | `String get` | Header title for Configuration screen |
| [`cfgBtnApplySave`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1005) | `String get` | Primary action button: persist and broadcast configuration |
| [`cfgEnvSection`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1011) | `String get` | Section header: Environment & Telemetry Parameters |
| [`cfgSysTimeLabel`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1017) | `String get` | Label: System Date & Time |
| [`cfgLocSettingsLabel`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1023) | `String get` | Label: Coordinates / Field Location |
| [`cfgTooltipLoc`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1029) | `String get` | Tooltip: configure GPS/Map mode |
| [`cfgNetSection`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1035) | `String get` | Section header: Network Services & Endpoints |
| [`cfgMeteoLabel`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1041) | `String get` | Label: Open-Meteo API Status |
| [`cfgCloudLabel`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1047) | `String get` | Label: Cloud Server Base URL |
| [`cfgTooltipEditEnd`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1053) | `String get` | Tooltip: edit server endpoint URL |
| [`cfgAgroSection`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1059) | `String get` | Section header: Agronomic Schedule (24H Clock) |
| [`cfgIrrPeriod`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1065) | `String get` | Label: Irrigation cycle window |
| [`cfgPeriodRange(String start, String end)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1071) | `String` | Formatted window range string (`08:00hrs to 12:00hrs`) |
| [`cfgShiftBtn`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1077) | `String get` | Button label: Shift time interval |
| [`cfgPredPeriod`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1083) | `String get` | Label: Optimal prediction cycle window |

##### Cloud Services & Emulation
| Signature | Return Type | Purpose / Message Context |
| :--- | :--- | :--- |
| [`cloudTestingConnection`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1089) | `String get` | Cloud API ping test in progress |
| [`cloudStatusConnected`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1095) | `String get` | Badge text: Connected |
| [`cloudStatusUnreachable`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1101) | `String get` | Badge text: Unreachable |
| [`cloudStatusError`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1107) | `String get` | Badge text: Error |
| [`cloudStatusConnectionUnknown`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1113) | `String get` | Badge text: Unknown |
| [`cloudStatusTesting`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1119) | `String get` | Badge text: Testing in progress |
| [`cloudApiOnline`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1125) | `String get` | Server online confirmation banner |
| [`cloudApiNoResponse`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1131) | `String get` | Server unresponsive error |
| [`cloudApiTestFailed(String error)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1137) | `String` | Detailed connection failure description |
| [`cloudSyncInitiating`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1143) | `String get` | Sync routine triggered text |
| [`cloudSyncFinished`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1149) | `String get` | Sync routine finished text |
| [`cloudSyncError(String error)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1155) | `String` | Cloud synchronization error message |
| [`cloudEmulationAbortedNoStation`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1161) | `String get` | Emulation aborted: no cloud registered station found |
| [`cloudEmulationNoSelection`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1167) | `String get` | Prompt to select station before running emulation |
| [`cloudEmulationExecuting(String name, String id)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1173) | `String` | Status during cloud in-memory inference |
| [`cloudEmulationFinished(String verdict)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1179) | `String` | Emulated RF inference finished message |
| [`cloudEmulationError(String error)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1185) | `String` | Cloud emulation exception text |
| [`cloudApiStatusTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1191) | `String get` | Card header: API Connection Status |
| [`cloudBtnTestApi`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1197) | `String get` | Button: Test API health endpoint |
| [`cloudBtnSync(int count)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1203) | `String` | Button: Sync dirty local records (`Sync (3 dirty)`) |
| [`cloudTargetEndpoint(String url)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1209) | `String` | Formatted endpoint target display |
| [`cloudApiAuthLabel(String status)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1215) | `String` | Authorization header status |
| [`cloudApiAuthConfigured`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1221) | `String get` | Authorization token present (`Configured [OK]`) |
| [`cloudApiAuthMissing`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1227) | `String get` | Authorization token missing |
| [`cloudConnectionStateLabel`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1233) | `String get` | Connection state label prefix |
| [`cloudEmuYellowZoneTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1239) | `String get` | Title for emulated RF in yellow zone |
| [`cloudEmuNormalTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1245) | `String get` | Title for emulated RF in normal window |
| [`cloudEmuYellowZoneWarning(int endH, int startH)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1251) | `String` | Gathering phase disclaimer for in-memory emulation |
| [`cloudEmuMinHumidity(String humidity, String date)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1257) | `String` | Predicted min humidity and expected timestamp |
| [`cloudEmuRadSum(String sum)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1263) | `String` | Solar radiation accumulation (`48h Radiation Sum: X J/m²`) |
| [`cloudEmuRefTimestamp(String date)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1269) | `String` | Reference prediction timestamp label |
| [`cloudCoordsLatLon(String lat, String lon)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1275) | `String` | Formatted coordinate pair (`Lat: X, Lon: Y`) |
| [`cloudCoordsNA`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1281) | `String get` | Fallback coordinate placeholder (`Lat N/A, Lon N/A`) |
| [`cloudCoordinatesLabel(String coords)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1287) | `String` | Label wrapper for coordinates |
| [`cloudHeaderTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1293) | `String get` | Screen header: Cloud Services & Emulation |
| [`cloudRegisteredStationsTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1299) | `String get` | Subtitle for list of registered stations |
| [`cloudNoStationsFound`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1305) | `String get` | Empty station list prompt |
| [`cloudSelectedStationMsg(String name)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1311) | `String` | Card banner showing selected cloud station |
| [`cloudBtnEmulateStation`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1317) | `String get` | Button: trigger cloud RF emulation |
| [`cloudValNA`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1323) | `String get` | N/A abbreviation |
| [`cloudEmuNoData`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1329) | `String get` | Empty emulation card placeholder |
| [`cloudValUnknown`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1335) | `String get` | Unknown value placeholder |

##### Generic Inference & Agronomic Advisory Card
| Signature | Return Type | Purpose / Message Context |
| :--- | :--- | :--- |
| [`inferenceRestrictedTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1341) | `String get` | Title banner when device is in yellow/restricted window |
| [`inferenceRestrictedDesc(int startI, int endI, int startH, int endH)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1347) | `String` | Full explanation of gathering interval vs optimal prediction interval |
| [`inferenceUnrecommendedTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1353) | `String get` | Warning title for out-of-window prediction |
| [`inferenceUnrecommendedWarning(int startH, int endH)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1359) | `String` | Warning body: result is for debugging only |
| [`inferenceRecommendedTitle`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1365) | `String get` | Title banner for optimal AI irrigation verdict |
| [`inferenceInfoSource(String source)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1371) | `String` | Inference origin attribution (`Source: {source}`) |

---

### 2.2 Localization Delegate Class: [`_AppLocalizationsDelegate`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1374-L1389)

An internal concrete implementation of Flutter's `LocalizationsDelegate<AppLocalizations>`.

#### Methods
- [`const _AppLocalizationsDelegate()`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1376): Constant constructor.
- [`Future<AppLocalizations> load(Locale locale)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1379-L1381): Synchronously loads the localizations via `SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale))`.
- [`bool isSupported(Locale locale)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1384-L1385): Returns `true` if `['en', 'es'].contains(locale.languageCode)`.
- [`bool shouldReload(_AppLocalizationsDelegate old)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1388): Returns `false` since the delegate instance is stateless and immutable.

---

### 2.3 Top-Level Locale Dispatcher: [`lookupAppLocalizations(Locale locale)`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1391-L1406)

```dart
AppLocalizations lookupAppLocalizations(Locale locale)
```
- **Description**: Factory dispatch function resolving a `Locale` to the appropriate concrete subclass (`AppLocalizationsEn` or `AppLocalizationsEs`).
- **Control Flow**:
  - `locale.languageCode == 'en'` -> returns [`AppLocalizationsEn()`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations_en.dart#L9).
  - `locale.languageCode == 'es'` -> returns [`AppLocalizationsEs()`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations_es.dart#L9).
  - Otherwise throws `FlutterError` indicating unsupported locale.

---

### 2.4 Concrete Implementation Classes

#### [`AppLocalizationsEn`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations_en.dart#L8-L805)
- **Superclass**: [`AppLocalizations`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L64-L1372)
- **Constructor**: [`AppLocalizationsEn([String locale = 'en']) : super(locale);`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations_en.dart#L9)
- **Responsibilities**: Implements all 100+ abstract getters and methods with English string literals and string interpolation expressions (e.g. `'$startH:00 - $endH:00'`).

#### [`AppLocalizationsEs`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations_es.dart#L8-L814)
- **Superclass**: [`AppLocalizations`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L64-L1372)
- **Constructor**: [`AppLocalizationsEs([String locale = 'es']) : super(locale);`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations_es.dart#L9)
- **Responsibilities**: Implements all 100+ abstract getters and methods with Spanish string translations and matching string interpolation expressions.

---

### 2.5 Translation Resource Catalogs (ARB)

#### [`app_en.arb`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_en.arb#L1-L375)
- **Role**: Base source template file for the application.
- **Locale**: `"@@locale": "en"`.
- **Contents**: JSON-structured dictionary specifying localization keys, default English text, and placeholder type definitions (e.g. `{"placeholders": {"startH": {"type": "int"}}}`).
- **Categories**:
  - `@@_GLOBAL_VALUES`
  - `@@_NAVIGATION_TABS`
  - `@@_HOME_SCREEN`
  - `@@_LOCAL_DB_SCREEN`
  - `@@_NEARBY_SCREEN`
  - `@@_CONFIG_SCREEN`
  - `@@_CLOUD_SCREEN`

#### [`app_es.arb`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_es.arb#L1-L222)
- **Role**: Target translation file for Castilian Spanish.
- **Locale**: `"@@locale": "es"`.
- **Contents**: Spanish localized translations aligned with the keys from `app_en.arb`.

---

## 3. Dependencies Section

### 3.1 Internal Dependencies

#### Downstream Consumers (Screens & Widgets consuming `AppLocalizations`)
- [`lib/main.dart`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/main.dart#L6): Configures `MaterialApp.localizationsDelegates` and `supportedLocales`, and queries initial ready/connection messages in `_DashboardShellState`.
- [`lib/screens/home_screen.dart`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/screens/home_screen.dart): Localized console notifications, clock synchronization summaries, debug wipe actions, and live BLE status.
- [`lib/screens/nearby_screen.dart`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/screens/nearby_screen.dart): BLE scanner UI, pairing authentication dialogs, RSSI formatting, and Bluetooth/Location permission banners.
- [`lib/screens/config_screen.dart`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/screens/config_screen.dart): System parameters, Open-Meteo latency checks, GPS vs manual map coordinates, and agronomic shift validation.
- [`lib/screens/storage_screen.dart`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/screens/storage_screen.dart): Local Isar database records, telemetry count badges, and offline Random Forest inference buttons.
- [`lib/screens/widgets/inference_card.dart`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/screens/widgets/inference_card.dart): Shared AI recommendation cards, yellow-zone telemetry collection advisories, and prediction window warnings.

#### Build Configuration
- [`l10n.yaml`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/l10n.yaml#L1-L7):
  ```yaml
  arb-dir: lib/core/utils/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  translator:
    targets:
      - es
  ```
- [`pubspec.yaml`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/pubspec.yaml#L60-L62): Configured with `flutter: generate: true` to trigger automatic source generation on `flutter pub get` or `flutter run`.

### 3.2 External Dependencies

| Package / Library | Scope / Purpose |
| :--- | :--- |
| `dart:async` | Provides `Future` for asynchronous delegate resolution |
| `package:flutter/widgets.dart` | `BuildContext`, `Widget`, `Localizations`, `Locale` primitives |
| `package:flutter/foundation.dart` | `SynchronousFuture`, `FlutterError` |
| `package:flutter_localizations` | Flutter SDK standard localization delegates (`GlobalMaterialLocalizations`, `GlobalCupertinoLocalizations`, `GlobalWidgetsLocalizations`) |
| `package:intl` (`intl.Intl`) | Canonical locale string parsing and formatting |
| `auto_translator` (dev dependency) | Automated translation maintenance between ARB files |

---

## 4. Relationships Section

The following diagram illustrates the relationship between code generation assets, the runtime delegate hierarchy, and UI consumption in the Flutter widget tree:

```mermaid
flowchart TD
    subgraph ToolingAndAssets["Build & Generation Pipeline"]
        YAML["l10n.yaml"]
        ARB_EN["app_en.arb (Template)"]
        ARB_ES["app_es.arb (Translation)"]
        GEN["Flutter gen-l10n Tool"]
        
        YAML --> GEN
        ARB_EN --> GEN
        ARB_ES --> GEN
    end

    subgraph RuntimeClasses["lib/core/utils/l10n"]
        GEN -.->|Generates| AL["AppLocalizations (Abstract Base)"]
        GEN -.->|Generates| AL_EN["AppLocalizationsEn"]
        GEN -.->|Generates| AL_ES["AppLocalizationsEs"]
        GEN -.->|Generates| AL_DEL["_AppLocalizationsDelegate"]
        GEN -.->|Generates| LOOKUP["lookupAppLocalizations(Locale)"]

        AL_EN --|>|Implements| AL
        AL_ES --|>|Implements| AL
        AL_DEL -->|Loads via| LOOKUP
        LOOKUP -->|Instantiates Locale 'en'| AL_EN
        LOOKUP -->|Instantiates Locale 'es'| AL_ES
        AL -->|Exposes| AL_DEL
    end

    subgraph FlutterFramework["Flutter Framework"]
        MAT_APP["MaterialApp (main.dart)"]
        LOC_WIDGET["Localizations (InheritedWidget)"]
        BUILD_CTX["BuildContext"]
        
        AL -.->|Provides delegates & locales| MAT_APP
        MAT_APP --> LOC_WIDGET
        LOC_WIDGET --> BUILD_CTX
    end

    subgraph Consumers["Application UI Consumers"]
        HOME["HomeScreen"]
        NEARBY["NearbyScreen"]
        STORAGE["StorageScreen"]
        CONFIG["ConfigScreen"]
        INF_CARD["InferenceCard"]

        BUILD_CTX -->|AppLocalizations.of(context)| HOME
        BUILD_CTX -->|AppLocalizations.of(context)| NEARBY
        BUILD_CTX -->|AppLocalizations.of(context)| STORAGE
        BUILD_CTX -->|AppLocalizations.of(context)| CONFIG
        BUILD_CTX -->|AppLocalizations.of(context)| INF_CARD
    end
```

### Key Execution Lifecycle

1. **Initialization**: [`MaterialApp`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/main.dart#L20-L35) mounts [`AppLocalizations.localizationsDelegates`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L87-L93) and registers `supportedLocales` (`en` and `es`).
2. **Resolution**: When locale changes or on initial frame build, Flutter invokes [`_AppLocalizationsDelegate.load()`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1379-L1381), which delegates to [`lookupAppLocalizations()`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations.dart#L1391-L1406).
3. **Dispatch**: Depending on device locale, either [`AppLocalizationsEn`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations_en.dart#L8-L805) or [`AppLocalizationsEs`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/core/utils/l10n/app_localizations_es.dart#L8-L814) is returned via `SynchronousFuture`.
4. **Access**: Any screen or component calls `AppLocalizations.of(context)!.<key>` to retrieve typed localized messages or format messages with dynamic arguments (such as time windows, error payloads, and device metrics).
