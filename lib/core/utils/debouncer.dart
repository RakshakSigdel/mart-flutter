import 'dart:async';

/// Delays a callback until [duration] has passed without another call —
/// the standard "wait for the user to stop typing" pattern for live search.
///
/// ```dart
/// final _debouncer = Debouncer();
///
/// void _onSearchChanged(String value) {
///   _debouncer.run(() => _controller.submitSearch());
/// }
/// ```
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 400)});

  final Duration duration;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}
