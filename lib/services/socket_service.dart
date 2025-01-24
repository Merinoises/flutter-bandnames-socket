import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:flutter/material.dart';

enum ServerStatus {
  online,
  offline,
  connecting,
}

class SocketService with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.connecting;
  late IO.Socket _socket;

  ServerStatus get serverStatus => _serverStatus;
  
  IO.Socket get socket => _socket;
  get emit => _socket.emit;

  SocketService() {
    _initConfig();
  }

  void _initConfig() {
    _socket = IO.io('http://192.168.1.14:3000', {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      _serverStatus = ServerStatus.online;
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      _serverStatus = ServerStatus.offline;
      notifyListeners();
    });
  }
}
