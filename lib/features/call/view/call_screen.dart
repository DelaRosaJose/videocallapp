import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:videocallapp/features/call/cubit/call_cubit.dart';
import 'package:videocallapp/features/call/cubit/call_state.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  bool get _isMobile {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  Color _getStatusColor(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return const Color(0xFF00E676);
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        return const Color(0xFFFFEA00);
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return const Color(0xFFFF1744);
    }
  }

  String _getStatusText(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return "Conectado";
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        return "En espera...";
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return "Falló";
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return "Desconectado";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<CallCubit, CallState>(
        listener: (context, state) {
          if (state is CallInitial) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("La conexion ha sido cerrada.")),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state is CallInProgress) {
            final mainRenderer = state.isSwapped
                ? state.localRenderer
                : state.remoteRenderer;
            final smallRenderer = state.isSwapped
                ? state.remoteRenderer
                : state.localRenderer;

            return Stack(
              children: [
                Positioned.fill(
                  child: RTCVideoView(
                    mainRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),

                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "ID: ${state.roomId}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: state.roomId),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("ID copiado")),
                                  );
                                },
                                child: const Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          BlocSelector<
                            CallCubit,
                            CallState,
                            RTCPeerConnectionState
                          >(
                            selector: (state) => (state is CallInProgress)
                                ? state.connectionState
                                : RTCPeerConnectionState
                                      .RTCPeerConnectionStateNew,
                            builder: (context, connectionState) {
                              final color = _getStatusColor(connectionState);
                              final text = _getStatusText(connectionState);

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    text,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 20,
                  bottom: 100,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.read<CallCubit>().toggleCameraView(),
                      child: Container(
                        height: 160,
                        width: 110,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 10),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: RTCVideoView(
                            smallRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    spacing: 30,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: "mute_btn",
                        backgroundColor: state.isMuted
                            ? Colors.white
                            : Colors.white24,
                        onPressed: () {
                          context.read<CallCubit>().toggleMute();
                        },
                        child: Icon(
                          state.isMuted ? Icons.mic_off : Icons.mic,
                          color: state.isMuted ? Colors.black : Colors.white,
                        ),
                      ),

                      FloatingActionButton(
                        heroTag: "hangup_btn",
                        backgroundColor: Colors.red,
                        onPressed: () {
                          context.read<CallCubit>().hangUp();
                        },
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),

                      _isMobile
                          ? FloatingActionButton(
                              heroTag: "switch_camera_btn",
                              backgroundColor: Colors.white24,
                              onPressed: () {
                                context.read<CallCubit>().switchMobileCamera();
                              },
                              child: const Icon(
                                Icons.cameraswitch,
                                color: Colors.white,
                              ),
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
