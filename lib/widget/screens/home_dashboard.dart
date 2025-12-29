import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_card/data/deck_repository.dart';
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/services/daily_progress_service.dart';
import 'package:flash_card/services/user_profile_service.dart';
import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flash_card/widget/screens/add_deck_screen.dart';
import 'package:flash_card/widget/screens/flashcard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

// Data management dashboard
class HomeDashboardScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueChanged<BottomNavItem>? onNavItemSelected;

  const HomeDashboardScreen({
    super.key,
    this.showBottomNav = true,
    this.onNavItemSelected,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final DeckRepository _deckRepository = deckRepository;

  // Daily progress data (streaks, check-ins)
  DailyProgressSnapshot? _progress;
  bool _loadingProgress = true;
  String? _progressError;

  List<Deck> _recentDecks = [];
  bool _loadingDecks = true;
  String? _deckError;
  String? _displayName;
  bool _loadingProfile = true;
  String _avatarPath = 'images/avatar.jpg';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void _showCalendar(DailyProgressSnapshot progress) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _CheckinCalendarCard(
              progress: progress,
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) {
                setState(() {
                  _focusedDay = focused;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleCheckInTap() async {
    if (_loadingProgress) return;
    final alreadyDone = _progress?.isTodayDone ?? false;
    if (!alreadyDone) {
      await _checkInToday();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadRecentDecks();
    _loadProfile();
  }

  // Data loading logic
  Future<void> _refreshAll() async {
    await Future.wait([
      _loadProgress(),
      _loadRecentDecks(),
      _loadProfile(),
    ]);
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
    });
    final profile = await UserProfileService.instance.fetchCurrentProfile();
    final prefs = await SharedPreferences.getInstance();
    final savedAvatar = prefs.getString('selected_avatar');
    if (!mounted) return;
    setState(() {
      _displayName = profile?.displayName;
      _avatarPath = savedAvatar ?? _avatarPath;
      _loadingProfile = false;
    });
  }

  Future<void> _loadProgress() async {
    setState(() {
      _loadingProgress = true;
      _progressError = null;
    });

    try {
      final result = await DailyProgressService.instance.fetchProgress();
      if (!mounted) return;
      setState(() {
        _progress = result;
        _loadingProgress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progressError = 'Unable to load your progress: $e';
        _loadingProgress = false;
      });
    }
  }

  Future<void> _loadRecentDecks() async {
    setState(() {
      _loadingDecks = true;
      _deckError = null;
    });

    try {
      final decks = await _deckRepository.fetchDecks();
      decks.sort((a, b) {
        final aDate = a.lastOpenedAt ?? a.createdAt;
        final bDate = b.lastOpenedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      final limited = decks.length > 10 ? decks.sublist(0, 10) : decks;
      if (!mounted) return;
      setState(() {
        _recentDecks = limited;
        _loadingDecks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deckError = 'Failed to load the deck: $e';
        _loadingDecks = false;
      });
    }
  }

  Future<void> _checkInToday() async {
    setState(() {
      _loadingProgress = true;
      _progressError = null;
    });

    try {
      final result = await DailyProgressService.instance.markTodayActive();
      if (!mounted) return;
      setState(() {
        _progress = result;
        _loadingProgress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progressError = 'Check-in failed: $e';
        _loadingProgress = false;
      });
    }
  }

  Future<void> _openDeck(Deck deck) async {
    await _deckRepository.markDeckOpened(deck.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          deck: deck,
          showBackButton: true,
          showBottomNav: false,
        ),
      ),
    );
    if (!mounted) return;
    _loadRecentDecks();
  }

  Future<void> _openAddDeck() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddDeckScreen()),
    );
    if (result == true && mounted) {
      _loadRecentDecks();
    }
  }

  // Main UI
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7233FE);
    const secondaryAccent = Color(0xFFAA80FF);
    final progress = _progress ?? const DailyProgressSnapshot.empty();

    return AppScaffold(
      title: 'Dashboard',
      showAppBar: false,
      currentItem: BottomNavItem.home,
      showBottomNav: widget.showBottomNav,
      onNavItemSelected: widget.onNavItemSelected,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            children: [
              // Hero panel with background, user info, and streak
              _DashboardHeader(
                accent: accent,
                secondaryAccent: secondaryAccent,
                progress: progress,
                loading: _loadingProgress,
                loadingProfile: _loadingProfile,
                displayName: _displayName,
                avatarPath: _avatarPath,
                onCheckIn: _handleCheckInTap,
                onShowCalendar: () => _showCalendar(progress),
              ),
              const SizedBox(height: 20),
              if (_progressError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _ErrorBanner(message: _progressError!, onRetry: _loadProgress),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StreakStatsCard(progress: progress),
                    const SizedBox(height: 20),
                    _OverviewRow(
                      totalDecks: _recentDecks.length,
                      studiedCards: _recentDecks.fold<int>(0, (sum, d) => sum + d.cardCount),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Previous decks',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _RecentDeckSection(
                      decks: _recentDecks,
                      loading: _loadingDecks,
                      error: _deckError,
                      onRetry: _loadRecentDecks,
                      onAddDeck: _openAddDeck,
                      onOpenDeck: _openDeck,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final Color accent;
  final Color secondaryAccent;
  final DailyProgressSnapshot progress;
  final bool loading;
  final bool loadingProfile;
  final String? displayName;
  final String avatarPath;
  final VoidCallback onCheckIn;
  final VoidCallback onShowCalendar;

  const _DashboardHeader({
    required this.accent,
    required this.secondaryAccent,
    required this.progress,
    required this.loading,
    required this.loadingProfile,
    required this.displayName,
    required this.avatarPath,
    required this.onCheckIn,
    required this.onShowCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = displayName?.isNotEmpty == true
        ? displayName!
        : (user?.displayName ?? user?.email ?? 'Learner');
    final week = progress.week.isNotEmpty ? progress.week : _placeholderWeek();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent,
            accent.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: AssetImage(avatarPath),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: onShowCalendar,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 35),
                          const SizedBox(width: 10),
                          Text(
                            '${progress.currentStreak}-day streak',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: loading ? null : onCheckIn,
                        child: Text(progress.isTodayDone ? 'Checked in' : 'Check in'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    progress.isTodayDone
                        ? 'You logged activity today. Keep it going!'
                        : 'Log one session today to keep your streak.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: week
                        .map(
                          (day) => _DayCircle(
                        label: _weekdayLabel(day.date),
                        active: day.done,
                        isToday: _isSameDate(day.date, DateTime.now()),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
class _DayCircle extends StatelessWidget {
  final String label;
  final bool active;
  final bool isToday;

  const _DayCircle({
    required this.label,
    required this.active,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final Color fill = active ? const Color(0xFFFFA500) : const Color(0xFFF1F1F1);
    final border = isToday ? Border.all(color: const Color(0xFF7233FE), width: 2) : null;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: border,
          ),
          child: active
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
      ],
    );
  }
}

// Widget showing a single stat number
class _StreakStatsCard extends StatelessWidget {
  final DailyProgressSnapshot progress;

  const _StreakStatsCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDDD5FF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(
            title: 'Current streak',
            value: '${progress.currentStreak} ${progress.currentStreak == 1 ? 'day' : 'days'}',
          ),
          _StatItem(
            title: 'Longest streak',
            value: '${progress.longestStreak} ${progress.longestStreak == 1 ? 'day' : 'days'}',
          ),
          _StatItem(
            title: 'Last active day',
            value: progress.lastActiveDate == null
                ? 'N/A'
                : _formatDate(progress.lastActiveDate!),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final int totalDecks;
  final int studiedCards;

  const _OverviewRow({
    required this.totalDecks,
    required this.studiedCards,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            label: 'Total decks',
            value: '$totalDecks',
            color: const Color(0xFF9D90FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            label: 'Studied cards',
            value: '$studiedCards',
            color: const Color(0xFF5CC6FF),
          ),
        ),
      ],
    );
  }
}

class _CheckinCalendarCard extends StatelessWidget {
  final DailyProgressSnapshot progress;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;

  const _CheckinCalendarCard({
    required this.progress,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final completedDays = progress.recentDates.map(DateUtils.dateOnly).toSet();
    final today = DateTime.now();
    final firstDay = DateTime.utc(today.year - 1, 1, 1);
    final lastDay = DateTime.utc(today.year + 1, 12, 31);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Check-in calendar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: const [
                  _LegendDot(color: Color(0xFFFFA500), label: 'Checked'),
                  SizedBox(width: 12),
                  _LegendDot(color: Color(0xFF7233FE), label: 'Today'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TableCalendar(
            firstDay: firstDay,
            lastDay: lastDay,
            focusedDay: focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => selectedDay != null && isSameDay(day, selectedDay),
            eventLoader: (day) {
              return completedDays.contains(DateUtils.dateOnly(day)) ? ['checked'] : [];
            },
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFF7233FE).withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7233FE), width: 1.6),
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF7233FE),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFFFFA500),
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
              outsideDaysVisible: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            color: Color(0xFF7233FE),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Widget showing create-deck prompt for new users
class _RecentDeckSection extends StatelessWidget {
  final List<Deck> decks;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;
  final VoidCallback onAddDeck;
  final void Function(Deck deck) onOpenDeck;

  const _RecentDeckSection({
    required this.decks,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onAddDeck,
    required this.onOpenDeck,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return _ErrorBanner(message: error!, onRetry: onRetry);
    }

    if (decks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No decks yet. Create a new one to start.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,

              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7233FE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onAddDeck,
                icon: const Icon(Icons.add),
                label: const Text('Create'),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        scrollDirection: Axis.horizontal,
        itemCount: decks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final deck = decks[index];
          return _DeckCard(
            deck: deck,
            onTap: () => onOpenDeck(deck),
          );
        },
      ),
    );
  }
}

// Widget for each deck item (title, card count, last opened)
class _DeckCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;

  const _DeckCard({
    required this.deck,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = deck.description.isNotEmpty
        ? deck.description
        : '${deck.cardCount} cards';
    final lastOpened = deck.lastOpenedAt != null ? _formatDate(deck.lastOpenedAt!) : 'Never';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E6E6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deck.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF7233FE),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87, fontSize: 13,),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${deck.cardCount} cards',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                Text(
                  lastOpened,
                  style: const TextStyle(
                    color: Color(0xFF7233FE),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC29D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.deepOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _weekdayLabel(DateTime date) {
  const labels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  final index = date.weekday % 7;
  return labels[index];
}

List<DayCheckin> _placeholderWeek() {
  final now = DateTime.now();
  final start = now.subtract(Duration(days: now.weekday % 7));
  return List.generate(
    7,
        (i) => DayCheckin(date: start.add(Duration(days: i)), done: false),
  );
}

String _formatDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '$dd/$mm';
}
