import 'dart:core';

import 'package:rohd/rohd.dart';

class StateMachine<StateIdentifier> {
  List<State<StateIdentifier>> states;

  final Map<StateIdentifier, State> _stateLookup = {};

  final Logic clk, reset;
  final StateIdentifier resetState;

  StateMachine(this.clk, this.reset, this.resetState, this.states) {
    for (var state in states) {
      _stateLookup[state.identifier] = state;
    }

    for (var state in states) {
      Case()
      If()
      Combinational([If("currentState == state", then: state.actions)]);
    }

    Combinational([]);
    Sequential(clk, []);
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

void main() {
  Logic a = Logic(), b = Logic(), c = Logic();
  Logic clk = Logic(), reset  = Logic();
  var states = [
    State<MyStates>(MyStates.state1, events: {
      a: MyStates.state2,
      ~a: MyStates.state3
    }, actions: [
      b < c,
    ])
  ];
  StateMachine<MyStates>(clk, reset, MyStates.state1, states);
  Map dict = {
    'STATE1': {
      'events': {'a': 'STATE2', '~a': 'STATE3'},
      'actions': [
        'b < c',
      ]
    }
  };

  var obj = StateMachine(dict);
  obj.nextState('STATE1', 'a');
}
