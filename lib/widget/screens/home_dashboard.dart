import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flutter/material.dart';

class HomeDashboardScreen extends StatelessWidget {
  final bool showBottomNav;
  final ValueChanged<BottomNavItem>? onNavItemSelected;

  const HomeDashboardScreen({
    super.key,
    this.showBottomNav = true,
    this.onNavItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7233FE);
    const secondaryAccent = Color(0xFFAA80FF);

    return AppScaffold(
      title: 'Dashboard',
      showAppBar: false,
      currentItem: BottomNavItem.home,
      showBottomNav: showBottomNav,
      onNavItemSelected: onNavItemSelected,
      body: const SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 24.0),
        child: Column(
          children: [
            _DashboardHeader(accent: accent, secondaryAccent: secondaryAccent),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StreakCard(),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _DailyGoalsCard()),
                      SizedBox(width: 12),
                      Expanded(child: _TotalCardsCard()),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Previous decks',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  _DeckList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final Color accent;
  final Color secondaryAccent;

  const _DashboardHeader({
    required this.accent,
    required this.secondaryAccent,
  });

  @override
  Widget build(BuildContext context) {
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kafuu Chino',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                    SizedBox(width: 8),
                    Text(
                      '4-day streak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Learn daily, keep your streak up',
                  style: TextStyle(color: Colors.black54),
                ),
                SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DayCircle(label: 'Su', active: true),
                    _DayCircle(label: 'Mo', active: true),
                    _DayCircle(label: 'Tu', active: true),
                    _DayCircle(label: 'We', active: true),
                    _DayCircle(label: 'Th', active: false),
                    _DayCircle(label: 'Fr', active: false),
                    _DayCircle(label: 'Sa', active: false),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  final String label;
  final bool active;

  const _DayCircle({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
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
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF2FC50D) : const Color(0xFFF1F1F1),
          ),
          child: active
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily goals',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '4-day streak',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Keep up the momentum! You are almost there for this week.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalsCard extends StatelessWidget {
  const _DailyGoalsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          SizedBox(
            height: 66,
            width: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 7,
                    value: 0.75,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF7233FE)),
                  ),
                ),
                Text(
                  '75%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7233FE),
                  ),
                )
              ],
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '9 of 12 decks',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                ),
                SizedBox(height: 6),
                Text(
                  '30 of 100 cards',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TotalCardsCard extends StatelessWidget {
  const _TotalCardsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total cards',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '500',
            style: TextStyle(
              fontSize: 32,
              color: Color(0xFF7233FE),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DeckProgress {
  final String title;
  final int cards;
  final double progress;

  const DeckProgress({
    required this.title,
    required this.cards,
    required this.progress,
  });
}

class _DeckList extends StatelessWidget {
  const _DeckList();

  static const decks = [
    DeckProgress(
      title: 'IELTS Vocab_ Environment',
      cards: 20,
      progress: 0.7,
    ),
    DeckProgress(
      title: 'Animal Kingdom',
      cards: 30,
      progress: 0.45,
    ),
    DeckProgress(
      title: 'Food & Cooking',
      cards: 15,
      progress: 0.3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: decks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final deck = decks[index];
          return _DeckCard(deck: deck);
        },
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final DeckProgress deck;

  const _DeckCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${deck.cards} cards',
            style: const TextStyle(color: Colors.black54),
          ),
          const Spacer(),
          LinearProgressIndicator(
            value: deck.progress,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF7233FE)),
          ),
        ],
      ),
    );
  }
}
