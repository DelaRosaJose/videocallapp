import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:videocallapp/features/call/cubit/call_cubit.dart';
import 'package:videocallapp/features/call/cubit/call_state.dart';
import 'package:videocallapp/features/call/view/call_screen.dart';
import '../../../shared_widgets/custom_button.dart';
import '../../../shared_widgets/custom_text_field.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _roomIdController = TextEditingController();

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallCubit, CallState>(
      listenWhen: (previous, current) {
        return previous is! CallInProgress && current is CallInProgress;
      },
      listener: (context, state) {
        if (state is CallInProgress) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<CallCubit>(),
                child: const CallScreen(),
              ),
            ),
          );
        } else if (state is CallFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is CallCreatingRoom) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Creando sala y conectando..."),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Video Call Lobby')),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Crea una llamada o únete con un ID',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                CustomButton(
                  text: 'Crear Llamada',
                  onPressed: () {
                    context.read<CallCubit>().createCall();
                  },
                  color: Colors.blue,
                ),

                const SizedBox(height: 40),
                const Text('O'),
                const SizedBox(height: 40),

                CustomTextField(
                  controller: _roomIdController,
                  hintText: 'Ingresa el ID de la llamada',
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Unirse a Llamada',
                  onPressed: () {
                    final roomId = _roomIdController.text.trim();
                    if (roomId.isNotEmpty) {
                      context.read<CallCubit>().joinCall(roomId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, ingresa un ID de llamada'),
                        ),
                      );
                    }
                  },
                  color: Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
