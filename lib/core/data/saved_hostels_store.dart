import 'package:flutter/foundation.dart';

// ── Saved Hostels Store ────────────────────────────────────────────────────
// In-memory, app-session-only store of hostels the seeker has saved. This is
// a stand-in for real persistence (SharedPreferences locally, or a Firestore
// `saved_hostels` subcollection per user once auth/backend exist) — every
// screen that cares about "is this hostel saved" talks to this singleton
// instead of holding its own bool, so the heart icon on the detail screen
// and the Saved Hostels list always agree.
//
// Hostels are keyed by name+city since the dummy data doesn't carry a real
// id yet. Swap `_keyOf` for `hostel['id'] as String` once hostels have one.
class SavedHostelsStore extends ChangeNotifier {
  SavedHostelsStore._();
  static final SavedHostelsStore instance = SavedHostelsStore._();

  final Map<String, Map<String, dynamic>> _saved = {};

  /// Saved hostels, most-recently-saved first.
  List<Map<String, dynamic>> get all => _saved.values.toList().reversed.toList();

  int get count => _saved.length;

  bool get isEmpty => _saved.isEmpty;

  String _keyOf(Map<String, dynamic> hostel) => '${hostel['name']}|${hostel['city']}';

  bool isSaved(Map<String, dynamic> hostel) => _saved.containsKey(_keyOf(hostel));

  void toggle(Map<String, dynamic> hostel) {
    final key = _keyOf(hostel);
    if (_saved.containsKey(key)) {
      _saved.remove(key);
    } else {
      _saved[key] = hostel;
    }
    notifyListeners();
  }

  void save(Map<String, dynamic> hostel) {
    _saved[_keyOf(hostel)] = hostel;
    notifyListeners();
  }

  void remove(Map<String, dynamic> hostel) {
    if (_saved.remove(_keyOf(hostel)) != null) {
      notifyListeners();
    }
  }
}