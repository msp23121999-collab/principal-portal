import 'package:flutter/material.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../models/examination.dart';

/// Maps an [ExamStage] onto the shared [StatusChip] palette so exam
/// states read the same as every other status badge in the portal.
class ExamStageChip extends StatelessWidget {
  const ExamStageChip({super.key, required this.stage});

  final ExamStage stage;

  AppStatus get _status {
    switch (stage) {
      case ExamStage.scheduled:
        return AppStatus.info;
      case ExamStage.inProgress:
        return AppStatus.pending;
      case ExamStage.completed:
        return AppStatus.active;
      case ExamStage.evaluated:
        return AppStatus.approved;
      case ExamStage.published:
        return AppStatus.passed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusChip(status: _status, customLabel: stage.label);
  }
}
