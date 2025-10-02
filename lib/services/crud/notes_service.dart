// import 'dart:async';
// import 'package:mynotes/extensions/list/filter.dart';
// import 'package:mynotes/services/crud/crud_exceptions.dart';
// import 'package:path/path.dart' show join;
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';

// const idCol = "id";
// const emailCol = "email";
// const userIdCol = "user_id";
// const textCol = "text";
// const isSyncedWithCloudCol = "is_synced_with_cloud";
// const dbName = "notes.db";
// const userTable = "user";
// const noteTable = "note";

// const createUserTable =
//     '''
//   CREATE TABLE IF NOT EXISTS "$userTable"(
//     "id"	INTEGER NOT NULL,
//     "email"	TEXT NOT NULL UNIQUE,
//     PRIMARY KEY("id" AUTOINCREMENT)
//   );''';

// const createNoteTable =
//     '''
// CREATE TABLE IF NOT EXISTS "$noteTable" (
//   "id"	INTEGER NOT NULL,
//   "user_id"	INTEGER NOT NULL,
//   "text"	TEXT,
//   "is_synced_with_cloud"	INTEGER NOT NULL,
//   PRIMARY KEY("id" AUTOINCREMENT),
//   FOREIGN KEY("user_id") REFERENCES "user"("id")
// );''';

// class NotesService {
//   Database? _db;
//   List<DatabaseNote> _notes = [];
//   DatabaseUser? _user;

//   late final StreamController<List<DatabaseNote>> _notesStreamController;
//   Stream<List<DatabaseNote>> get allNotes =>
//      _notesStreamController.stream.filter((note){
//         final currenUser=_user;
//         if(currenUser!=null){
//           return currenUser.id==note.userId;
//         }else{
//           throw UserShouldBeSetBeforeReadingAllNotes();
//         }
//      });

//   //creating a singleton
//   static final NotesService _shared = NotesService._sharedInstance();
//   NotesService._sharedInstance() {
//     _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
//       onListen: () {
//         _notesStreamController.sink.add(_notes);
//       },
//     );
//   }
//   factory NotesService() => _shared;

//   Future<DatabaseUser> getOrCreateUser({
//     required String email,
//     bool setAsCurrentUser = true,
//   }) async {
//     try {
//       final user = await getUser(email: email);
//       if(setAsCurrentUser){
//         _user=user;
//       }
//       return user;
//     } on UserNotFound {
//       final user = await createUser(email: email);
//       if(setAsCurrentUser){
//         _user=user;
//       }
//       return user;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> _cacheNotes() async {
//     final allNotes = await getAllNote();
//     _notes = allNotes.toList();
//     _notesStreamController.add(_notes);
//   }

//   Future<DatabaseNote> updateNote({
//     required String text,
//     required DatabaseNote note,
//   }) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     // make sure that the note exists
//     await getNote(id: note.id);

//     final updateCount = await db.update(
//       noteTable,
//       {textCol: text, isSyncedWithCloudCol: 0},
//       whereArgs: [note.id],
//       where: "id = ?",
//     );

//     if (updateCount == 0) {
//       throw CouldNotUpdateNote();
//     } else {
//       final updatedNote = await getNote(id: note.id);
//       _notes.removeWhere((note) => note.id == updatedNote.id);
//       _notes.add(updatedNote);
//       _notesStreamController.add(_notes);
//       return updatedNote;
//     }
//   }

//   Future<Iterable<DatabaseNote>> getAllNote() async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final notes = await db.query(noteTable);

//     return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
//   }

//   Future<DatabaseNote> getNote({required int id}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final notes = await db.query(
//       noteTable,
//       where: "id = ?",
//       whereArgs: [id],
//       limit: 1,
//     );

//     if (notes.isEmpty) {
//       throw NoteNotFound();
//     } else {
//       final note = DatabaseNote.fromRow(notes.first);
//       _notes.removeWhere((note) => note.id == id);
//       _notes.add(note);
//       _notesStreamController.add(_notes);
//       return note;
//     }
//   }

//   Future<int> deleteAllNotes() async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     _notes = [];
//     _notesStreamController.add(_notes);
//     return await db.delete(noteTable);
//   }

//   Future<void> deleteNote({required int id}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       noteTable,
//       where: "id = ?",
//       whereArgs: [id],
//     );

