/// Copyright (C) 2021 Intel Corporation
/// SPDX-License-Identifier: BSD-3-Clause
///
/// synchronous_propogator.dart
/// Ultra light-weight events for signal propogation
///
/// 2021 August 3
/// Author: Max Korbel <max.korbel@intel.com>
///

//TODO: a way to only propagate execution of downstream logic
// once all values from the output of a sequential have completed
// maybe a special phase of the simulation just for sequential outputs
// to all come to an agreement?
// how about a two-phase glitch, so you can either listen to glitch
// or you can listen to first and second phase, then only eval on second?
// should try to *measure* how many unnecessary reg-litches there are
// there should be a prePut, to notify downstream listeners that a put is
// coming and not to execute until it has received it; then its optional
// to implement it!  need to make a utility that can set that up for you.
// need a separate putComplete notification, in case put does nothing.
// the preputs need to propagate first deeply to get any value
// combinational blocks need to propagate anyways instantly for functionality
// i guess only need it for combinational block signals that LOOP?
// need to immediately cancel if a loop is detected to prevent deadlock
// can we just only put this on sequential and still get a benefit?
// this only matters on multi-output things
// combinational *can* use this I think, as long as it doesnt *generate* it

/// A controller for a [SynchronousEmitter] that allows for
/// adding of events of type [T] to be emitted.
class SynchronousPropagator<T> {
  /// The [SynchronousEmitter] which sends events added to this.
  SynchronousEmitter<T> get emitter => _emitter;
  final SynchronousEmitter<T> _emitter = SynchronousEmitter<T>();

  /// When set to `true`, will throw an exception if an event
  /// added is reentrant.
  bool throwOnReentrance = false;

  /// Adds a new event [t] to be emitted from [emitter].
  void add(T t) {
    if (throwOnReentrance && _emitter.isEmitting) {
      throw Exception('Disallowed reentrance occurred.');
    }
    _emitter._propagate(t);
  }
}

/// A stream of events of type [T] that can be synchronously listened to.
class SynchronousEmitter<T> {
  /// Registers a new listener [f] to be notified with an event of
  /// type [T] as an argument whenever that event is to be emitted.
  void listen(void Function(T args) f) => _actions.add(f);

  /// A [List] of actions to perform for each event.
  final List<void Function(T)> _actions = <void Function(T)>[];

  /// Returns `true` iff this is currently emitting.
  ///
  /// Useful for reentrance checking.
  bool get isEmitting => _isEmitting;
  bool _isEmitting = false;

  /// Sends out [t] to all listeners.
  void _propagate(T t) {
    _isEmitting = true;
    for (final action in _actions) {
      action(t);
    }
    _isEmitting = false;
  }
}
