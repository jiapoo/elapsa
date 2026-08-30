import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:elapsa/domain/document_type.dart';

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
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'elapsa.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
