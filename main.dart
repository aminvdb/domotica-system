import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relay Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ConnectScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _connecting = false;
  String _statusMessage = "";

  Future<void> connectToHC05() async {
    final hc05 = BluetoothDevice(name: "HC-05", address: "58:56:00:01:7D:5C");

    // ✅ Vraag permissies met betere check
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => !status.isGranted)) {
      setState(() {
        _statusMessage = "❌ Toestemming geweigerd voor Bluetooth.";
      });
      return;
    }

    setState(() {
      _connecting = true;
      _statusMessage = "🔄 Verbinden met HC-05...";
    });

    try {
      final connection = await Future.any([
        BluetoothConnection.toAddress(hc05.address),
        Future.delayed(Duration(seconds: 20), () => throw TimeoutException("⏱️ Timeout")),
      ]);

      setState(() {
        _statusMessage = "✅ Verbonden met HC-05!";
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeControlScreen(connection: connection as BluetoothConnection),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = "❌ Verbinden mislukt: ${e is TimeoutException ? 'Timeout' : e.toString()}";
        _connecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bluetooth Relay")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.bluetooth),
              label: Text("Verbind met HC-05"),
              onPressed: _connecting ? null : connectToHC05,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            SizedBox(height: 20),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeControlScreen extends StatefulWidget {
  final BluetoothConnection connection;

  const HomeControlScreen({super.key, required this.connection});

  @override
  _HomeControlScreenState createState() => _HomeControlScreenState();
}

class _HomeControlScreenState extends State<HomeControlScreen> {
  List<bool> buttonStates = List.generate(6, (_) => false);

  void sendCommand(String command) {
    if (widget.connection.isConnected) {
      widget.connection.output.add(Uint8List.fromList(command.codeUnits));
      print('📤 Commando verzonden: $command');
    }
  }

  Widget buildControlButton(int index, String label, String command) {
    bool isOn = buttonStates[index];

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isOn ? Colors.green : Colors.red,
        shape: CircleBorder(),
        padding: EdgeInsets.all(24),
      ),
      onPressed: () {
        setState(() {
          buttonStates[index] = !buttonStates[index];
          if (buttonStates[index]) {
            sendCommand(command);
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOn ? Icons.power : Icons.power_off, color: Colors.white),
          Text(label, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('6 Relay Controller')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            buildControlButton(0, "Knop 1", "a"),
            buildControlButton(1, "Knop 2", "b"),
            buildControlButton(2, "Knop 3", "c"),
            buildControlButton(3, "Knop 4", "d"),
            buildControlButton(4, "Knop 5", "e"),
            buildControlButton(5, "Knop 6", "f"),
          ],
        ),
      ),
    );
  }
}