//     if (deletedCount != 1) {
//       throw CouldNotDeleteNote();
//     } else {
//       _notes.removeWhere((note) => id == note.id);
//       _notesStreamController.add(_notes);
//     }
//   }

//   Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();

//     final dbUser = await getUser(email: owner.email);
//     if (dbUser != owner) throw UserNotFound();

//     const text = "";

//     final noteId = await db.insert(noteTable, {
//       userIdCol: owner.id,
//       textCol: text,
//       isSyncedWithCloudCol: 1,
//     });

//     final note = DatabaseNote(
//       userId: owner.id,
//       id: noteId,
//       isSyncedWithCloud: true,
//       text: text,
//     );
//     _notes.add(note);
//     _notesStreamController.add(_notes);
//     return note;
//   }

//   Future<DatabaseUser> getUser({required String email}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final result = await db.query(
//       userTable,
//       limit: 1,
//       where: "email = ?",
//       whereArgs: [email.toLowerCase()],
//     );

//     if (result.isEmpty) {
//       throw UserNotFound();
//     } else {
//       return DatabaseUser.fromRow(result.first);
//     }
//   }

//   Future<DatabaseUser> createUser({required String email}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final result = await db.query(
//       userTable,
//       limit: 1,
//       where: "email = ?",
//       whereArgs: [email.toLowerCase()],
//     );

//     if (result.isNotEmpty) throw UserAlreadyExists();

//     final userId = await db.insert(userTable, {emailCol: email.toLowerCase()});

//     return DatabaseUser(id: userId, email: email);
//   }

//   Future<void> deleteUser({required String email}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       userTable,
//       where: "email = ?",
//       whereArgs: [email.toLowerCase()],
//     );

//     if (deletedCount != 1) throw CouldNotDeleteUser();
//   }

//   Database _getDatabaseOrThrow() {
//     final db = _db;
//     if (db == null) {
//       throw DatabaseIsNotOpen();
//     } else {
//       return db;
//     }
//   }

//   Future<void> _ensureDbIsOpen() async {
//     try {
//       await open();
//     } on DatabaseAlreadyOpenException {
//       return;
//     }
//   }

//   Future<void> open() async {
//     if (_db != null) throw DatabaseAlreadyOpenException();

//     try {
//       final docsPath = await getApplicationDocumentsDirectory();
//       final dbPath = join(docsPath.path, dbName);
//       final db = await openDatabase(dbPath);
//       _db = db;
//       // await db.delete(userTable);
//       // await db.delete(noteTable);
//       await db.execute(createUserTable);
//       await db.execute(createNoteTable);
//       await _cacheNotes();
//     } on MissingPlatformDirectoryException catch (_) {
//       throw UnableToGetDocumentDirectory();
//     }
//   }

//   Future<void> close() async {
//     if (_db == null) throw DatabaseIsNotOpen();

//     await _db?.close();
//     _db = null;
//   }
// }

// class DatabaseUser {
//   final int id;
//   final String email;

//   DatabaseUser({required this.id, required this.email});

//   DatabaseUser.fromRow(Map<String, Object?> map)
//     : id = map[idCol] as int,
//       email = map[emailCol] as String;

//   @override
//   String toString() {
//     return "Person, ID=$id, email=$email";
//   }

//   @override
//   bool operator ==(covariant DatabaseUser other) {
//     return id == other.id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }

// class DatabaseNote {
//   final int userId, id;
//   final bool isSyncedWithCloud;
//   final String text;

//   DatabaseNote({
//     required this.userId,
//     required this.id,
//     required this.isSyncedWithCloud,
//     required this.text,
//   });

//   DatabaseNote.fromRow(Map<String, Object?> map)
//     : id = map[idCol] as int,
//       userId = map[userIdCol] as int,
//       isSyncedWithCloud = (map[isSyncedWithCloudCol] as int) == 1
//           ? true
//           : false,
//       text = map[textCol] as String;

//   @override
//   String toString() {
//     return "Note, ID=$id, userID=$userId, isSysncedWithCloud=$isSyncedWithCloud, text=$text";
//   }

//   @override
//   bool operator ==(covariant DatabaseNote other) {
//     return id == other.id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }
