import 'package:flutter/widgets.dart';

import '../models/enums.dart';
import 'l10n_helper.dart';

extension MuscleGroupL10n on MuscleGroup {
  String localizedLabel(BuildContext context) {
    final l = context.l10n;
    return switch (this) {
      MuscleGroup.chest => l.muscleChest,
      MuscleGroup.back => l.muscleBack,
      MuscleGroup.shoulders => l.muscleShoulders,
      MuscleGroup.biceps => l.muscleBiceps,
      MuscleGroup.triceps => l.muscleTriceps,
      MuscleGroup.forearms => l.muscleForearms,
      MuscleGroup.quadriceps => l.muscleQuadriceps,
      MuscleGroup.hamstrings => l.muscleHamstrings,
      MuscleGroup.glutes => l.muscleGlutes,
      MuscleGroup.calves => l.muscleCalves,
      MuscleGroup.core => l.muscleCore,
      MuscleGroup.fullBody => l.muscleFullBody,
      MuscleGroup.cardio => l.muscleCardio,
    };
  }
}

extension EquipmentTypeL10n on EquipmentType {
  String localizedLabel(BuildContext context) {
    final l = context.l10n;
    return switch (this) {
      EquipmentType.barbell => l.equipBarbell,
      EquipmentType.dumbbell => l.equipDumbbell,
      EquipmentType.cable => l.equipCable,
      EquipmentType.machine => l.equipMachine,
      EquipmentType.bodyweight => l.equipBodyweight,
      EquipmentType.benchPress => l.equipBenchPress,
      EquipmentType.latPulldown => l.equipLatPulldown,
      EquipmentType.legExtension => l.equipLegExtension,
      EquipmentType.legCurl => l.equipLegCurl,
      EquipmentType.seatedRow => l.equipSeatedRow,
      EquipmentType.shoulderPress => l.equipShoulderPress,
      EquipmentType.smithMachine => l.equipSmithMachine,
      EquipmentType.chestFly => l.equipChestFly,
      EquipmentType.rowingMachine => l.equipRowingMachine,
      EquipmentType.treadmill => l.equipTreadmill,
      EquipmentType.stationaryBike => l.equipStationaryBike,
      EquipmentType.elliptical => l.equipElliptical,
      EquipmentType.bench => l.equipBench,
      EquipmentType.inclineBench => l.equipInclineBench,
      EquipmentType.dipStation => l.equipDipStation,
      EquipmentType.pullUpBar => l.equipPullUpBar,
      EquipmentType.hyperextensionBench => l.equipHyperextensionBench,
      EquipmentType.preacherCurlBench => l.equipPreacherCurlBench,
    };
  }
}

extension SetTypeL10n on SetType {
  String localizedLabel(BuildContext context) {
    final l = context.l10n;
    return switch (this) {
      SetType.warmup => l.setTypeWarmup,
      SetType.working => l.setTypeWorking,
      SetType.dropset => l.setTypeDropset,
      SetType.failure => l.setTypeFailure,
    };
  }
}
