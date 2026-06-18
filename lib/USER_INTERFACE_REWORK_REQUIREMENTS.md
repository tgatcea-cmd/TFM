# Technical Specification

## Style Guides
* all text's use localization from 'core/localization.dart'
* dynamics fonts to compensate screen resolution variation
* use system colors from device
* use system icons (material, cupertino...)
* use as few colors as possible
* few decorations, avoid Decoration boxes, big shadows, crazy colors...

## Guidelines
* Always check if exists standarization.
* All menus have an understandable way of exiting (press outside, an x somewhere at the top, the "back" system buttom)

## Main View - State 0: No Sensor

* Central button: "Check for IoT Station" (device_menu)
* Bottom Navigation (use icons): Main View | Settings

### Device_menu

* Has navigation control: Nearby | Saved
* Animated deploy from original button
* Uses background BLE service to display available devices at "Nearby" listing.
* "Saved" listing displays existing entries at Database from selected device.
* When a device is displayed, the name, MAC and dB are shown.
* When a device is clicked, it begins the pairing and synchronization sequence. -> Move to Main View at State 1

## Main view - State 1: Sensor Paired

* Current Date and location.
* Unified chart displays synchronized data. The chars is horizontally scrollable.
* BIG Irrigation recommendation from Random Forest Inference. 
* Historical data vertical scroll view from that Specific sensor. (Lazy Loading)
* Bottom Button: Labeled as the selected SeFnsor, when pressed it opens the Device_menu and you can choose a new device or disconnect from current.
* Bottom Navigation (use icons): Main View | Settings

## Settings View

* Language Selector
* It displays app permissions state:
        * Internet Access (OpenMeteo API)
        * BLE Access
        * GPS Access
* Location Configuration toggle: Automatic <-> Manual
        * When Automatic it syncs to gps every 30 seconds.
        * When manual it displays the world map as a menu and the user can choose and apply a new location.
* Per Device database "Clear" button (it clears the database for that device).
* Bottom Button: Labeled as the selected Sensor, when pressed it opens the Device_menu and you can choose a new device or disconnect from current.
* Bottom Navigation (use icons): Main View | Settings

