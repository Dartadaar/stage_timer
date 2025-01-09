import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:osc/osc.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  String _displayedTime = '--:--';
  int _remainingSeconds = 0;
  Timer? _timer;
  Color _borderColor = Colors.transparent;
  bool _isBlinking = false;
  Timer? _blinkTimer;
  bool _postZeroActive = false;
  Timer? _postZeroTimer;

  RawDatagramSocket? _oscSocket;
  static const int _oscPort = 21600; // Choose a port

  late final AnimationController _blinkAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  late final Animation<double> _blinkAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _blinkAnimationController, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    _initOsc();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkTimer?.cancel();
    _postZeroTimer?.cancel();
    _oscSocket?.close();
    _blinkAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initOsc() async {
    try {
      _oscSocket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, _oscPort);
      debugPrint('OSC Server started on port ${_oscSocket?.port}');

      _oscSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final Datagram? datagram = _oscSocket?.receive();
          if (datagram != null) {
            try {
              final message = OSCMessage.fromBytes(datagram.data);
              if (message.address == '/timer') {
                if (message.arguments.isNotEmpty &&
                    message.arguments[0] is String) {
                  final timeString = message.arguments[0] as String;
                  final parts = timeString.split(':');
                  if (parts.length == 2) {
                    final minutes = int.tryParse(parts[0]);
                    final seconds = int.tryParse(parts[1]);
                    if (minutes != null && seconds != null) {
                      _startTimer(minutes * 60 + seconds);
                    } else {
                      debugPrint('Invalid time format: $timeString');
                    }
                  } else {
                    debugPrint('Invalid argument format: $timeString');
                  }
                } else {
                  debugPrint('Invalid OSC message format: $message');
                }
              }
            } catch (e) {
              debugPrint('Error parsing OSC message: $e');
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing OSC: $e');
    }
  }

  void _startTimer(int totalSeconds) {
    setState(() {
      _timer?.cancel();
      _postZeroTimer?.cancel();
      _isBlinking = false;
      _blinkAnimationController.stop();
      _postZeroActive = false;
      _borderColor = Colors.transparent;
      _remainingSeconds = totalSeconds;
      _displayedTime = _formatTime(_remainingSeconds);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _displayedTime = _formatTime(_remainingSeconds);
          if (_remainingSeconds <= 60 && _borderColor != Colors.yellow) {
            _borderColor = Colors.yellow;
          }
          if (_remainingSeconds <= 15 && _borderColor != Colors.red) {
            _borderColor = Colors.red;
          }
        });
      } else {
        _timer?.cancel();
        _triggerZeroReached();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(1, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _triggerZeroReached() {
    setState(() {
      _displayedTime = '0:00';
      _borderColor = Colors.red;
      _isBlinking = true;
    });
    _blinkAnimationController.repeat();

    Future.delayed(const Duration(milliseconds: 500 * 3 * 2), () {
      // 3 blinks
      _blinkAnimationController.stop();
      setState(() {
        _isBlinking = false;
      });
      _startPostZeroTimer();
    });
  }

  void _startPostZeroTimer() {
    setState(() {
      _postZeroActive = true;
    });
    _postZeroTimer = Timer(const Duration(minutes: 1), () {
      setState(() {
        _displayedTime = '--:--';
        _borderColor = Colors.transparent;
        _postZeroActive = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AnimatedOpacity(
              opacity: _isBlinking ? _blinkAnimation.value : 1.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                _displayedTime,
                style: const TextStyle(
                  fontSize: 200,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _borderColor,
                  width: 40.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
