import 'package:flash_card/widget/screens/add_deck_screen.dart';
import 'package:flash_card/data/deck_repository.dart';
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flash_card/widget/screens/flashcard.dart';
import 'package:flutter/material.dart';

enum _DeckAction { edit, delete }

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
  final DeckRepository _repository = deckRepository;
  List<Deck> _decks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDecks();
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

  void _openFlashcard(Deck deck) {
    _repository.markDeckOpened(deck.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(deck: deck, showBackButton: true, showBottomNav: false),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Decks',
      currentItem: BottomNavItem.decks,
      showBottomNav: widget.showBottomNav,
      onNavItemSelected: widget.onNavItemSelected,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7233FE),
        onPressed: _openAddDeck,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your Decks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadDecks,
                      child: _decks.isEmpty
                          ? const SingleChildScrollView(
                              physics: AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: 300,
                                child: Center(
                                  child: Text(
                                    'No decks yet. Tap + to add one.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _decks.length,
                              itemBuilder: (context, index) {
                                final deck = _decks[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      deck.title,
                                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      deck.description.isEmpty
                                          ? '${deck.cardCount} cards'
                                          : '${deck.cardCount} cards • ${deck.description}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: PopupMenuButton<_DeckAction>(
                                      onSelected: (action) => _handleMenuSelection(context, action, deck),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: _DeckAction.edit,
                                          child: Text('Chỉnh sửa'),
                                        ),
                                        const PopupMenuItem(
                                          value: _DeckAction.delete,
                                          child: Text('Xóa'),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _openFlashcard(deck),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
