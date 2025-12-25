import 'dart:math';

import 'package:flash_card/data/deck_repository.dart';
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flash_card/widget/screens/add_deck_screen.dart';
import 'package:flash_card/widget/screens/flashcard.dart';
import 'package:flash_card/widget/screens/quiz_screen.dart';
import 'package:flash_card/services/ai_distractor_service.dart';
import 'package:flutter/material.dart';

enum _DeckAction { edit, delete }

enum _DeckListTab { created, completed }

class DecksScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueChanged<BottomNavItem>? onNavItemSelected;

  const DecksScreen({
    super.key,
    this.showBottomNav = true,
    this.onNavItemSelected,
  });

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  static const _accent = Color(0xFF7D5CFA);
  static const _mutedBackground = Color(0xFFF7F7FB);

  final DeckRepository _repository = deckRepository;
  final AiDistractorService _aiService = AiDistractorService();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedDeckIds = {};

  List<Deck> _decks = [];
  bool _loading = true;
  _DeckListTab _activeTab = _DeckListTab.created;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _loadDecks();
  }

  @override
  void dispose() {
    _aiService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    setState(() => _loading = true);
    final decks = await _repository.fetchDecks();
    if (mounted) {
      setState(() {
        _decks = decks;
        _loading = false;
      });
    }
  }

  Future<void> _openAddDeck() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddDeckScreen()),
    );
    if (result == true) {
      await _loadDecks();
    }
  }

  Future<void> _openEditDeck(Deck deck) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddDeckScreen(deckToEdit: deck)),
    );
    if (result == true) {
      await _loadDecks();
    }
  }

  void _openFlashcard(Deck deck) async {
    _repository.markDeckOpened(deck.id);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          deck: deck,
          showBackButton: true,
          showBottomNav: false,
        ),
      ),
    );
    // Reload decks to update progress UI
    await _loadDecks();
  }

  Future<void> _openQuiz(Deck deck) async {
    // Nếu danh sách cards rỗng (do fetchDecks chỉ lấy thông tin cơ bản), cần tải cards trước
    if (deck.cards.isEmpty && deck.cardCount > 0) {
      try {
        final loadedCards = await _repository.fetchCards(deck.id);
        deck.cards = loadedCards;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thẻ: $e')),
        );
        return;
      }
    }

    if (deck.cards.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 4 thẻ để bắt đầu kiểm tra!')),
      );
      return;
    }

    // Tạo distractors trước khi vào quiz
    await _prefetchDistractors(deck);

    _repository.markDeckOpened(deck.id);
    
    // Map Deck card model to QuizCard model
    final quizCards = deck.cards.map((c) => QuizCard(
      id: c.id,
      term: c.term,
      definition: c.definition,
      distractors: c.distractors,
    )).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          deckName: deck.title,
          cards: quizCards,
        ),
      ),
    );
  }

  Future<void> _prefetchDistractors(Deck deck) async {
    final needing = deck.cards.where((c) => (c.distractors?.length ?? 0) < 3).toList();
    if (needing.isEmpty) return;

    final total = needing.length;
    final progress = ValueNotifier<double>(0);

    // Start work in the background
    final work = () async {
      int processed = 0;
      const chunkSize = 10;
      for (var i = 0; i < needing.length; i += chunkSize) {
        final chunk = needing.sublist(i, min(i + chunkSize, needing.length));
        try {
          final result = await _aiService.generateBatch(chunk);
          for (final card in chunk) {
            final distractors = result[card.id];
            if (distractors != null && distractors.length >= 3) {
              final updated = card.copyWith(distractors: distractors);
              final idx = deck.cards.indexWhere((c) => c.id == card.id);
              if (idx != -1) {
                deck.cards[idx] = updated;
              }
              await _repository.updateCardDistractors(deck.id, card.id, distractors);
            }
          }
        } catch (e) {
          // Ignore errors here; fallback logic in quiz will handle missing distractors.
        } finally {
          processed += chunk.length;
          progress.value = processed / total;
        }
      }
      progress.value = 1.0;
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (context, value, __) {
          final percent = (value * 100).clamp(0, 100).toInt();
          return AlertDialog(
            title: const Text('Đang tạo đáp án nhiễu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: value.clamp(0.0, 1.0)),
                const SizedBox(height: 12),
                Text('$percent%'),
              ],
            ),
          );
        },
      ),
    );

    await work;
    progress.dispose();
  }

  void _handleMenuSelection(BuildContext context, _DeckAction action, Deck deck) async {
    switch (action) {
      case _DeckAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa bộ thẻ?'),
            content: const Text('Bạn có chắc chắn muốn xóa bộ thẻ này không?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xóa')),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await _repository.deleteDeck(deck.id);
            if (!mounted) return;
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bộ thẻ')));
            await _loadDecks();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
          }
        }
        break;
      case _DeckAction.edit:
        _openEditDeck(deck);
        break;
    }
  }

  Deck? get _latestReviewedDeck {
    if (_decks.isEmpty) return null;
    final sorted = List<Deck>.from(_decks)
      ..sort((a, b) {
        final aDate = a.lastOpenedAt ?? a.createdAt;
        final bDate = b.lastOpenedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
    return sorted.first;
  }

  List<Deck> get _filteredDecks {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _decks.where((deck) {
      final matchesQuery =
          query.isEmpty || deck.title.toLowerCase().contains(query) || deck.description.toLowerCase().contains(query);
      return matchesQuery;
    });

    if (_activeTab == _DeckListTab.completed) {
      return filtered.where((deck) => deck.lastOpenedAt != null).toList();
    }
    return filtered.toList();
  }

  double _progressForDeck(Deck deck) {
    if (deck.cardCount == 0) return 0;
    // Use the actual progress field from the model
    return deck.progress.clamp(0.0, 1.0);
  }

  void _toggleExpanded(String deckId) {
    setState(() {
      if (_expandedDeckIds.contains(deckId)) {
        _expandedDeckIds.remove(deckId);
      } else {
        _expandedDeckIds.add(deckId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Library',
      currentItem: BottomNavItem.decks,
      showBottomNav: widget.showBottomNav,
      showBackButton: !widget.showBottomNav,
      onNavItemSelected: widget.onNavItemSelected,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        onPressed: _openAddDeck,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      backgroundColor: _mutedBackground,
      body: RefreshIndicator(
        onRefresh: _loadDecks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildSearchField(),
            const SizedBox(height: 20),
            _buildLatestReviewSection(),
            const SizedBox(height: 24),
            _buildDecksSection(),
            if (_loading) const SizedBox(height: 200),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          hintText: 'Search',
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLatestReviewSection() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final deck = _latestReviewedDeck;
    if (deck == null) {
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'My lastest review',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'You have not reviewed any deck yet.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    final progress = _progressForDeck(deck);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My lastest review',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${deck.cardCount} cards',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_DeckAction>(
                    onSelected: (action) => _handleMenuSelection(context, action, deck),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: _DeckAction.edit, child: Text('Chỉnh sửa')),
                      PopupMenuItem(value: _DeckAction.delete, child: Text('Xóa')),
                    ],
                    child: const Icon(Icons.more_vert, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _Pill(label: '10 test'),
                  _Pill(label: '20 review'),
                ],
              ),
              const SizedBox(height: 16),
              _ProgressBar(value: progress, accent: _accent, percentLabel: '${(progress * 100).round()}%'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openQuiz(deck),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent,
                        side: const BorderSide(color: _accent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Test'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _openFlashcard(deck),
                      child: const Text('Learn'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My decks',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SegmentedTab(
              label: 'Created',
              selected: _activeTab == _DeckListTab.created,
              onTap: () => setState(() => _activeTab = _DeckListTab.created),
            ),
            const SizedBox(width: 10),
            _SegmentedTab(
              label: 'Completed',
              selected: _activeTab == _DeckListTab.completed,
              onTap: () => setState(() => _activeTab = _DeckListTab.completed),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredDecks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeTab == _DeckListTab.completed
                      ? 'You have not completed any deck yet.'
                      : 'No decks yet. Tap + to add one.',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 8),
                if (_activeTab == _DeckListTab.created)
                  TextButton(
                    onPressed: _openAddDeck,
                    child: const Text('Create deck'),
                  ),
              ],
            ),
          )
        else
          Column(
            children: _filteredDecks.map((deck) {
              final expanded = _expandedDeckIds.contains(deck.id);
              final progress = _progressForDeck(deck);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deck.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${deck.cardCount} cards',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _toggleExpanded(deck.id),
                            icon: Icon(
                              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _Pill(label: '0 test'),
                          _Pill(label: '0 review'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ProgressBar(
                        value: progress,
                        accent: _accent,
                        percentLabel: '${(progress * 100).round()}%',
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openEditDeck(deck),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => _openQuiz(deck),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _accent,
                                side: const BorderSide(color: _accent),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                              child: const Text('Test'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => _openFlashcard(deck),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Learn'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7D5CFA),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color accent;
  final String percentLabel;

  const _ProgressBar({
    required this.value,
    required this.accent,
    required this.percentLabel,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 10,
                  width: constraints.maxWidth * clamped,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          percentLabel,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SegmentedTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentedTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8E1FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF7D5CFA) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF7D5CFA) : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
