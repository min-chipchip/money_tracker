import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A new globally unique id for a database row.
///
/// UUIDv7 instead of 1, 2, 3...: two phones can create rows offline without
/// clashing (needed for sync later), and v7 ids start with a timestamp, so
/// they sort by creation time and keep indexes efficient.
String newId() => _uuid.v7();
