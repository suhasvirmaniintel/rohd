// ignore_for_file: avoid_print

import 'package:rohd/rohd.dart';

Future<void> displaySystemVerilog(Module mod) async {
  await mod.build();
  print('\nYour System Verilog Equivalent Code: \n ${mod.generateSynth()}');
}

class AssignmentOperator extends Module {
  AssignmentOperator(Logic a, void Function(Logic a, Logic b) assignment)
      : super(name: 'Assignment') {
    a = addInput('a', a, width: a.width);
    final b = addOutput('b', width: a.width);

    assignment(a, b);
  }
}

class Gate extends Module {
  Logic get c => output('c');
  Gate(Logic a, Logic b, void Function(Logic a, Logic b, Logic c) gate)
      : super(name: 'Assignment') {
    a = addInput('a', a, width: a.width);
    b = addInput('b', b, width: b.width);
    final c = addOutput('c', width: a.width);

    gate(a, b, c);
  }
}
