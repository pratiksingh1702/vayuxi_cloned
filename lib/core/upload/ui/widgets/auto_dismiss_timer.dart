import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/upload_job.dart';

class AutoDismissTimer extends StatefulWidget {
  final UploadJob job;
  final VoidCallback onStop;
  final VoidCallback onDismiss;

  const AutoDismissTimer({
    super.key,
    required this.job,
    required this.onStop,
    required this.onDismiss,
  });

  @override
  State<AutoDismissTimer> createState() => _AutoDismissTimerState();
}

class _AutoDismissTimerState extends State<AutoDismissTimer> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(AutoDismissTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.job.autoDismissAt != oldWidget.job.autoDismissAt) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.job.autoDismissAt == null) {
      setState(() => _secondsLeft = 0);
      return;
    }

    _updateSeconds();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateSeconds();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateSeconds() {
    if (widget.job.autoDismissAt == null) {
      _timer?.cancel();
      return;
    }

    final diff = widget.job.autoDismissAt!.difference(DateTime.now());
    final seconds = diff.inSeconds;

    if (seconds <= 0) {
      _timer?.cancel();
      setState(() => _secondsLeft = 0);
    } else {
      setState(() => _secondsLeft = seconds);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.job.autoDismissAt == null || _secondsLeft <= 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${_secondsLeft}s',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              decoration: TextDecoration.none,
            ),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: widget.onDismiss,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Icon(
              Icons.close,
              color: Colors.white.withOpacity(0.5),
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}
