import 'dart:convert';
import 'dart:io';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../models/contest_entry.dart';

class SheetsService {
  static Future<List<ContestEntry>> fetchTopTen({
    required String credentialsPath,
    required String sheetId,
  }) async {
    final raw = await File(credentialsPath).readAsString();
    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(raw) as Map<String, dynamic>,
    );

    // clientViaServiceAccount signs a JWT with the private key, exchanges it
    // for an OAuth2 token scoped to Sheets read-only, and returns an HTTP
    // client that auto-refreshes that token.
    final client = await clientViaServiceAccount(
      credentials,
      [SheetsApi.spreadsheetsReadonlyScope],
    );

    try {
      final api = SheetsApi(client);
      final response = await api.spreadsheets.values.get(sheetId, 'A:E');
      final rows = response.values ?? [];

      final entries = <ContestEntry>[];
      for (final row in rows) {
        if (row.length < 4) continue;
        // Rows where column D isn't an integer (e.g. the header row) are
        // silently skipped — no need to explicitly detect the header.
        final time = int.tryParse(row[3].toString());
        if (time == null) continue;
        entries.add(ContestEntry(
          name: row[0].toString(),
          email: row[1].toString(),
          nickname: row.length > 2 ? row[2].toString() : null,
          timeSeconds: time,
        ));
      }

      // Keep only the fastest submission per person, then return the top 10.
      final best = <String, ContestEntry>{};
      for (final e in entries) {
        final existing = best[e.email];
        if (existing == null || e.timeSeconds < existing.timeSeconds) {
          best[e.email] = e;
        }
      }

      return (best.values.toList()
            ..sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds)))
          .take(10)
          .toList();
    } finally {
      client.close();
    }
  }
}
