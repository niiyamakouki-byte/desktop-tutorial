import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// Voice input service using Web Speech API
/// Provides real-time speech-to-text functionality for chat input
class VoiceInputService {
  static final VoiceInputService _instance = VoiceInputService._internal();
  factory VoiceInputService() => _instance;
  VoiceInputService._internal();

  bool _initialized = false;
  VoiceInputState _state = VoiceInputState.idle;

  final StreamController<String> _transcriptController = StreamController<String>.broadcast();
  final StreamController<VoiceInputState> _stateController = StreamController<VoiceInputState>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  final StreamController<String> _finalTranscriptController = StreamController<String>.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<VoiceInputState> get stateStream => _stateController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<String> get finalTranscriptStream => _finalTranscriptController.stream;

  VoiceInputState get state => _state;
  bool get isListening => _state == VoiceInputState.listening;

  /// Check if voice input is supported
  bool get isSupported {
    if (!kIsWeb) return false;
    try {
      return _jsIsSupported();
    } catch (e) {
      return false;
    }
  }

  /// Initialize the voice input service
  void initialize() {
    if (_initialized) return;
    if (!kIsWeb) return;

    try {
      _jsInit();
      _setupCallbacks();
      _initialized = true;
    } catch (e) {
      debugPrint('Voice input initialization failed: $e');
    }
  }

  void _setupCallbacks() {
    _jsSetCallbacks(
      _onResult.toJS,
      _onError.toJS,
      _onStateChange.toJS,
    );
  }

  void _onResult(String transcript, bool isFinal) {
    _transcriptController.add(transcript);
    if (isFinal) {
      _finalTranscriptController.add(transcript);
    }
  }

  void _onError(String error) {
    _errorController.add(error);
    _state = VoiceInputState.error;
    _stateController.add(_state);
  }

  void _onStateChange(String state) {
    switch (state) {
      case 'listening':
        _state = VoiceInputState.listening;
        break;
      case 'idle':
        _state = VoiceInputState.idle;
        break;
      case 'error':
        _state = VoiceInputState.error;
        break;
      default:
        _state = VoiceInputState.idle;
    }
    _stateController.add(_state);
  }

  /// Start voice recognition
  Future<bool> startListening() async {
    if (!kIsWeb) return false;
    if (!_initialized) initialize();

    try {
      return _jsStart();
    } catch (e) {
      _errorController.add('音声入力を開始できませんでした');
      return false;
    }
  }

  /// Stop voice recognition
  void stopListening() {
    if (!kIsWeb) return;
    try {
      _jsStop();
    } catch (e) {
      // Ignore
    }
    _state = VoiceInputState.idle;
    _stateController.add(_state);
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _transcriptController.close();
    _stateController.close();
    _errorController.close();
    _finalTranscriptController.close();
  }
}

/// Voice input states
enum VoiceInputState {
  idle,
  listening,
  processing,
  error,
}

// JavaScript interop
@JS('VoiceInput.isSupported')
external bool _jsIsSupported();

@JS('VoiceInput.init')
external void _jsInit();

@JS('VoiceInput.start')
external bool _jsStart();

@JS('VoiceInput.stop')
external void _jsStop();

@JS('VoiceInput.setCallbacks')
external void _jsSetCallbacks(JSFunction onResult, JSFunction onError, JSFunction onStateChange);

extension on void Function(String, bool) {
  JSFunction get toJS => _createResultCallback(this);
}

extension on void Function(String) {
  JSFunction get toJS => _createStringCallback(this);
}

@JS('eval')
external JSFunction _createResultCallback(void Function(String, bool) callback);

@JS('eval')
external JSFunction _createStringCallback(void Function(String) callback);
