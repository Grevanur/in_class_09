import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Folder {
  const Folder({required this.id, required this.name, required this.createdAt, this.cardCount = 0});
  final int id;
  final String name;
  final String createdAt;
  final int cardCount;
  factory Folder.fromMap(Map<String, Object?> map) => Folder(
    id: map['id'] as int, name: map['name'] as String,
    createdAt: map['created_at'] as String, cardCount: (map['card_count'] as int?) ?? 0,
  );
}

class PlayingCard {
  const PlayingCard({this.id, required this.title, required this.suit, required this.folderId, this.notes = '', this.imageRef});
  final int? id;
  final String title;
  final String suit;
  final String notes;
  final String? imageRef;
  final int folderId;
  factory PlayingCard.fromMap(Map<String, Object?> map) => PlayingCard(
    id: map['id'] as int, title: map['title'] as String, suit: map['suit'] as String,
    notes: map['notes'] as String, imageRef: map['image_ref'] as String?, folderId: map['folder_id'] as int,
  );
  Map<String, Object?> toMap() => {
    'title': title, 'suit': suit, 'notes': notes, 'image_ref': imageRef, 'folder_id': folderId,
  };
}

/// Owns the v1 roster plus the additive v2 folder/card schema and repository methods.
class DatabaseHelper {
  static const _databaseName = 'MyDatabase.db';
  static const _databaseVersion = 2;
  static const guestTable = 'my_table';
  static const guestId = '_id';
  static const guestName = 'name';
  static const guestAge = 'age';
  late Database _db;

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _db = await openDatabase(join(directory.path, _databaseName), version: _databaseVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('CREATE TABLE $guestTable ($guestId INTEGER PRIMARY KEY, $guestName TEXT NOT NULL, $guestAge INTEGER NOT NULL)');
      await _createV2Tables(txn);
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await db.transaction(_createV2Tables);
  }

  Future<void> _createV2Tables(DatabaseExecutor db) async {
    await db.execute('CREATE TABLE folders (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, created_at TEXT NOT NULL)');
    await db.execute("CREATE TABLE cards (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, suit TEXT NOT NULL, notes TEXT NOT NULL DEFAULT '', image_ref TEXT, folder_id INTEGER NOT NULL, FOREIGN KEY(folder_id) REFERENCES folders(id) ON DELETE CASCADE)");
    await db.execute('CREATE INDEX idx_cards_folder_id ON cards(folder_id)');
  }

  Future<List<Map<String, Object?>>> queryAllRows() => _db.query(guestTable, orderBy: '$guestId ASC');
  Future<int> queryRowCount() async => Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM $guestTable')) ?? 0;
  Future<List<Folder>> getFoldersWithCounts() async => (await _db.rawQuery('SELECT f.id, f.name, f.created_at, COUNT(c.id) AS card_count FROM folders f LEFT JOIN cards c ON c.folder_id = f.id GROUP BY f.id ORDER BY f.name COLLATE NOCASE')).map(Folder.fromMap).toList();
  Future<List<PlayingCard>> getCards(int folderId) async => (await _db.query('cards', where: 'folder_id = ?', whereArgs: [folderId], orderBy: 'title COLLATE NOCASE ASC')).map(PlayingCard.fromMap).toList();
  Future<int> insertFolder(String name) => _db.insert('folders', {'name': name, 'created_at': DateTime.now().toIso8601String()});
  Future<int> insertCard(PlayingCard card) => _db.insert('cards', card.toMap());
  Future<int> updateCard(PlayingCard card) => _db.update('cards', card.toMap(), where: 'id = ?', whereArgs: [card.id]);
  Future<int> deleteCard(int id) => _db.delete('cards', where: 'id = ?', whereArgs: [id]);
  Future<int> deleteFolder(int id) => _db.delete('folders', where: 'id = ?', whereArgs: [id]);
}
