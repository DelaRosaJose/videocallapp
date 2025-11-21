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
  final bool isSwapped;
  final bool isFrontCamera;
  final bool isMuted;

  const CallInProgress({
    required this.localRenderer,
    required this.remoteRenderer,
    required this.roomId,
    this.isSwapped = false,
    this.isFrontCamera = true,
    this.isMuted = false,
  });

  CallInProgress copyWith({
    RTCVideoRenderer? localRenderer,
    RTCVideoRenderer? remoteRenderer,
    String? roomId,
    bool? isSwapped,
    bool? isFrontCamera,
    bool? isMuted,
  }) {
    return CallInProgress(
      localRenderer: localRenderer ?? this.localRenderer,
      remoteRenderer: remoteRenderer ?? this.remoteRenderer,
      roomId: roomId ?? this.roomId,
      isSwapped: isSwapped ?? this.isSwapped,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class CallConnecting extends CallState {
  const CallConnecting();
}

class CallFailure extends CallState {
  final String errorMessage;

  const CallFailure(this.errorMessage);
}
