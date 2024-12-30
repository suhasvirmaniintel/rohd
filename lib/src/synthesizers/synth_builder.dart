// Copyright (C) 2021-2023 Intel Corporation
// SPDX-License-Identifier: BSD-3-Clause
//
// synth_builder.dart
// Definition for something that builds synthesis of a module hierarchy
//
// 2021 August 26
// Author: Max Korbel <max.korbel@intel.com>

import 'package:collection/collection.dart';
import 'package:rohd/rohd.dart';
import 'package:rohd/src/utilities/sanitizer.dart';
import 'package:rohd/src/utilities/uniquifier.dart';

/// A generic class which can convert a module into a generated output using
/// a [Synthesizer].
class SynthBuilder {
  /// The top-level [Module] to be synthesized.
  final Module top;

  /// The [Synthesizer] to use for generating an output.
  final Synthesizer synthesizer;

  /// A [Map] from instances of [Module]s to the type that should represent
  /// them in the synthesized output.
  final Map<Module, String> _moduleToInstanceTypeMap = {};

  /// All the [SynthesisResult]s generated by this [SynthBuilder].
  final Set<SynthesisResult> _synthesisResults = {};

  /// All the [SynthesisResult]s generated by this [SynthBuilder].
  Set<SynthesisResult> get synthesisResults =>
      UnmodifiableSetView(_synthesisResults);

  /// [Uniquifier] for instance type names.
  final Uniquifier _instanceTypeUniquifier = Uniquifier();

  //TODO: consider https://github.com/intel/rohd/issues/434

  /// Constructs a [SynthBuilder] based on the [top] module and
  /// using [synthesizer] for generating outputs.
  SynthBuilder(this.top, this.synthesizer) {
    if (!top.hasBuilt) {
      throw ModuleNotBuiltException();
    }

    final modulesToParse = <Module>[top];
    for (var i = 0; i < modulesToParse.length; i++) {
      final moduleI = modulesToParse[i];
      if (!synthesizer.generatesDefinition(moduleI)) {
        continue;
      }
      modulesToParse.addAll(moduleI.subModules);
    }

    // go backwards to start from the bottom (...now we're here)
    // critical to go in this order for caching to work properly
    modulesToParse.reversed
        .where(synthesizer.generatesDefinition)
        .forEach(_getInstanceType);
  }

  /// Collects a [List] of [String]s representing file contents generated by
  /// the [synthesizer].
  List<SynthFileContents> getFileContents() => synthesisResults
      .map((synthesisResult) => synthesisResult.toFileContents())
      .flattened
      .toList(growable: false);

  /// Provides an instance type name for [module].
  ///
  /// If a name already exists for [module], it will return the same one.
  /// If another [Module] is equivalent (as determined by comparing the
  /// [SynthesisResult]s), they will both get the same name.
  String _getInstanceType(Module module) {
    if (!synthesizer.generatesDefinition(module)) {
      return '*NONE*';
    }

    if (_moduleToInstanceTypeMap.containsKey(module)) {
      return _moduleToInstanceTypeMap[module]!;
    }
    var newName = module.definitionName;

    final newSynthesisResult = synthesizer.synthesize(module, _getInstanceType);
    if (_synthesisResults.contains(newSynthesisResult)) {
      // a name for this module already exists
      newName = _moduleToInstanceTypeMap[
          _synthesisResults.lookup(newSynthesisResult)!.module]!;
    } else {
      _synthesisResults.add(newSynthesisResult);
      newName = _instanceTypeUniquifier.getUniqueName(
          initialName: newName, reserved: module.reserveDefinitionName);
    }

    assert(Sanitizer.isSanitary(newName),
        'Module definition names should be sanitary.');

    _moduleToInstanceTypeMap[module] = newName;

    // add any required supporting modules to be synthesized
    newSynthesisResult.supportingModules?.forEach(_getInstanceType);

    return newName;
  }
}
