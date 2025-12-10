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

  DailyProgressSnapshot? _progress;
  bool _loadingProgress = true;
  String? _progressError;

  List<Deck> _recentDecks = [];
  bool _loadingDecks = true;
  String? _deckError;
  String? _displayName;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadRecentDecks();
    _loadProfile();
  }

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
    if (!mounted) return;
    setState(() {
      _displayName = profile?.displayName;
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
        _progressError = 'Khong tai duoc tien do: $e';
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
        _deckError = 'Khong tai duoc deck: $e';
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
        _progressError = 'Check-in that bai: $e';
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
              _DashboardHeader(
                accent: accent,
                secondaryAccent: secondaryAccent,
                progress: progress,
                loading: _loadingProgress,
                loadingProfile: _loadingProfile,
                displayName: _displayName,
                onCheckIn: _checkInToday,
              ),
              const SizedBox(height: 16),
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
                    const SizedBox(height: 24),
                    const Text(
                      'Previous decks',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
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
  final VoidCallback onCheckIn;

  const _DashboardHeader({
    required this.accent,
    required this.secondaryAccent,
    required this.progress,
    required this.loading,
    required this.loadingProfile,
    required this.displayName,
    required this.onCheckIn,
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
            secondaryAccent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
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
                child: const CircleAvatar(
                  radius: 32,
                  backgroundImage: AssetImage('images/avatar.jpg'),
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
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
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
          const SizedBox(height: 24),
          Container(
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
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          '${progress.currentStreak}-day streak',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: loading || progress.isTodayDone ? null : onCheckIn,
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
                const SizedBox(height: 18),
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
    final Color fill = active ? const Color(0xFF2FC50D) : const Color(0xFFF1F1F1);
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

class _StreakStatsCard extends StatelessWidget {
  final DailyProgressSnapshot progress;

  const _StreakStatsCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(
            title: 'Current streak',
            value: '${progress.currentStreak} days',
          ),
          _StatItem(
            title: 'Longest streak',
            value: '${progress.longestStreak} days',
          ),
          _StatItem(
            title: 'Last active',
            value: progress.lastActiveDate == null
                ? 'N/A'
                : _formatDate(progress.lastActiveDate!),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

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
              'Chua co gi o day ca, hay tao deck moi de bat dau nhe!!',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
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
                label: const Text('Tao deck moi'),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: decks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
        width: 200,
        padding: const EdgeInsets.all(16),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${deck.cardCount} cards',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  lastOpened,
                  style: const TextStyle(
                    color: Color(0xFF7233FE),
                    fontSize: 12,
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
