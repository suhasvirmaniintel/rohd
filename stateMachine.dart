import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:rohd/rohd.dart';
import 'dart:math';

class StateMachine<StateIdentifier> {
  List<State<StateIdentifier>> states;

  final Map<StateIdentifier, State> _stateLookup = {};
  final Map<State, int> _stateValueLookup = {};

  final Logic clk, reset;
  final StateIdentifier resetState;

  /// The current state of the FSM.
  final Logic currentState;

  final Logic nextState;

  static int logBase(num x, num base) => (log(x) / log(base)).ceil();

  final int stateWidth;

  StateMachine(this.clk, this.reset, this.resetState, this.states)
      : stateWidth = logBase(states.length, 2),
        currentState =
            Logic(name: 'currentState', width: logBase(states.length, 2)),
        nextState = Logic(name: 'nextState', width: logBase(states.length, 2)) {
    var stateCounter = 0;

    //TODO: make sure all states are defined!

    for (var state in states) {
      _stateLookup[state.identifier] = state;
      _stateValueLookup[state] = stateCounter++;
    }

    // Combinational([
    //   Case(
    //       currentState,
    //       states
    //           .map((state) => CaseItem(
    //               Const(_stateValueLookup[_stateLookup[state]],
    //                   width: stateWidth),
    //               state.actions))
    //           .toList(),
    //       conditionalType: ConditionalType.unique)
    // ]);

    Sequential(clk, [
      If(
        reset,
        then: [currentState < _stateValueLookup[_stateLookup[resetState]]],
        orElse: [currentState < nextState],
      )
    ]);
  }

  // void test() {
  //   print(dict);
  // }

  // void nextState(String currentState, String event) {
  //   if (dict[currentState]['events'].containsKey(event)) {
  //     print(dict[currentState]['events'][event]);
  //   }
  // }
}

class State<StateIdentifier> {
  final StateIdentifier identifier;
  final Map<Logic, StateIdentifier> events;
  final List<Conditional> actions;

  State(this.identifier, {required this.events, required this.actions});
}

enum MyStates { state1, state2, state3 }

class TestModule extends Module {
  TestModule(Logic clk, Logic reset) {
    Logic a = Logic(), b = Logic(), c = Logic();
    clk = addInput('clk', clk);
    reset = addInput('reset', reset);
    var states = [
      State<MyStates>(MyStates.state1, events: {
        a: MyStates.state2,
        ~a: MyStates.state3
      }, actions: [
        b < c,
      ]),
      State<MyStates>(MyStates.state2, events: {}, actions: []),
      State<MyStates>(MyStates.state3, events: {}, actions: []),
    ];
    StateMachine<MyStates>(clk, reset, MyStates.state1, states);
  }
}

void main() async {
  var mod = TestModule(Logic(), Logic());
  await mod.build();

  File('tmpfsm.sv').writeAsStringSync(mod.generateSynth());

  // Map dict = {
  //   'STATE1': {
  //     'events': {'a': 'STATE2', '~a': 'STATE3'},
  //     'actions': [
  //       'b < c',
  //     ]
  //   }
  // };

  // var obj = StateMachine(dict);
  // obj.nextState('STATE1', 'a');
}
