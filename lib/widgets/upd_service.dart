//lib/widgets/upd_service.dart
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

  UdpService({required this.onTimerCommandReceived});

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
    }
  }

  void dispose() {
    _udp?.close();
  }

  void _processMessage(String message) {
    if (message.startsWith('/timer')) {
      final commaIndex = message.indexOf(',');
      if (commaIndex != -1 && message.length > commaIndex + 2) {
        var timeString = message.substring(commaIndex + 2).trim();
        // Remove null characters from timeString
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
}