import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

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
  int get schemaVersion => 1;

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
