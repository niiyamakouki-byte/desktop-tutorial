import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

// Conditional import for web
import 'voice_input_stub.dart'
    if (dart.library.html) 'voice_input_web.dart' as voice;

/// Voice input button widget with recording animation
/// Uses Web Speech API for speech-to-text
class VoiceInputButton extends StatefulWidget {
  final Function(String text) onResult;
  final Function(String error)? onError;
  final bool autoSend;
  final bool enabled;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onError,
    this.autoSend = false,
    this.enabled = true,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isListening = false;
  bool _isSupported = false;
  String _interimText = '';

  StreamSubscription? _resultSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkSupport();
  }

  void _checkSupport() {
    if (kIsWeb) {
      _isSupported = voice.isVoiceInputSupported();
      if (_isSupported) {
        voice.initVoiceInput();
        _setupListeners();
      }
    }
    if (mounted) setState(() {});
  }

  void _setupListeners() {
    _resultSubscription = voice.onVoiceResult.listen((result) {
      if (mounted) {
        setState(() {
          _interimText = result.transcript;
        });

        if (result.isFinal) {
          _stopListening();
          widget.onResult(result.transcript);
        }
      }
    });

    _errorSubscription = voice.onVoiceError.listen((error) {
      if (mounted) {
        _stopListening();
        widget.onError?.call(error);
        _showErrorSnackbar(error);
      }
    });

    _stateSubscription = voice.onVoiceStateChange.listen((state) {
      if (mounted) {
        setState(() {
          _isListening = state == 'listening';
        });

        if (_isListening) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    if (!_isSupported) {
      _showErrorSnackbar('このブラウザは音声入力に対応していません');
      return;
    }

    setState(() {
      _interimText = '';
    });

    voice.startVoiceInput();
  }

  void _stopListening() {
    voice.stopVoiceInput();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isListening = false;
    });
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultSubscription?.cancel();
    _errorSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_isSupported) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Interim text display when listening
        if (_isListening && _interimText.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _interimText,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // Mic button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled ? _toggleListening : null,
                  borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? AppColors.error
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: AppColors.error.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening
                          ? Colors.white
                          : widget.enabled
                              ? AppColors.iconDefault
                              : AppColors.textTertiary,
                      size: AppConstants.iconSizeM,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Compact voice input button for inline use
class CompactVoiceButton extends StatefulWidget {
  final Function(String text) onResult;
  final bool enabled;

  const CompactVoiceButton({
    super.key,
    required this.onResult,
    this.enabled = true,
  });

  @override
  State<CompactVoiceButton> createState() => _CompactVoiceButtonState();
}

class _CompactVoiceButtonState extends State<CompactVoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isListening = false;
  bool _isSupported = false;

  StreamSubscription? _resultSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    if (kIsWeb) {
      _isSupported = voice.isVoiceInputSupported();
      if (_isSupported) {
        voice.initVoiceInput();

        _resultSub = voice.onVoiceResult.listen((result) {
          if (result.isFinal && mounted) {
            voice.stopVoiceInput();
            setState(() => _isListening = false);
            _pulseController.stop();
            widget.onResult(result.transcript);
          }
        });

        _stateSub = voice.onVoiceStateChange.listen((state) {
          if (mounted) {
            final listening = state == 'listening';
            setState(() => _isListening = listening);
            if (listening) {
              _pulseController.repeat(reverse: true);
            } else {
              _pulseController.stop();
            }
          }
        });
      }
    }
  }

  void _toggle() {
    if (_isListening) {
      voice.stopVoiceInput();
    } else {
      voice.startVoiceInput();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_isSupported) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return IconButton(
          onPressed: widget.enabled ? _toggle : null,
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? AppColors.error : AppColors.iconDefault,
          ),
          tooltip: _isListening ? '音声入力を停止' : '音声で入力',
          style: IconButton.styleFrom(
            backgroundColor:
                _isListening ? AppColors.error.withOpacity(0.1) : null,
          ),
        );
      },
    );
  }
}
