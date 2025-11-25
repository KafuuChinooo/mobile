import 'package:flash_card/Helper/router.dart';
import 'package:flash_card/data/deck_repository.dart';
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flutter/material.dart';

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
  final DeckRepository _repository = DeckRepository.instance;
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
    final result = await Navigator.of(context).pushNamed(AppRouter.addDeck);
    if (result == true) {
      await _loadDecks();
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
              'Your decks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    title: Text(deck.title),
                                    subtitle: Text(
                                      deck.description.isEmpty
                                          ? '${deck.cards.length} cards'
                                          : '${deck.cards.length} cards • ${deck.description}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {},
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
