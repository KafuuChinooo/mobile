import 'package:flash_card/data/deck_repository.dart';
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flutter/material.dart';

// Màn hình này có thể dùng cho cả Thêm Mới và Chỉnh Sửa
class AddDeckScreen extends StatefulWidget {
  final Deck? deckToEdit; // Biến này chứa deck cần sửa, nếu là null thì là Thêm Mới

  const AddDeckScreen({super.key, this.deckToEdit});

  @override
  State<AddDeckScreen> createState() => _AddDeckScreenState();
}

class _AddDeckScreenState extends State<AddDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_CardFields> _cards = [];
  bool _saving = false;
  final DeckRepository _repository = deckRepository;
  bool get _isEditing => widget.deckToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingData();
    } else {
      // Nếu thêm mới, tạo 2 card rỗng
      _addCard();
      _addCard();
    }
  }

  Future<void> _loadExistingData() async {
    // Điền thông tin cơ bản
    _titleController.text = widget.deckToEdit!.title;
    _descriptionController.text = widget.deckToEdit!.description;

    // Tải danh sách card từ sub-collection
    try {
      final cards = await _repository.fetchCards(widget.deckToEdit!.id);
      if (!mounted) return;
      setState(() {
        for (var card in cards) {
          _cards.add(_CardFields.fromDeckCard(card));
        }
      });
    } catch (e) {
      print("Error loading cards for edit: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách thẻ: $e')),
        );
      }
    }
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
    if (_cards.length <= 1 && !_isEditing) return; // Giữ ít nhất 1 card nếu thêm mới
    setState(() {
      _cards.removeAt(index).dispose();
    });
  }

  Future<void> _saveDeck() async {
    if (_saving) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final cardData = _cards
        .map((card) => DeckCard(
              front: card.wordController.text.trim(), // Map word -> front
              back: card.answerController.text.trim(), // Map answer -> back
            ))
        .where((entry) => entry.front.isNotEmpty || entry.back.isNotEmpty)
        .toList();

    if (cardData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất một thẻ')),
      );
      return;
    }

    setState(() => _saving = true);
    
    final deckToSave = Deck(
      id: _isEditing ? widget.deckToEdit!.id : '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      authorId: _isEditing ? widget.deckToEdit!.authorId : '',
      cardCount: cardData.length,
      cards: cardData,
      createdAt: _isEditing ? widget.deckToEdit!.createdAt : DateTime.now(),
    );

    try {
      if (_isEditing) {
        await _repository.updateDeck(deckToSave);
      } else {
        await _repository.addDeck(deckToSave);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Đã cập nhật bộ thẻ' : 'Đã lưu bộ thẻ')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing ? 'Edit Deck' : 'Add Deck',
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
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 1,
              ),
              const SizedBox(height: 24),
              ..._buildCardFields(),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _addCard,
                  icon: const Icon(Icons.add, color: Color(0xFF7233FE)),
                  label: const Text('Add card', style: TextStyle(color: Color(0xFF7233FE))),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Card', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => _removeCard(index)),
                  ],
                ),
                TextFormField(
                  controller: card.wordController,
                  decoration: const InputDecoration(labelText: 'Words', labelStyle: TextStyle(color: Colors.black), border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: card.answerController,
                  decoration: const InputDecoration(labelText: 'Answer', labelStyle: TextStyle(color: Colors.black), border: UnderlineInputBorder()),
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
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.black), hintText: hintText, border: const UnderlineInputBorder()),
    );
  }
}

class _CardFields {
  final TextEditingController wordController;
  final TextEditingController answerController;

  _CardFields({String? word, String? answer}) : 
    wordController = TextEditingController(text: word),
    answerController = TextEditingController(text: answer);

  factory _CardFields.fromDeckCard(DeckCard card) {
    return _CardFields(word: card.front, answer: card.back); // Map front/back -> fields
  }

  void dispose() {
    wordController.dispose();
    answerController.dispose();
  }
}
