import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class DayCheckin {
  final DateTime date;
  final bool done;

  const DayCheckin({
    required this.date,
    required this.done,
  });
}

class DailyProgressSnapshot {
  final int currentStreak;
  final int longestStreak;
  final bool isTodayDone;
  final DateTime? lastActiveDate;
  final List<DayCheckin> week;

  const DailyProgressSnapshot({
    required this.currentStreak,
    required this.longestStreak,
    required this.isTodayDone,
    required this.lastActiveDate,
    required this.week,
  });

  const DailyProgressSnapshot.empty()
      : currentStreak = 0,
        longestStreak = 0,
        isTodayDone = false,
        lastActiveDate = null,
        week = const [];
}

class DailyProgressService {
  DailyProgressService._();
  static final DailyProgressService instance = DailyProgressService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'flashcard',
  );

  CollectionReference<Map<String, dynamic>> _logsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('daily_logs');
  }

  Future<DailyProgressSnapshot> fetchProgress() async {
    final user = _auth.currentUser;
    if (user == null) return const DailyProgressSnapshot.empty();

    final today = _dateOnly(DateTime.now());
    final startOfWeek = _startOfWeek(today);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final weekDocs = await _logsCollection(user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('date', isLessThan: Timestamp.fromDate(endOfWeek))
        .get();
    final weekKeys = weekDocs.docs
        .map((doc) => _keyForDate(_dateOnly((doc.data()['date'] as Timestamp?)?.toDate() ?? today)))
        .toSet();

    final recentDocs = await _logsCollection(user.uid)
        .orderBy('date', descending: true)
        .limit(60)
        .get();
    final recentDates = recentDocs.docs
        .map((doc) => _dateOnly((doc.data()['date'] as Timestamp?)?.toDate() ?? today))
        .toList();

    final currentStreak = _computeCurrentStreak(today, recentDates);
    final longestStreak = _computeLongestStreak(recentDates);
    final todayKey = _keyForDate(today);

    final week = List<DayCheckin>.generate(7, (index) {
      final day = startOfWeek.add(Duration(days: index));
      return DayCheckin(
        date: day,
        done: weekKeys.contains(_keyForDate(day)),
      );
    });

    return DailyProgressSnapshot(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      isTodayDone: weekKeys.contains(todayKey) || recentDates.any((d) => _keyForDate(d) == todayKey),
      lastActiveDate: recentDates.isEmpty ? null : recentDates.first,
      week: week,
    );
  }

  Future<DailyProgressSnapshot> markTodayActive() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final today = _dateOnly(DateTime.now());
    final docId = _keyForDate(today);
    final docRef = _logsCollection(user.uid).doc(docId);

    await docRef.set(
      {
        'date': Timestamp.fromDate(today),
        'dateKey': docId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return fetchProgress();
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _keyForDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  DateTime _startOfWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return _dateOnly(date.subtract(Duration(days: daysFromSunday)));
  }

  int _computeCurrentStreak(DateTime today, List<DateTime> dates) {
    final keys = dates.map(_keyForDate).toSet();
    var streak = 0;
    var cursor = today;

    while (keys.contains(_keyForDate(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _computeLongestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final unique = dates.map(_keyForDate).toSet().toList();
    unique.sort();

    var longest = 1;
    var current = 1;
    for (var i = 1; i < unique.length; i++) {
      final prev = DateTime.parse(unique[i - 1]);
      final curr = DateTime.parse(unique[i]);
      if (curr.difference(prev).inDays == 1) {
        current += 1;
      } else {
        current = 1;
      }
      if (current > longest) {
        longest = current;
      }
    }
    return longest;
  }
}
