import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('users.db');
  final result = db.select('SELECT email FROM users;');
  for (final row in result) {
    print('Email: "${row['email']}"');
  }
  db.dispose();
}
