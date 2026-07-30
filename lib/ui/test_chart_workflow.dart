import 'package:flutter/material.dart';
import '../data/models/models.dart';
import 'widgets/charts/unified_chart.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TestChartWorkflowScreen(),
  ));
}

class TestChartWorkflowScreen extends StatefulWidget {
  const TestChartWorkflowScreen({super.key});

  @override
  State<TestChartWorkflowScreen> createState() => _TestChartWorkflowScreenState();
}

class _TestChartWorkflowScreenState extends State<TestChartWorkflowScreen> {
  List<SoilHumidityRecord> history = [];
  List<PredictionRecord> predictions = [];
  List<WeatherRecord> weatherHistory = [];
  List<double> radiationForecast = [];
  List<double> temperatureForecast = []; // <-- Added new metric

  int timeOffsetHours = 0; // 0 = now
  int forecastZoneStartHour = 19;
  int forecastZoneEndHour = 9;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateInitialData();
  }

  void _generateInitialData() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const msPerHour = 3600000;

    history.clear();
    weatherHistory.clear();
    predictions.clear();
    radiationForecast.clear();
    temperatureForecast.clear();

    // Generate history: past 24 hours
    for (int i = -24; i <= 0; i++) {
      final ts = nowMs + i * msPerHour;
      double phase = (i + 24) / 24.0 * 3.14159 * 2;
      history.add(SoilHumidityRecord(ts, 60.0 + 10 * (i % 5 == 0 ? 1 : 0.5)));
      weatherHistory.add(WeatherRecord(
        ts, 
        15.0 + 10.0 * MathUtils.sin(phase), // simulated temp curve
        50.0, 
        MathUtils.max(0, 800.0 * MathUtils.sin(phase)), 
        0.0,
      ));
    }

    // Generate forecast: next 24 hours
    for (int i = 1; i <= 24; i++) {
      final ts = nowMs + i * msPerHour;
      double phase = (i) / 24.0 * 3.14159 * 2;
      predictions.add(PredictionRecord(ts, 65.0 + 5 * (i % 3), "Water soon"));
      radiationForecast.add(MathUtils.max(0, 750.0 * MathUtils.sin(phase)));
      temperatureForecast.add(15.0 + 12.0 * MathUtils.sin(phase)); // simulated temp forecast
    }

    setState(() {});
  }

  void _injectHistoricalData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    const msPerHour = 3600000;
    if (history.isEmpty) return;
    final earliestTs = history.first.timestamp;

    final newHistory = <SoilHumidityRecord>[];
    final newWeather = <WeatherRecord>[];

    for (int i = 50; i > 0; i--) {
      final ts = earliestTs - i * msPerHour;
      newHistory.add(SoilHumidityRecord(ts, 50.0 + (i % 10)));
      newWeather.add(WeatherRecord(
        ts, 
        10.0 + 5.0 * MathUtils.sin(i / 24.0 * 3.14159), // cold snap injected
        40.0, 
        MathUtils.max(0, 500.0 * MathUtils.sin(i / 24.0 * 3.14159)), 
        0.0,
      ));
    }

    setState(() {
      history.insertAll(0, newHistory);
      weatherHistory.insertAll(0, newWeather);
      _isLoading = false;
    });
  }

  void _updateForecast() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const msPerHour = 3600000;

    predictions.clear();
    radiationForecast.clear();
    temperatureForecast.clear();

    for (int i = 1; i <= 24; i++) {
      final ts = nowMs + i * msPerHour;
      double phase = (i) / 24.0 * 3.14159 * 2;
      predictions.add(PredictionRecord(ts, 40.0 + 2 * (i % 4), "Drying rapidly"));
      radiationForecast.add(MathUtils.max(0, 950.0 * MathUtils.sin(phase))); 
      temperatureForecast.add(20.0 + 15.0 * MathUtils.sin(phase)); // heatwave
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart Workflow Tester'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Unified Chart View",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                UnifiedChart(
                  history: history,
                  predictions: predictions,
                  radiationForecast: radiationForecast,
                  temperatureForecast: temperatureForecast,
                  weatherHistory: weatherHistory,
                  minHumidity: 0,
                  timeOffsetHours: timeOffsetHours,
                  forecastZoneStartHour: forecastZoneStartHour,
                  forecastZoneEndHour: forecastZoneEndHour, deviceHistory: [],
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                const Text(
                  "Workflow Test Controls",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Simulate Cloud Sync (Inject 50h History)'),
                      onPressed: _injectHistoricalData,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.online_prediction),
                      label: const Text('Simulate Model Update (New Forecast)'),
                      onPressed: _updateForecast,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset Data'),
                      onPressed: () {
                        setState(() {
                          timeOffsetHours = 0;
                          forecastZoneStartHour = 19;
                          forecastZoneEndHour = 9;
                          _generateInitialData();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text("Simulate Logic Stages (Time Travel)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Offset Hours: "),
                    Expanded(
                      child: Slider(
                        value: timeOffsetHours.toDouble(),
                        min: -24,
                        max: 24,
                        divisions: 48,
                        label: "${timeOffsetHours}h",
                        onChanged: (val) {
                          setState(() {
                            timeOffsetHours = val.toInt();
                          });
                        },
                      ),
                    ),
                    Text(
                      "${timeOffsetHours > 0 ? '+' : ''}$timeOffsetHours h",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  "Current Simulated Time: ${TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: timeOffsetHours))).format(context)}",
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),

                const SizedBox(height: 24),
                const Text("Customize Zones", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text("Forecast Start Hour: ")),
                    Expanded(
                      flex: 2,
                      child: Slider(
                        value: forecastZoneStartHour.toDouble(),
                        min: 0,
                        max: 23,
                        divisions: 23,
                        label: "${forecastZoneStartHour}h",
                        onChanged: (val) {
                          setState(() => forecastZoneStartHour = val.toInt());
                        },
                      ),
                    ),
                    Text("${forecastZoneStartHour}h", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(child: Text("Forecast End Hour: ")),
                    Expanded(
                      flex: 2,
                      child: Slider(
                        value: forecastZoneEndHour.toDouble(),
                        min: 0,
                        max: 23,
                        divisions: 23,
                        label: "${forecastZoneEndHour}h",
                        onChanged: (val) {
                          setState(() => forecastZoneEndHour = val.toInt());
                        },
                      ),
                    ),
                    Text("${forecastZoneEndHour}h", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),

              ],
            ),
        ),
    );
  }
}

class MathUtils {
  static double max(double a, double b) => a > b ? a : b;
  static double sin(double x) {
     const double PI = 3.14159265;
     while (x > PI) x -= 2 * PI;
     while (x < -PI) x += 2 * PI;
     return (16 * x * (PI - x.abs())) / (5 * PI * PI - 4 * x.abs() * (PI - x.abs()));
  }
}
