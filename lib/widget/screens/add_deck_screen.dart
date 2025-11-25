import 'package:flash_card/data/deck_repository.dart';
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flutter/material.dart';

class AddDeckScreen extends StatefulWidget {
  const AddDeckScreen({super.key});

  @override
  State<AddDeckScreen> createState() => _AddDeckScreenState();
}

class _AddDeckScreenState extends State<AddDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_CardFields> _cards = [];
  bool _saving = false;
  final DeckRepository _repository = DeckRepository.instance;

  @override
  void initState() {
    super.initState();
    _addCard();
    _addCard();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final card in _cards) {
      card.dispose();
    }
    super.dispose();
  }

  void _addCard() {
    setState(() {
      _cards.add(_CardFields());
    });
  }

  void _removeCard(int index) {
    if (_cards.length <= 1) return;
    setState(() {
      _cards.removeAt(index).dispose();
    });
  }

  Future<void> _saveDeck() async {
    if (_saving) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final cards = _cards
        .map(
          (card) => DeckCard(
            word: card.wordController.text.trim(),
            answer: card.answerController.text.trim(),
          ),
        )
        .where((entry) => entry.word.isNotEmpty || entry.answer.isNotEmpty)
        .toList();

    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one card')),
      );
      return;
    }

    setState(() => _saving = true);
    final deck = Deck(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      cards: cards,
      createdAt: DateTime.now(),
    );

    try {
      await _repository.addDeck(deck);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck saved')),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Add deck',
      showBackButton: true,
      showBottomNav: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.black),
          onPressed: _saveDeck,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledField(
                label: 'Title',
                controller: _titleController,
                hintText: 'Enter deck title',
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Description',
                controller: _descriptionController,
                hintText: 'Enter description',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ..._buildCardFields(),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _addCard,
                  icon: const Icon(Icons.add, color: Color(0xFF7233FE)),
                  label: const Text(
                    'Add card',
                    style: TextStyle(color: Color(0xFF7233FE)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7233FE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              if (_saving) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCardFields() {
    return List.generate(_cards.length, (index) {
      final card = _cards[index];
      return Padding(
        padding: EdgeInsets.only(bottom: index == _cards.length - 1 ? 0 : 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Card',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _removeCard(index),
                    ),
                  ],
                ),
                TextFormField(
                  controller: card.wordController,
                  decoration: const InputDecoration(
                    labelText: 'Words',
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: card.answerController,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    border: UnderlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final String? Function(String?)? validator;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            border: const UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _CardFields {
  final TextEditingController wordController = TextEditingController();
  final TextEditingController answerController = TextEditingController();

  void dispose() {
    wordController.dispose();
    answerController.dispose();
  }
}
