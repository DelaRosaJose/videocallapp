import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class CallState {
  const CallState();
}

class CallInitial extends CallState {
  const CallInitial();
}

class CallCreatingRoom extends CallState {
  const CallCreatingRoom();
}

class CallInProgress extends CallState {
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;
  final String roomId;

  CallInProgress({
    required this.localRenderer,
    required this.remoteRenderer,
    required this.roomId,
  });
}

class CallConnecting extends CallState {
  const CallConnecting();
}

class CallFailure extends CallState {
  final String errorMessage;

  const CallFailure(this.errorMessage);
}
