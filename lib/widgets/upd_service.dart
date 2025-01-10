// lib/widgets/upd_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:udp/udp.dart';

class UdpService {
  UDP? _udp;
  Endpoint? _udpEndpoint;
  static const int _oscPort = 21600; // Choose a port

  final Function(int) onTimerCommandReceived;
  final VoidCallback onTimerClearCommandReceived;

  UdpService({
    required this.onTimerCommandReceived,
    required this.onTimerClearCommandReceived,
  });

  Future<void> init() async {
    try {
      _udpEndpoint = Endpoint.any(port: Port(_oscPort));
      _udp = await UDP.bind(_udpEndpoint!);
      debugPrint('UDP server started on port $_oscPort');

      _udp?.asStream().listen((Datagram? datagram) {
        if (datagram != null) {
          final messageBytes = datagram.data;
          debugPrint('Received message: $messageBytes');
          final String message = utf8.decode(datagram.data);
          _processMessage(message);
        }
      });
    } catch (e) {
      debugPrint('Error initializing UDP: $e');
      // Consider showing an error dialog to the user if UDP fails to initialize.
    }
  }

  void dispose() {
    _udp?.close();
  }

  void _processMessage(String message) {
    if (message == '/timer\x00\x00,s\x00\x00clear\x00\x00\x00') {
      onTimerClearCommandReceived();
    } else if (message.startsWith('/timer')) {
      final commaIndex = message.indexOf(',');
      if (commaIndex != -1 && message.length > commaIndex + 2) {
        var timeString = message.substring(commaIndex + 2).trim();
        timeString = timeString.replaceAll('\u0000', '');
        final parts = timeString.split(':');
        if (parts.length == 2) {
          final minutes = int.tryParse(parts[0]);
          final seconds = int.tryParse(parts[1]);
          if (minutes != null && seconds != null) {
            onTimerCommandReceived(minutes * 60 + seconds);
          } else {
            debugPrint('Invalid time format in UDP message: $message');
          }
        } else {
          debugPrint('Invalid argument format in UDP message: $message');
        }
      } else {
        debugPrint('Invalid OSC message format: $message');
      }
    } else {
      debugPrint('Received unknown UDP message: $message');
    }
  }

  Future<void> sendMessage(String ipAddress, int port, String message) async {
    try {
      final data = utf8.encode(message);
      final receiverEndpoint =
          Endpoint.unicast(InternetAddress(ipAddress), port: Port(port));
      final sendResult = await _udp?.send(data, receiverEndpoint);
      debugPrint('Sent "$message" to $ipAddress:$port. Result: $sendResult');
    } catch (e) {
      debugPrint('Error sending UDP message: $e');
    }
  }
}
