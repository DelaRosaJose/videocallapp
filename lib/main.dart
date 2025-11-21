import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:videocallapp/data/services/signaling_firebase_service.dart';
import 'package:videocallapp/firebase_options.dart';
import 'features/call/cubit/call_cubit.dart';
import 'features/call/view/lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider(create: (_) => SignalingFirebaseService()),
      ],
      child: BlocProvider<CallCubit>(
        create: (context) =>
            CallCubit(context.read<SignalingFirebaseService>()),

        child: MaterialApp(
          title: 'Video Call App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const LobbyScreen(),
        ),
      ),
    );
  }
}
