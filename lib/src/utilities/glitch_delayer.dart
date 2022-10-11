// ignore_for_file: public_member_api_docs

import 'package:rohd/rohd.dart';

class GlitchDelayer {
  final void Function() _toExecute;

  final Set<Logic> _toWait = {};
  final List<Logic> _toPrePut = [];

  // bool _anyChanges = false;

  GlitchDelayer(List<Logic> toListen, this._toExecute, List<Logic> toPrePut) {
    addToListen(toListen, toPrePut);

    //TODO: ditch this
    Simulator.registerEndOfSimulationAction(() {
      if (_toWait.isNotEmpty) {
        throw Exception('GlitchDelayer is still waiting!');
      }
    });
  }

  void addToListen(List<Logic> moreToListen, List<Logic> toPrePut) {
    for (final logic in moreToListen) {
      logic.preGlitch.listen((args) {
        _toWait.add(logic);
        for (final downstreamSignal in toPrePut) {
          downstreamSignal.prePut();
        }
      });
      logic.glitch.listen((args) {
        _toWait.remove(logic);
        // _anyChanges |= args.newValue != args.previousValue;
        // if (_toWait.isEmpty && _anyChanges) {
        if (_toWait.isEmpty) {
          _toExecute();
          // _anyChanges = false;
        } else {
          // print('waiting'); //TODO ditch this
        }
      });
    }
  }
}
