import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide queue for "optimistic with Undo" writes (e.g. T&A "Done today").
///
/// An entry is committed exactly once, whichever comes first:
/// * the Undo snackbar closes without Undo (the screen calls [commit]),
/// * its safety timer fires (snackbar never closed, e.g. route popped mid-way),
/// * the owning screen is disposed ([flush] from `dispose`),
/// * the app goes to background / is being closed (lifecycle observer).
/// Only an explicit Undo ([cancel]) drops it — a pending write is never silently lost.
class PendingCommitQueue with WidgetsBindingObserver {
  PendingCommitQueue() {
    WidgetsBinding.instance.addObserver(this);
  }

  final Map<Object, _Entry> _entries = {};

  bool isPending(Object key) => _entries.containsKey(key);

  /// Queues [commit] under [key]; it runs by [timeout] at the latest.
  void schedule(Object key, Future<void> Function() commit, {Duration timeout = const Duration(seconds: 6)}) {
    _entries.remove(key)?.timer.cancel();
    _entries[key] = _Entry(commit, Timer(timeout, () => this.commit(key)));
  }

  /// Undo: drops the entry without running it. Returns false if it already committed.
  bool cancel(Object key) {
    final entry = _entries.remove(key);
    entry?.timer.cancel();
    return entry != null;
  }

  /// Runs the entry now (no-op if already committed or cancelled).
  Future<void> commit(Object key) async {
    final entry = _entries.remove(key);
    if (entry == null) return;
    entry.timer.cancel();
    await entry.commit();
  }

  /// Commits every pending entry (optionally only those whose key matches [where]).
  Future<void> flush({bool Function(Object key)? where}) async {
    final keys = _entries.keys.where((k) => where == null || where(k)).toList();
    await Future.wait(keys.map(commit));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      flush();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    flush();
  }
}

class _Entry {
  _Entry(this.commit, this.timer);
  final Future<void> Function() commit;
  final Timer timer;
}

final pendingCommitQueueProvider = Provider<PendingCommitQueue>((ref) {
  final queue = PendingCommitQueue();
  ref.onDispose(queue.dispose);
  return queue;
});
