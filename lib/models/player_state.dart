enum ProcessingState {
  idle,
  loading,
  buffering,
  ready,
  completed,
}

class PlayerState {
  final bool playing;
  final ProcessingState processingState;

  const PlayerState(this.playing, this.processingState);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerState &&
          runtimeType == other.runtimeType &&
          playing == other.playing &&
          processingState == other.processingState;

  @override
  int get hashCode => Object.hash(playing, processingState);

  @override
  String toString() =>
      'PlayerState(playing: $playing, processingState: $processingState)';
}
