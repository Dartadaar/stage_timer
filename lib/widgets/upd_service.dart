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

  Future<void> sendMessage(String ipAddress, int port, String address,
      List<dynamic> arguments) async {
    try {
      final data = _buildOscMessage(address, arguments);
      final receiverEndpoint =
          Endpoint.unicast(InternetAddress(ipAddress), port: Port(port));
      final sendResult = await _udp?.send(data, receiverEndpoint);
      debugPrint('Sent OSC message to $ipAddress:$port. Result: $sendResult');
    } catch (e) {
      debugPrint('Error sending UDP message: $e');
    }
  }

  Uint8List _buildOscMessage(String address, List<dynamic> arguments) {
    final byteList = <int>[];

    // Build Address Pattern
    final addressBytes = utf8.encode(address);
    byteList.addAll(addressBytes);
    final addressPadding = (4 - (addressBytes.length % 4)) % 4;
    byteList.addAll(List.filled(addressPadding, 0));

    // Build Type Tag String
    String typeTagString = ',';
    for (var arg in arguments) {
      if (arg is int) {
        typeTagString += 'i';
      } else if (arg is double) {
        typeTagString += 'f';
      } else if (arg is String) {
        typeTagString += 's';
      } else if (arg is Uint8List) {
        typeTagString += 'b';
      } else {
        throw Exception('Unsupported argument type: ${arg.runtimeType}');
      }
    }
    final typeTagBytes = utf8.encode(typeTagString);
    byteList.addAll(typeTagBytes);
    final typeTagPadding = (4 - (typeTagBytes.length % 4)) % 4;
    byteList.addAll(List.filled(typeTagPadding, 0));

    // Add arguments
    for (var arg in arguments) {
      if (arg is int) {
        // 32-bit big-endian
        var buffer = Uint8List(4);
        var bdata = ByteData.view(buffer.buffer);
        bdata.setInt32(0, arg, Endian.big);
        byteList.addAll(buffer);
      } else if (arg is String) {
        // UTF-8 encoded string, null-terminated, padded to multiple of 4 bytes
        var strBytes = utf8.encode(arg);
        byteList.addAll(strBytes);
        byteList.add(0); // null terminator
        final argPadding = (4 - ((strBytes.length + 1) % 4)) % 4;
        byteList.addAll(List.filled(argPadding, 0));
      }
      // Add other argument types if needed
    }

    return Uint8List.fromList(byteList);
  }
}
