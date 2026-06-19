import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerDialog extends StatefulWidget {
  final double initialLat;
  final double initialLon;

  const MapPickerDialog({
    super.key,
    required this.initialLat,
    required this.initialLon,
  });

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(widget.initialLat, widget.initialLon);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Station Location'),
      contentPadding: const EdgeInsets.all(8.0),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cesar.tfm_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Return the selected coordinates to the caller
            Navigator.pop(context, _selectedLocation);
          },
          child: const Text('Save Location'),
        ),
      ],
    );
  }
}