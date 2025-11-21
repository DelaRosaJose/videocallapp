import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para el portapapeles
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:videocallapp/features/call/cubit/call_cubit.dart';
import 'package:videocallapp/features/call/cubit/call_state.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam, color: Colors.white),
                        Text(
                          "ID: ${state.roomId}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox.shrink(),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.all(0),
                          ),
                          child: const Icon(Icons.copy, color: Colors.white),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: state.roomId),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("ID copiado al portapapeles"),
                              ),
                            );
                          },
                        ),
                      ],
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: "mute_btn",
                        backgroundColor: Colors.white24,
                        onPressed: () {},
                        child: const Icon(Icons.mic, color: Colors.white),
                      ),

                      FloatingActionButton(
                        heroTag: "hangup_btn",
                        backgroundColor: Colors.red,
                        onPressed: () {
                          context.read<CallCubit>().hangUp();
                        },
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),

                      if (Platform.isAndroid || Platform.isIOS)
                        FloatingActionButton(
                          heroTag: "switch_camera_btn",
                          backgroundColor: Colors.white24,
                          onPressed: () {
                            context.read<CallCubit>().switchMobileCamera();
                          },
                          child: const Icon(
                            Icons.cameraswitch,
                            color: Colors.white,
                          ),
                        ),
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
