import 'dart:async';
import 'dart:js_interop';

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
JSFunction? _resultCallback;
JSFunction? _errorCallback;
JSFunction? _stateCallback;

/// Check if voice input is supported
bool isVoiceInputSupported() {
  try {
    return _voiceInput?.isSupported ?? false;
  } catch (e) {
    return false;
  }
}

/// Initialize voice input
void initVoiceInput() {
  if (_initialized) return;

  try {
    final api = _voiceInput;
    if (api == null) return;
    _resultCallback = ((String transcript, bool isFinal) {
      if (transcript.isNotEmpty) {
        _resultController.add(VoiceResult(transcript, isFinal));
      }
    }).toJS;
    _errorCallback = ((String error) {
      if (error.isNotEmpty) {
        _errorController.add(error);
      }
    }).toJS;
    _stateCallback = ((String state) {
      if (state.isNotEmpty) {
        _stateController.add(state);
      }
    }).toJS;
    api.setCallbacks(_resultCallback!, _errorCallback!, _stateCallback!);
    _initialized = true;
  } catch (e) {
    _errorController.add('音声入力の初期化に失敗しました');
  }
}

/// Start voice recognition
void startVoiceInput() {
  try {
    _voiceInput?.start();
  } catch (e) {
    _errorController.add('音声入力を開始できませんでした');
  }
}

/// Stop voice recognition
void stopVoiceInput() {
  try {
    _voiceInput?.stop();
  } catch (e) {
    // Ignore stop errors
  }
}

@JS('VoiceInput')
external VoiceInputApi? get _voiceInput;

@JS()
@staticInterop
class VoiceInputApi {}

extension VoiceInputApiExtension on VoiceInputApi {
  external bool get isSupported;
  external void setCallbacks(
    JSFunction onResult,
    JSFunction onError,
    JSFunction onStateChange,
  );
  external bool start();
  external void stop();
}
