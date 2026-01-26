import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation for voice input using Web Speech API

class VoiceResult {
  final String transcript;
  final bool isFinal;
  VoiceResult(this.transcript, this.isFinal);
}

// Stream controllers
final StreamController<VoiceResult> _resultController =
    StreamController<VoiceResult>.broadcast();
final StreamController<String> _errorController =
    StreamController<String>.broadcast();
final StreamController<String> _stateController =
    StreamController<String>.broadcast();

Stream<VoiceResult> get onVoiceResult => _resultController.stream;
Stream<String> get onVoiceError => _errorController.stream;
Stream<String> get onVoiceStateChange => _stateController.stream;

bool _initialized = false;

/// Check if voice input is supported
bool isVoiceInputSupported() {
  try {
    final result = _evalJs('typeof window.VoiceInput !== "undefined" && window.VoiceInput.isSupported');
    return result == 'true';
  } catch (e) {
    return false;
  }
}

/// Initialize voice input
void initVoiceInput() {
  if (_initialized) return;

  try {
    // Set up JavaScript callbacks
    _evalJs('''
      window.VoiceInput.setCallbacks(
        function(transcript, isFinal) {
          window._voiceResultCallback && window._voiceResultCallback(transcript, isFinal);
        },
        function(error) {
          window._voiceErrorCallback && window._voiceErrorCallback(error);
        },
        function(state) {
          window._voiceStateCallback && window._voiceStateCallback(state);
        }
      );
    ''');

    // Set up Dart callbacks via JavaScript global functions
    _setupDartCallbacks();

    _initialized = true;
  } catch (e) {
    _errorController.add('音声入力の初期化に失敗しました');
  }
}

void _setupDartCallbacks() {
  // We'll poll for results using a timer since direct callback setup is complex
  // Instead, use JavaScript events through window properties

  // Create a polling mechanism
  Timer.periodic(const Duration(milliseconds: 100), (timer) {
    try {
      // Check for pending result
      final hasResult = _evalJs('window._pendingVoiceResult !== undefined');
      if (hasResult == 'true') {
        final transcript = _evalJs('window._pendingVoiceResult.transcript || ""');
        final isFinal = _evalJs('window._pendingVoiceResult.isFinal === true') == 'true';
        _evalJs('window._pendingVoiceResult = undefined');

        if (transcript.isNotEmpty) {
          _resultController.add(VoiceResult(transcript, isFinal));
        }
      }

      // Check for pending error
      final hasError = _evalJs('window._pendingVoiceError !== undefined');
      if (hasError == 'true') {
        final error = _evalJs('window._pendingVoiceError || ""');
        _evalJs('window._pendingVoiceError = undefined');

        if (error.isNotEmpty) {
          _errorController.add(error);
        }
      }

      // Check for pending state
      final hasState = _evalJs('window._pendingVoiceState !== undefined');
      if (hasState == 'true') {
        final state = _evalJs('window._pendingVoiceState || ""');
        _evalJs('window._pendingVoiceState = undefined');

        if (state.isNotEmpty) {
          _stateController.add(state);
        }
      }
    } catch (e) {
      // Ignore polling errors
    }
  });
}

/// Start voice recognition
void startVoiceInput() {
  try {
    _evalJs('window.VoiceInput.start()');
  } catch (e) {
    _errorController.add('音声入力を開始できませんでした');
  }
}

/// Stop voice recognition
void stopVoiceInput() {
  try {
    _evalJs('window.VoiceInput.stop()');
  } catch (e) {
    // Ignore stop errors
  }
}

/// Evaluate JavaScript code and return result as string
String _evalJs(String code) {
  try {
    final result = web.window.eval(code.toJS);
    return result?.toString() ?? '';
  } catch (e) {
    return '';
  }
}

extension on web.Window {
  external JSAny? eval(JSString code);
}
