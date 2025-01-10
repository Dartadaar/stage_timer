// lib/widgets/send_command_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stage_timer/widgets/upd_service.dart';

class SendCommandDialog extends StatefulWidget {
  final UdpService udpService;
  final String initialIpAddress;

  const SendCommandDialog({
    super.key,
    required this.udpService,
    required this.initialIpAddress,
  });

  @override
  State<SendCommandDialog> createState() => _SendCommandDialogState();
}

class _SendCommandDialogState extends State<SendCommandDialog> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ipController.text = widget.initialIpAddress;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _sendMessage(String address, List<dynamic> arguments) {
    final ipAddress = _ipController.text;
    const remotePort = 21600;
    const localhostPort = 12600;

    widget.udpService.sendMessage(ipAddress, remotePort, address, arguments);

    widget.udpService
        .sendMessage('127.0.0.1', localhostPort, address, arguments);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send UDP Command'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: 'IP Address'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(hintText: 'MM:SS'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                LengthLimitingTextInputFormatter(5),
                _TimeFormatter(),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final time = _timeController.text;
                    if (time.isNotEmpty &&
                        time.length == 5 &&
                        time.split(':').length == 2) {
                      _sendMessage('/timer', [time]);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Invalid time format (MM:SS)')),
                      );
                    }
                  },
                  child: const Text('SEND'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _sendMessage('/timer', ['clear']);
                    Navigator.of(context).pop();
                  },
                  child: const Text('SEND CLEAR'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _TimeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Remove any non-digit characters (e.g., existing colons)
    text = text.replaceAll(RegExp(r'\D'), '');

    // Limit to max 4 digits (MMSS)
    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    String newText = '';
    if (text.length >= 3) {
      // Insert colon after the second character
      newText = text.replaceFirstMapped(
        RegExp(r'^(\d{2})(\d+)'),
        (Match m) => '${m.group(1)}:${m.group(2)}',
      );
    } else if (text.isNotEmpty) {
      newText = text;
    }

    // Adjust the selection to the end of the new text
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
