import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/quick_add/data/repository/quick_add_draft_repository.dart';
import 'package:opennutritracker/features/quick_add/domain/entity/quick_add_draft_entity.dart';
import 'package:opennutritracker/features/quick_add/domain/usecase/quick_add_draft_usecase.dart';

void main() {
  late AppDatabase db;
  late QuickAddDraftUsecase usecase;

  setUp(() {
    db = AppDatabase.createInMemory();
    final repository = QuickAddDraftRepository(ConfigDao(db));
    usecase = QuickAddDraftUsecase(repository);
  });

  tearDown(() async {
    await db.close();
  });

  test('returns null when no draft has been saved', () async {
    expect(await usecase.getDraft(), isNull);
  });

  test('saves and restores a non-empty draft', () async {
    const draft = QuickAddDraftEntity(
      kcal: '250',
      label: 'Cereal',
      mealSlot: 'breakfast',
    );

    await usecase.saveDraft(draft);
    final restored = await usecase.getDraft();

    expect(restored, equals(draft));
  });

  test('does not persist an empty draft', () async {
    await usecase.saveDraft(const QuickAddDraftEntity());
    expect(await usecase.getDraft(), isNull);
  });

  test('saving an empty draft clears a previously saved one', () async {
    await usecase.saveDraft(const QuickAddDraftEntity(kcal: '100'));
    expect(await usecase.getDraft(), isNotNull);

    await usecase.saveDraft(const QuickAddDraftEntity());
    expect(await usecase.getDraft(), isNull);
  });

  test('clearDraft removes a saved draft', () async {
    await usecase.saveDraft(const QuickAddDraftEntity(kcal: '100'));
    await usecase.clearDraft();
    expect(await usecase.getDraft(), isNull);
  });
}
