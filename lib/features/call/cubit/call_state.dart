abstract class CallState {
  const CallState();
}

class CallInitial extends CallState {
  const CallInitial();
}

class CallConnecting extends CallState {
  const CallConnecting();
}

class CallFailure extends CallState {
  final String errorMessage;

  const CallFailure(this.errorMessage);
}
