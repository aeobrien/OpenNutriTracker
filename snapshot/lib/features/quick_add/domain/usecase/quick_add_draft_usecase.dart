import 'package:opennutritracker/features/quick_add/data/repository/quick_add_draft_repository.dart';
import 'package:opennutritracker/features/quick_add/domain/entity/quick_add_draft_entity.dart';

/// Business logic for the quick-add draft: an empty draft is discarded rather
/// than stored, and loading a draft that turns out empty returns null.
class QuickAddDraftUsecase {
  final QuickAddDraftRepository _repository;

  QuickAddDraftUsecase(this._repository);

  Future<void> saveDraft(QuickAddDraftEntity draft) async {
    if (draft.isEmpty) {
      await _repository.clearDraft();
      return;
    }
    await _repository.saveDraft(draft);
  }

  Future<QuickAddDraftEntity?> getDraft() async {
    final draft = await _repository.getDraft();
    if (draft == null || draft.isEmpty) return null;
    return draft;
  }

  Future<void> clearDraft() async {
    await _repository.clearDraft();
  }
}
