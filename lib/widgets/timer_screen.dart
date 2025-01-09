//lib/widgets/timer_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stage_timer/widgets/upd_service.dart';

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

  late UdpService _udpService;

  @override
  void initState() {
    super.initState();
    _udpService = UdpService(
      onTimerCommandReceived: _startTimer,
      onTimerClearCommandReceived: _clearTimer, // Pass the new callback
    );
    _udpService.init().then((_) {
      // Show the dialog after UDP service is initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStartupDialog(context);
      });
    });
  }

  void _showStartupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('UDP Port Open'),
          content: const Text(
              'This app is listening for commands on port 21600.\n\nYou can send the following commands:\n- `/timer "mm:ss"` (e.g., /timer "05:00")\n- `/timer clear`'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkTimer?.cancel();
    _postZeroTimer?.cancel();
    _udpService.dispose();
    super.dispose();
  }

  void _startTimer(int totalSeconds) {
    setState(() {
      _resetState(); // Reuse reset logic
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

  void _clearTimer() {
    setState(() {
      _resetState();
      _displayedTime = '--:--';
    });
  }

  void _resetState() {
    _timer?.cancel();
    _postZeroTimer?.cancel();
    _isBlinking = false;
    _blinkTimer?.cancel();
    _postZeroActive = false;
    _borderColor = Colors.transparent;
    _remainingSeconds = 0;
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _triggerZeroReached() {
    setState(() {
      _displayedTime = '00:00';
      _borderColor = Colors.red;
      _isBlinking = true;
    });

    // Start blinking every second
    _blinkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _isBlinking = !_isBlinking;
      });
    });

    // Stop blinking and start post-zero timer after 60 seconds)
    Future.delayed(const Duration(seconds: 60), () {
      _blinkTimer?.cancel();
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
            child: Visibility(
              visible:
                  !_isBlinking, // Show only when not in the "off" blink state
              child: Text(
                _displayedTime,
                style: const TextStyle(
                  fontSize: 200,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: Colors.white, // Ensure text is visible
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: true,
            child: Visibility(
              visible:
                  !_isBlinking, // Show only when not in the "off" blink state
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
          ),
        ],
      ),
    );
  }
}
