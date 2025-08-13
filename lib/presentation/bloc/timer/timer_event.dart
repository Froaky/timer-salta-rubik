import 'package:equatable/equatable.dart';

abstract class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object> get props => [];
}

class TimerStartHold extends TimerEvent {
  const TimerStartHold();
}

class TimerStopHold extends TimerEvent {
  const TimerStopHold();
}

class TimerTick extends TimerEvent {
  const TimerTick();
}

class TimerStart extends TimerEvent {
  const TimerStart();
}

class TimerStop extends TimerEvent {
  const TimerStop();
}

class TimerReset extends TimerEvent {
  const TimerReset();
}