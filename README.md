# In Class Activity 09 Local Storage Part II

## Student and pathway

- Student: Gowtham Revanur
- Panther ID: 002574540
- Pathway: Graduate
- Flutter: 3.47.2 / Dart 3.13.2

## Build and run

```bash
flutter pub get
flutter analyze
flutter run -d emulator-5554
flutter build apk --release
```

## Database migration and design

The app keeps the Part I database filename, `MyDatabase.db`, and the existing version-1 table, `my_table` (`_id`, `name`, `age`). Version 2 adds `folders` and `cards`; it does not drop, rename, or recreate `my_table`. `onUpgrade` runs the v2 schema inside a transaction for an existing Part I installation. `onCreate` creates the complete v1 plus v2 schema for a fresh install. Foreign keys are enabled in `onConfigure`; `cards.folder_id` references `folders.id` with `ON DELETE CASCADE`, and `idx_cards_folder_id` supports the filtered card query.

`Folder` and `PlayingCard` are typed model classes in `lib/database_helper.dart`. The same repository owns parameterized folder/card CRUD: `getFoldersWithCounts`, `getCards(folderId)`, `insertCard`, `updateCard`, `deleteCard`, and `deleteFolder`. Widgets do not contain SQL.

## User interface and image handling

The folders screen displays a generated integer ID and card count. Tapping a folder lists only cards whose `folder_id` matches that folder. One card form handles add and edit; it requires a title and supported suit. Notes and `image_ref` are optional. This lab stores only the nullable image reference; when it is absent, the UI deliberately displays a stable suit-symbol placeholder rather than failing. Delete confirmations name the target. Cancel never writes.

## T1 to T6 evidence plan

Evidence must be collected on the actual Android target before submission. Preserve real observations rather than fabricating them.

| Test | Expected observation |
|---|---|
| T1 Upgrade | Existing Part I rows retain their values and count after v1 to v2 upgrade. |
| T2 Create | Two cards in one folder and a third in another have generated IDs and accurate counts. |
| T3 Edit | One ID changes after Save; a cancelled edit changes nothing. |
| T4 Restart | IDs, values, and counts survive force-stop/relaunch without clearing storage. |
| T5 Delete | Cancel keeps data; confirmed folder delete removes its child cards. |
| T6 Failure | Empty title writes nothing and a null image reference shows the fallback symbol. |

Place the observed results, real IDs/counts, and pass/fail outcome in this table before publishing. Keep `evidence/T1_before.png`, `evidence/T2_cards.png`, `evidence/T4_after.png`, and `evidence/analysis_output.txt` in the repository. `flutter analyze` completed with `No issues found!` on Oct. 8, 2026.

## Known limitations and attribution

This is an offline local SQLite lab. It intentionally has no cloud sync, authentication, gallery picker, or network image dependency. Test records must be fictional. Course notes and the sqflite/Flutter documentation informed the implementation. Codex assisted with source organization and static analysis; final runtime evidence must be the student's actual observation.
