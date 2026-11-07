import 'package:flutter_test/flutter_test.dart';
import 'package:my_stream/models/player_state.dart';

void main() {
  group('ProcessingState Enum', () {
    test('contains all expected states', () {
      expect(ProcessingState.values, [
        ProcessingState.idle,
        ProcessingState.loading,
        ProcessingState.buffering,
        ProcessingState.ready,
        ProcessingState.completed,
      ]);
    });
  });

  group('PlayerState Model', () {
    test('equality and hashCode work properly', () {
      const state1 = PlayerState(true, ProcessingState.ready);
      const state2 = PlayerState(true, ProcessingState.ready);
      const state3 = PlayerState(false, ProcessingState.ready);
      const state4 = PlayerState(true, ProcessingState.completed);

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));

      expect(state1, isNot(equals(state3)));
      expect(state1, isNot(equals(state4)));
    });

    test('toString returns informative string', () {
      const state = PlayerState(true, ProcessingState.loading);
      expect(
        state.toString(),
        'PlayerState(playing: true, processingState: ProcessingState.loading)',
      );
    });
  });
}
