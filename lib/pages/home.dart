import 'dart:io';

import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:band_names/models/band.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [
    // Band(id: '1', name: 'Metallica', votes: 5),
    // Band(id: '2', name: 'Queen', votes: 1),
    // Band(id: '3', name: 'Héoes del Silencio', votes: 2),
    // Band(id: '4', name: 'Bon Jovi', votes: 5),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();

    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BandNames',
          style: TextStyle(color: Colors.black87),
        ),
        elevation: 1,
        actions: [
          Container(
              margin: const EdgeInsets.only(
                right: 10,
              ),
              child: socketService.serverStatus == ServerStatus.connecting
                  ? const CircularProgressIndicator()
                  : socketService.serverStatus == ServerStatus.online
                      ? Icon(
                          Icons.check_circle,
                          color: Colors.blue[300],
                        )
                      : const Icon(
                          Icons.offline_bolt,
                          color: Colors.red,
                        ))
        ],
      ),
      body: Column(
        children: [
          bands.isEmpty ? const SizedBox.shrink() : _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, i) => _bandTile(bands[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 1,
        backgroundColor: Colors.blue[200],
        onPressed: addNewBand,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) =>
          socketService.socket.emit('delete-band', {'id': band.id}),
      background: Container(
        padding: const EdgeInsets.only(left: 8),
        color: Colors.red,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Delete Band',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(band.name.substring(0, 2)),
        ),
        title: Text(band.name),
        trailing: Text(
          '${band.votes}',
          style: const TextStyle(fontSize: 20),
        ),
        onTap: () => socketService.socket.emit('vote-band', {'id': band.id}),
      ),
    );
  }

  addNewBand() {
    final textControler = TextEditingController();

    if (Platform.isAndroid) {
      return showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('New band name:'),
          content: TextField(
            controller: textControler,
          ),
          actions: [
            MaterialButton(
              elevation: 5,
              textColor: Colors.blue,
              onPressed: () => addBandToList(textControler.text),
              child: const Text('Add'),
            ),
          ],
        ),
      );
    }

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('New band name:'),
        content: CupertinoTextField(
          controller: textControler,
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () => addBandToList(textControler.text),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Dismiss'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit('add-band', {'name': name});
    }

    Navigator.pop(context);
  }

  //Mostrar gráfica

  Widget _showGraph() {
    Map<String, double> dataMap = {};

    for (Band band in bands) {
      dataMap[band.name] = band.votes.toDouble();
    }

    final List<Color> colorList = [
      Colors.blue.shade50,
      Colors.blue.shade200,
      Colors.pink.shade50,
      Colors.pink.shade200,
      Colors.yellow.shade50,
      Colors.yellow.shade200,
    ];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: PieChart(
        dataMap: dataMap,
        animationDuration: const Duration(milliseconds: 800),
        chartLegendSpacing: 32,
        // chartRadius: MediaQuery.of(context).size.width / 3.2,
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: 32,
        // centerText: "HYBRID",
        legendOptions: const LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendShape: BoxShape.circle,
          legendTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        chartValuesOptions: const ChartValuesOptions(
          showChartValueBackground: true,
          showChartValues: true,
          showChartValuesInPercentage: false,
          showChartValuesOutside: false,
          decimalPlaces: 0,
        ),
        // gradientList: ---To add gradient colors---
        // emptyColorGradient: ---Empty Color gradient---
      ),
    );
  }
}
