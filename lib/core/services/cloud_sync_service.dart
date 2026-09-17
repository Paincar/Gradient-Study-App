import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import 'auth_service.dart';

enum CloudSyncStatus {
  synced,
  syncing,
  localOnly,
  error,
}

class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._internal();
  CloudSyncService._internal();

  CloudSyncStatus _status = CloudSyncStatus.localOnly;
  DateTime? _lastSyncTime;
  String? _lastError;

  CloudSyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;

  final ValueNotifier<CloudSyncStatus> statusNotifier =
      ValueNotifier<CloudSyncStatus>(CloudSyncStatus.localOnly);

  void _setStatus(CloudSyncStatus newStatus) {
    _status = newStatus;
    statusNotifier.value = newStatus;
  }

  /// Sync a single note to Firestore
  Future<void> syncNote(NoteItem note) async {
    final user = AuthService.instance.currentUser;
    if (user == null || !AuthService.instance.isFirebaseReady) {
      _setStatus(CloudSyncStatus.localOnly);
      return;
    }

    try {
      _setStatus(CloudSyncStatus.syncing);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(note.id)
          .set(note.toJson(), SetOptions(merge: true));
      _lastSyncTime = DateTime.now();
      _setStatus(CloudSyncStatus.synced);
    } catch (e) {
      debugPrint('Cloud sync error for note ${note.id}: $e');
      _lastError = e.toString();
      _setStatus(CloudSyncStatus.error);
    }
  }

  /// Delete note from Firestore
  Future<void> deleteNote(String noteId) async {
    final user = AuthService.instance.currentUser;
    if (user == null || !AuthService.instance.isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting note from cloud: $e');
    }
  }

  /// Perform full two-way reconciliation between local notes and Cloud Firestore
  Future<List<NoteItem>> syncAllNotes(List<NoteItem> localNotes) async {
    final user = AuthService.instance.currentUser;
    if (user == null || !AuthService.instance.isFirebaseReady) {
      _setStatus(CloudSyncStatus.localOnly);
      return localNotes;
    }

    try {
      _setStatus(CloudSyncStatus.syncing);
      final notesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes');

      final snapshot = await notesCollection.get();
      final remoteNotesMap = <String, NoteItem>{};

      for (final doc in snapshot.docs) {
        try {
          final item = NoteItem.fromJson(doc.data());
          remoteNotesMap[item.id] = item;
        } catch (_) {}
      }

      final mergedNotes = <String, NoteItem>{};

      // Merge local notes
      for (final local in localNotes) {
        if (remoteNotesMap.containsKey(local.id)) {
          final remote = remoteNotesMap[local.id]!;
          if (remote.updatedAt.isAfter(local.updatedAt)) {
            mergedNotes[local.id] = remote;
          } else {
            mergedNotes[local.id] = local;
            // Update remote with newer local version
            await notesCollection.doc(local.id).set(local.toJson(), SetOptions(merge: true));
          }
        } else {
          mergedNotes[local.id] = local;
          // Upload local note that is missing in remote
          await notesCollection.doc(local.id).set(local.toJson(), SetOptions(merge: true));
        }
      }

      // Add remote notes that are not present locally
      for (final remoteEntry in remoteNotesMap.entries) {
        if (!mergedNotes.containsKey(remoteEntry.key)) {
          mergedNotes[remoteEntry.key] = remoteEntry.value;
        }
      }

      _lastSyncTime = DateTime.now();
      _setStatus(CloudSyncStatus.synced);
      return mergedNotes.values.toList();
    } catch (e) {
      debugPrint('Full sync failure: $e');
      _lastError = e.toString();
      _setStatus(CloudSyncStatus.error);
      return localNotes;
    }
  }
}
