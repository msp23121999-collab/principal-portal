import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/approvals_repository.dart';

/// Tells the Principal what a decision actually did.
///
/// Recording a decision is two writes that cannot share a transaction — the
/// decision itself, then the audit entry. Four screens take decisions
/// (Approvals categories, All Approvals, Leave, and the Dashboard queue) and
/// each used to announce plain success as soon as no exception was thrown, so
/// a decision that applied without reaching the trail was reported as fully
/// recorded on all four.
///
/// The wording is deliberate. It never suggests the decision failed — by the
/// time an outcome exists the decision has taken effect, and inviting the
/// Principal to "try again" would apply it twice. What it says is that the
/// *record* is missing and who needs to know.
void showDecisionResult(
  ScaffoldMessengerState messenger, {
  required String subject,
  required String action,
  required DecisionOutcome outcome,
}) {
  if (outcome.recorded) {
    messenger.showSnackBar(SnackBar(content: Text('$subject $action.')));
    return;
  }

  messenger.showSnackBar(
    SnackBar(
      backgroundColor: AppColors.danger,
      duration: const Duration(seconds: 8),
      content: Text(
        '$subject $action, but the audit trail did not record it. '
        'Tell your administrator before relying on the decision history.',
      ),
    ),
  );
}
