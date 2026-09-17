import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

enum SyncState { connected, syncing, offline, error }

class SyncService extends ChangeNotifier {
  SyncState _status = SyncState.offline;
  int _pendingUploadsCount = 0;
  String? _lastSyncTime;
  String? _errorMessage;
  int _lastEventId = 0;

  SyncState get status => _status;
  int get pendingUploadsCount => _pendingUploadsCount;
  String? get lastSyncTime => _lastSyncTime;
  String? get errorMessage => _errorMessage;
  int get lastEventId => _lastEventId;

  bool get isOnline => _status == SyncState.connected || _status == SyncState.syncing;

  Future<void> initialize({
    required String token,
    required String organizationId,
    required String branchId,
    required String deviceUuid,
    String? apiUrl,
  }) async {
    _status = SyncState.syncing;
    notifyListeners();

    try {
      final baseUrl = apiUrl ?? AppConstants.defaultApiUrl;
      final uri = Uri.parse('$baseUrl/sync/pull').replace(
        queryParameters: {
          'device_uuid': deviceUuid,
          'branch_id': branchId,
          'last_event_id': _lastEventId.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastEventId = data['new_cursor'] ?? _lastEventId;
        _status = SyncState.connected;
        _lastSyncTime = DateTime.now().toIso8601String();
        _errorMessage = null;
      } else {
        _status = SyncState.offline;
      }
    } catch (e) {
      _status = SyncState.offline;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> pushBatch({
    required String token,
    required String branchId,
    required String deviceUuid,
    required List<Map<String, dynamic>> items,
    String? apiUrl,
  }) async {
    if (items.isEmpty) return true;

    _status = SyncState.syncing;
    notifyListeners();

    try {
      final baseUrl = apiUrl ?? AppConstants.defaultApiUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/sync/push'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'device_uuid': deviceUuid,
          'items': items,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _pendingUploadsCount = 0;
        _lastSyncTime = DateTime.now().toIso8601String();
        _status = SyncState.connected;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _status = SyncState.error;
        _errorMessage = 'Sync push failed with status ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = SyncState.offline;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void queueOfflineWrite() {
    _pendingUploadsCount++;
    notifyListeners();
  }

  void completeSync() {
    _pendingUploadsCount = 0;
    _lastSyncTime = DateTime.now().toIso8601String();
    _status = SyncState.connected;
    notifyListeners();
  }

  void setOffline() {
    _status = SyncState.offline;
    notifyListeners();
  }
}
