import 'package:flash_card/data/deck_repository.dart';
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flash_card/widget/screens/add_deck_screen.dart';
import 'package:flash_card/widget/screens/flashcard.dart';
import 'package:flash_card/widget/screens/quiz_screen.dart';
import 'package:flash_card/widget/screens/water_sort_screen.dart';
import 'package:flash_card/services/ai_distractor_service.dart';
import 'package:flash_card/services/quiz_engine.dart';
import 'package:flash_card/services/quiz_prep_service.dart';
import 'package:flutter/material.dart';

enum _DeckAction { edit, delete }

enum _DeckListTab { created, completed }

enum _TestMode { quiz, waterSort }

class DecksScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueChanged<BottomNavItem>? onNavItemSelected;
  final DeckRepository repository;
  final QuizPrepService? quizPrepService;

  DecksScreen({
    super.key,
    this.showBottomNav = true,
    this.onNavItemSelected,
    DeckRepository? repository,
    this.quizPrepService,
  }) : repository = repository ?? deckRepository;

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  static const _accent = Color(0xFF7D5CFA);
  static const _mutedBackground = Color(0xFFF7F7FB);

  late final DeckRepository _repository;
  late final QuizPrepService _quizPrepService;
  AiDistractorService? _ownedAiService;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedDeckIds = {};

  List<Deck> _decks = [];
  bool _loading = true;
  _DeckListTab _activeTab = _DeckListTab.created;
  final QuizEngine _engine = const QuizEngine();

  QuizPrepService _buildDefaultQuizPrepService() {
    final ai = AiDistractorService();
    _ownedAiService = ai;
    return QuizPrepService(
      repository: _repository,
      distractorProvider: ai,
    );
  }

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;
    _quizPrepService = widget.quizPrepService ?? _buildDefaultQuizPrepService();
    _searchController.addListener(() {
      setState(() {});
    });
    _loadDecks();
  }

  @override
  void dispose() {
    _ownedAiService?.dispose();
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

  Future<void> _openQuizChooser(Deck deck) async {
    final choice = await showModalBottomSheet<_TestMode>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose test mode',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.list_alt_outlined),
                  title: const Text('Multiple choice'),
                  subtitle: const Text('Standard multiple choice'),
                  onTap: () => Navigator.of(context).pop(_TestMode.quiz),
                ),
                ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: const Text('Water Sort mini-game'),
                  subtitle: const Text('Color sort mini-game; answer to earn extra moves'),
                  onTap: () => Navigator.of(context).pop(_TestMode.waterSort),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null) return;

    final progress = ValueNotifier<double>(0);
    final dialog = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (context, value, __) {
          final percent = (value * 100).clamp(0, 100).toInt();
          return AlertDialog(
            title: const Text('Preparing questions'),
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

    List<DeckCard> preparedCards;
    try {
      preparedCards = await _quizPrepService.prepare(
        deck,
        onProgress: (v) => progress.value = v,
      );
    } on QuizPrepException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      await dialog;
      return;
    } catch (e) {
      if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz preparation failed: $e')));
      }
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      await dialog;
      return;
    } finally {
      progress.dispose();
    }

    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    await dialog;

    if (!mounted) return;

    deck.cards = preparedCards;
    _repository.markDeckOpened(deck.id);

    switch (choice) {
      case _TestMode.quiz:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              deckName: deck.title,
              cards: preparedCards,
            ),
          ),
        );
        break;
      case _TestMode.waterSort:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WaterSortScreen(
              deckName: deck.title,
              cards: preparedCards,
              engine: _engine,
            ),
          ),
        );
        break;
    }
  }

  void _handleMenuSelection(BuildContext context, _DeckAction action, Deck deck) async {
    switch (action) {
      case _DeckAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete deck?'),
            content: const Text('Are you sure you want to delete this deck?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await _repository.deleteDeck(deck.id);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deck deleted')));
            await _loadDecks();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
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
    const completionThreshold = 0.999; // tolerate floating errors
    final query = _searchController.text.trim();
    final normalizedQuery = _normalize(query);

    bool matchesQuery(Deck deck) {
      if (normalizedQuery.isEmpty) return true;
      final normalizedTitle = _normalize(deck.title);
      final normalizedDescription = _normalize(deck.description);
      final normalizedTags = _normalize(deck.tags.join(' '));
      return normalizedTitle.contains(normalizedQuery) ||
          normalizedDescription.contains(normalizedQuery) ||
          normalizedTags.contains(normalizedQuery);
    }

    bool matchesTab(Deck deck) {
      final isCompleted = deck.progress >= completionThreshold;
      switch (_activeTab) {
        case _DeckListTab.created:
          return !isCompleted;
        case _DeckListTab.completed:
          return isCompleted;
      }
    }

    return _decks.where((deck) => matchesQuery(deck) && matchesTab(deck)).toList();
  }

  String _normalize(String input) {
    const accentMap = <String, String>{
      // a
      "\u00e1": "a",
      "\u00e0": "a",
      "\u1ea3": "a",
      "\u00e3": "a",
      "\u1ea1": "a",
      "\u0103": "a",
      "\u1eaf": "a",
      "\u1eb1": "a",
      "\u1eb3": "a",
      "\u1eb5": "a",
      "\u1eb7": "a",
      "\u00e2": "a",
      "\u1ea5": "a",
      "\u1ea7": "a",
      "\u1ea9": "a",
      "\u1eab": "a",
      "\u1ead": "a",
      // d
      "\u0111": "d",
      // e
      "\u00e9": "e",
      "\u00e8": "e",
      "\u1ebb": "e",
      "\u1ebd": "e",
      "\u1eb9": "e",
      "\u00ea": "e",
      "\u1ebf": "e",
      "\u1ec1": "e",
      "\u1ec3": "e",
      "\u1ec5": "e",
      "\u1ec7": "e",
      // i
      "\u00ed": "i",
      "\u00ec": "i",
      "\u1ec9": "i",
      "\u0129": "i",
      "\u1ecb": "i",
      // o
      "\u00f3": "o",
      "\u00f2": "o",
      "\u1ecf": "o",
      "\u00f5": "o",
      "\u1ecd": "o",
      "\u00f4": "o",
      "\u1ed1": "o",
      "\u1ed3": "o",
      "\u1ed5": "o",
      "\u1ed7": "o",
      "\u1ed9": "o",
      "\u01a1": "o",
      "\u1edb": "o",
      "\u1edd": "o",
      "\u1edf": "o",
      "\u1ee1": "o",
      "\u1ee3": "o",
      // u
      "\u00fa": "u",
      "\u00f9": "u",
      "\u1ee7": "u",
      "\u0169": "u",
      "\u1ee5": "u",
      "\u01b0": "u",
      "\u1ee9": "u",
      "\u1eeb": "u",
      "\u1eed": "u",
      "\u1eef": "u",
      "\u1ef1": "u",
      // y
      "\u00fd": "y",
      "\u1ef3": "y",
      "\u1ef7": "y",
      "\u1ef9": "y",
      "\u1ef5": "y",
    };

    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune).toLowerCase();
      buffer.write(accentMap[char] ?? char);
    }
    return buffer.toString();
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
                      PopupMenuItem(value: _DeckAction.edit, child: Text('Chinh sua')),
                      PopupMenuItem(value: _DeckAction.delete, child: Text('Delete')),
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
                      onPressed: () => _openQuizChooser(deck),
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
                              onPressed: () => _openQuizChooser(deck),
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
