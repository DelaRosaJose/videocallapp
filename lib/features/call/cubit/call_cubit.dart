import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:videocallapp/data/services/signaling_firebase_service.dart';
import 'package:videocallapp/features/call/cubit/call_state.dart';

class CallCubit extends Cubit<CallState> {
  CallCubit(this._signalingRepository) : super(CallInitial());

  final SignalingFirebaseService _signalingRepository;

  RTCPeerConnection? _peerConnection;

  Future<void> createCall() async {
    emit(CallConnecting());
    try {
      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      };

      //Creamos nuestra conexion local
      _peerConnection = await createPeerConnection(configuration);

      //Creamos la oferta SDP
      final offer = await _peerConnection!.createOffer();

      //Configuramos la oferta localmente
      await _peerConnection!.setLocalDescription(offer);

      //Enviamos la oferta al servidor y obtenemos el ID de la sala
      final roomId = await _signalingRepository.createRoomAndSendOffer(
        offer.toMap(),
      );

      emit(CallInitial());
    } catch (e) {
      emit(CallFailure(e.toString()));
    }
  }
}
