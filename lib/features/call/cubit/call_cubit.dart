import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:videocallapp/data/services/signaling_firebase_service.dart';
import 'package:videocallapp/features/call/cubit/call_state.dart';

class CallCubit extends Cubit<CallState> {
  CallCubit(this._signalingService) : super(CallInitial());

  final SignalingFirebaseService _signalingService;
  String? _roomID;
  bool _isCaller = true;

  MediaStream? _localStream;

  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;

  StreamSubscription? _roomSubscription;
  StreamSubscription? _candidatesSubscription;

  //Generador de 6 dígitos aleatorios
  String generateRoomId() {
    var r = Random();
    int randomInt = r.nextInt(900000) + 100000;
    return randomInt.toString();
  }

  Future<void> createCall() async {
    try {
      emit(CallCreatingRoom());
      _roomID = generateRoomId();
      await _initializeAndConnect();

      //Creamos la oferta SDP
      final offer = await _peerConnection!.createOffer();

      //Configuramos la oferta localmente
      await _peerConnection!.setLocalDescription(offer);

      //Enviamos la oferta al servidor
      await _signalingService.createRoomAndSendOffer(_roomID!, offer.toMap());

      //Escuhamos los cambios SDP de la sala y los nuevos candidatos ICE
      _startListeningToRoomUpdates();

      emit(
        CallInProgress(
          localRenderer: _localRenderer,
          remoteRenderer: _remoteRenderer,
          roomId: _roomID!,
        ),
      );
    } catch (e) {
      emit(CallFailure(e.toString()));
    }
  }

  //Inicializa WebRTC ( Renderers, Cámara, PeerConnection, Listeners)
  Future<void> _initializeAndConnect() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _peerConnection = await createPeerConnection(configuration);

    _setupListeners();

    // 3. Obtener media del usuario.
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });

    _localRenderer.srcObject = _localStream;

    // Añadimos nuestro video al Track para que le llegue al otro usuario.
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  void _setupListeners() {
    // No quitar by: JRuiz, En Web platform hay un bug en la libreria que no permite recibir los ICE candidates, encontramos esta solución en los Issues de flutter-webrtc
    if (kIsWeb) {
      _peerConnection?.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );
    }

    // Escuchamos los ICE
    _peerConnection!.onIceCandidate = (candidate) {
      _signalingService.addIceCandidate(
        roomId: _roomID!,
        candidate: candidate.toMap(),
        isCaller: _isCaller,
      );
    };

    // SETEAMOS EL LISTENER DE PISTAS DE VIDEO/AUDIO
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        hangUp();
      }
    };

    emit(
      CallInProgress(
        localRenderer: _localRenderer,
        remoteRenderer: _remoteRenderer,
        roomId: _roomID!,
      ),
    );
  }

  Future<void> hangUp() async {
    await _roomSubscription?.cancel();
    // 1. Detener tracks locales
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });

    // Cerramos la conexión
    await _peerConnection?.close();
    _peerConnection = null;
    _peerConnection?.dispose();

    //Limpiamos los Streams
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    _localStream = null;

    emit(const CallInitial());
  }

  Future<void> joinCall(String roomId) async {
    emit(const CallConnecting());
    try {
      _roomID = roomId;
      _isCaller = false;

      // 1. Verificar si la sala existe y obtener la Oferta
      final roomData = await _signalingService.getRoom(roomId);
      if (roomData == null) {
        emit(const CallFailure("La sala no existe"));
        return;
      }

      final offer = roomData['sdp'];
      if (offer == null) {
        emit(const CallFailure("La sala no tiene una oferta válida"));
        return;
      }

      await _initializeAndConnect();

      // Setteamos la oferta enviada por el Caller
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      final answer = await _peerConnection!.createAnswer();

      // Configuramos la respuesta localmente
      await _peerConnection!.setLocalDescription(answer);

      await _signalingService.sendAnswer(roomId, answer.toMap());

      _startListeningToCandidates();

      emit(
        CallInProgress(
          localRenderer: _localRenderer,
          remoteRenderer: _remoteRenderer,
          roomId: _roomID!,
        ),
      );
    } catch (e) {
      emit(CallFailure(e.toString()));
    }
  }

  void _startListeningToRoomUpdates() {
    if (_isCaller == false) return;

    //Escuchamos los cambios de SDP en la sala
    _roomSubscription = _signalingService.getRoomStream(_roomID!).listen((
      snapshot,
    ) async {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['sdp'] != null) {
          final sdp = data['sdp'];
          String type = sdp['type'];

          if (type == 'answer') {
            final currentState = await _peerConnection!.getSignalingState();
            if (currentState ==
                RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
              try {
                await _peerConnection!.setRemoteDescription(
                  RTCSessionDescription(sdp['sdp'], type),
                );
                _startListeningToCandidates();
              } catch (e) {
                rethrow;
              }
            }
          }
        }
      }
    });
  }

  void _startListeningToCandidates() {
    _candidatesSubscription = _signalingService
        .getCandidatesStream(roomId: _roomID!, isCaller: _isCaller)
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                //Agregamos el candidato ICE a la conexión
                _peerConnection!.addCandidate(
                  RTCIceCandidate(
                    data['candidate'],
                    data['sdpMid'],
                    data['sdpMLineIndex'],
                  ),
                );
              }
            }
          }
        });
  }

  void toggleCameraView() {
    final currentState = state;
    if (currentState is CallInProgress) {
      emit(currentState.copyWith(isSwapped: !currentState.isSwapped));
    }
  }
}
