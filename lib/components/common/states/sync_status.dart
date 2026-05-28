import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';

/// Background sync health — designed for queue/retry extensions later.
enum SyncStatus {
  syncing,
  synced,
  pending,
  failed,
}

extension SyncStatusX on SyncStatus {
  String get label => switch (this) {
        SyncStatus.syncing => 'Syncing…',
        SyncStatus.synced => 'All changes synced',
        SyncStatus.pending => 'Pending sync',
        SyncStatus.failed => 'Sync paused',
      };

  IconData get icon => switch (this) {
        SyncStatus.syncing => Icons.sync_rounded,
        SyncStatus.synced => Icons.cloud_done_rounded,
        SyncStatus.pending => Icons.schedule_rounded,
        SyncStatus.failed => Icons.cloud_off_rounded,
      };

  Color get accent => switch (this) {
        SyncStatus.syncing => AppColors.secondary,
        SyncStatus.synced => AppColors.success,
        SyncStatus.pending => AppColors.warning,
        SyncStatus.failed => AppColors.danger,
      };

  bool get showsSpinner => this == SyncStatus.syncing;
}

/// Future-ready processing kinds (OCR, voice, bank sync, AI, etc.).
enum ProcessingStateKind {
  generic,
  ai,
  ocr,
  voiceInput,
  bankSync,
  backgroundQueue,
}

extension ProcessingStateKindX on ProcessingStateKind {
  String get loadingHint => switch (this) {
        ProcessingStateKind.generic => 'Loading…',
        ProcessingStateKind.ai => 'Thinking…',
        ProcessingStateKind.ocr => 'Reading receipt…',
        ProcessingStateKind.voiceInput => 'Processing voice…',
        ProcessingStateKind.bankSync => 'Connecting to bank…',
        ProcessingStateKind.backgroundQueue => 'Processing in background…',
      };

  IconData get icon => switch (this) {
        ProcessingStateKind.generic => Icons.hourglass_empty_rounded,
        ProcessingStateKind.ai => Icons.auto_awesome_rounded,
        ProcessingStateKind.ocr => Icons.document_scanner_outlined,
        ProcessingStateKind.voiceInput => Icons.mic_rounded,
        ProcessingStateKind.bankSync => Icons.account_balance_rounded,
        ProcessingStateKind.backgroundQueue => Icons.queue_rounded,
      };
}
