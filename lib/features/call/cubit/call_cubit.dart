import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:videocallapp/data/services/signaling_firebase_service.dart';
import 'package:videocallapp/features/call/cubit/call_state.dart';

class CallCubit extends Cubit<CallState> {
  CallCubit(this._signalingService) : super(CallInitial());

  final SignalingFirebaseService _signalingService;
  String? _roomID = null;

  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  RTCPeerConnection? _peerConnection;

  Future<void> createCall() async {
    emit(CallConnecting());
    try {
      _roomID = generateRoomId();
      await _initializeAndConnect();

      //Creamos la oferta SDP
      final offer = await _peerConnection!.createOffer();

      //Configuramos la oferta localmente
      await _peerConnection!.setLocalDescription(offer);

      //Enviamos la oferta al servidor
      await _signalingService.createRoomAndSendOffer(_roomID!, offer.toMap());

      emit(CallInitial());
    } catch (e) {
      emit(CallFailure(e.toString()));
    }
  }

  Future<void> _initializeAndConnect() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    _setupListeners();

    // 3. Obtener media del usuario.
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    // ... conectar stream al renderer, etc.
  }

  void _setupListeners() {
    // No quitar by: JRuiz, En Web platform hay un bug en la libreria que no permite recibir los ICE candidates, encontramos esta solución en los Issues de flutter-webrtc
    if (kIsWeb) {
      _peerConnection?.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }

    // Escuchamos los ICE
    _peerConnection!.onIceCandidate = (candidate) {
      _signalingService.addIceCandidate(
        roomId: _roomID!,
        candidate: candidate.toMap(),
        isCaller: true, // ¡Importante! Debemos saber quién envía el candidato.
      );
    };

    // SETEAMOS EL LISTENER DE PISTAS DE VIDEO/AUDIO
    _peerConnection!.onTrack = (event) {
      print("🛰️ ¡Pista remota recibida!");
      // Lógica para mostrar el video del otro usuario.
    };
  }

  String generateRoomId() {
    var r = Random();
    int randomInt = r.nextInt(900000) + 100000;
    return randomInt.toString();
  }
}
