import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/services/secure_store.dart';

part 'database.g.dart';

/// One row per tracked document.
///
/// Everything lives on the device. There is no server, no account, and no
/// upload — a passport number is exactly the sort of thing that should never
/// leave the phone it was scanned on.
class Documents extends Table {
  TextColumn get id => text()();
  IntColumn get type => intEnum<DocumentType>()();
  TextColumn get label => text()();
  TextColumn get holder => text().nullable()();
  TextColumn get documentNumber => text().nullable()();
  TextColumn get issuingCountry => text().nullable()();
  DateTimeColumn get issueDate => dateTime().nullable()();
  DateTimeColumn get expiryDate => dateTime()();
  IntColumn get renewalLeadDays => integer()();
  TextColumn get imagePath => text().nullable()();

  /// How many pictures this document has. A card has two sides and some
  /// documents several pages, so one record owns an ordered set of images
  /// rather than a single face.
  IntColumn get imageCount => integer().withDefault(const Constant(0))();

  /// Type-specific fields, as JSON.
  ///
  /// A column each would mean a migration every time a document type gains a
  /// field, and a table full of nulls — a bank card has no plate number and a
  /// passport has no security code.
  TextColumn get details => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Documents])
class AppDatabase extends _$AppDatabase {
  AppDatabase(SecureStore secure, [QueryExecutor? executor])
      : super(executor ?? _openConnection(secure));

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(documents, documents.imageCount);
            // Records written before multi-image support have one picture if
            // they have any picture at all.
            await customStatement(
              'UPDATE documents SET image_count = 1 WHERE image_path IS NOT NULL',
            );
          }
          if (from < 3) {
            await m.addColumn(documents, documents.details);
          }
        },
      );

  /// All documents, soonest expiry first, as a live stream so the list
  /// redraws itself whenever anything changes.
  Stream<List<Document>> watchAll() {
    return (select(documents)
          ..orderBy([(t) => OrderingTerm.asc(t.expiryDate)]))
        .watch();
  }

  Future<List<Document>> getAll() {
    return (select(documents)
          ..orderBy([(t) => OrderingTerm.asc(t.expiryDate)]))
        .get();
  }

  Future<Document?> getById(String id) {
    return (select(documents)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsert(DocumentsCompanion entry) =>
      into(documents).insertOnConflictUpdate(entry);

  Future<int> deleteById(String id) =>
      (delete(documents)..where((t) => t.id.equals(id))).go();
}

/// Removes a database that this device's key cannot open.
///
/// The key lives in the Keychain and the data is worthless without it, so if
/// the two ever part company — the key cleared, the file restored from another
/// device's backup — the contents are already unrecoverable. Starting over is
/// then the only outcome available, and it is a great deal better than an app
/// that throws on launch and can never be opened again.
///
/// Deliberately narrow: only `SQLITE_NOTADB` triggers this. A disk error or a
/// locked file is transient and must not cost the user their documents.
Future<void> _discardIfUnreadable(File file, String passphrase) async {
  if (!await file.exists()) return;

  try {
    final probe = sqlite3.open(file.path);
    try {
      probe.execute("PRAGMA key = '$passphrase';");
      probe.select('SELECT count(*) FROM sqlite_master;');
    } finally {
      probe.dispose();
    }
  } on SqliteException catch (error) {
    const sqliteNotADatabase = 26;
    if (error.extendedResultCode != sqliteNotADatabase &&
        error.resultCode != sqliteNotADatabase) {
      rethrow;
    }
    debugPrint(
      'Elapsa: database cannot be decrypted with this device key — '
      'starting a new one.',
    );
    await file.delete();
  }
}

/// Opens the database encrypted with SQLCipher.
///
/// The passphrase is derived from the Keychain-held master key, so the file on
/// disk is unreadable without the device — which is what makes "everything
/// stays on your device" a property of the storage rather than a promise in
/// the marketing copy.
LazyDatabase _openConnection(SecureStore secure) {
  return LazyDatabase(() async {
    // Android's system sqlite would otherwise win the symbol lookup and open
    // the file as plain SQLite, which fails confusingly rather than loudly.
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'elapsa.sqlite'));
    final passphrase = await secure.databasePassphrase();

    await _discardIfUnreadable(file, passphrase);

    return NativeDatabase(
      file,
      setup: (db) {
        // The key has to be set before any other statement touches the file.
        db.execute("PRAGMA key = '$passphrase';");

        // Forces SQLCipher to actually read the header now. Without this the
        // first real query is where a wrong key surfaces, far from the cause.
        db.execute('SELECT count(*) FROM sqlite_master;');
      },
    );
  });
}
