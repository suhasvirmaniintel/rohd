import 'dart:core';

class StateMachine {
  Map dict;

  StateMachine(this.dict);

  void test() {
    print(dict);
  }

  void nextState(String currentState, String event) {
    if (dict[currentState]['events'].containsKey(event)) {
      print(dict[currentState]['events'][event]);
    }
  }
}

void main() {
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
