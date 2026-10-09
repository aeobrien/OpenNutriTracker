import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/quick_add/domain/entity/quick_add_draft_entity.dart';

/// Persists a single in-progress quick-add draft in the generic key/value
/// [ConfigDao] store, so a half-filled form survives app switches without
/// needing a dedicated drift table or schema migration.
class QuickAddDraftRepository {
  static const _draftKey = 'quickAddDraft';

  final ConfigDao _configDao;
  final _log = Logger('QuickAddDraftRepository');

  QuickAddDraftRepository(this._configDao);

  Future<void> saveDraft(QuickAddDraftEntity draft) async {
    _log.fine('Saving quick-add draft');
    await _configDao.setValue(_draftKey, draft.encode());
  }

  Future<QuickAddDraftEntity?> getDraft() async {
    final raw = await _configDao.getValue(_draftKey);
    return QuickAddDraftEntity.decode(raw);
  }

  Future<void> clearDraft() async {
    _log.fine('Clearing quick-add draft');
    await _configDao.setValue(_draftKey, '');
  }
}
