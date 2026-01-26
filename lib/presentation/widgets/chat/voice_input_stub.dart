import 'dart:async';

/// Stub implementation for non-web platforms
/// Voice input is only supported on web

class VoiceResult {
  final String transcript;
  final bool isFinal;
  VoiceResult(this.transcript, this.isFinal);
}

bool isVoiceInputSupported() => false;

void initVoiceInput() {}

void startVoiceInput() {}

void stopVoiceInput() {}

Stream<VoiceResult> get onVoiceResult => const Stream.empty();

Stream<String> get onVoiceError => const Stream.empty();

Stream<String> get onVoiceStateChange => const Stream.empty();
