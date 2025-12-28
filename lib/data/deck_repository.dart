import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flash_card/model/deck.dart';

abstract class DeckRepository {
  Future<List<Deck>> fetchDecks();
  Future<List<DeckCard>> fetchCards(String deckId);
  Future<void> addDeck(Deck deck);
  Future<void> updateDeck(Deck deck);
  Future<void> deleteDeck(String deckId);
  Future<void> markDeckOpened(String deckId);
  Future<void> updateDeckProgress(String deckId, double progress, int lastStudiedIndex);
  Future<void> updateCardDistractors(String deckId, String cardId, List<String> distractors);
}

final DeckRepository deckRepository = FirestoreDeckRepository();

class FirestoreDeckRepository implements DeckRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'flashcard',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _getDecksCollection() {
    return _firestore.collection('decks');
  }

  @override
  Future<List<Deck>> fetchDecks() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _getDecksCollection()
        .where('authorId', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Deck.fromJson(data);
    }).toList();
  }

  @override
  Future<List<DeckCard>> fetchCards(String deckId) async {
    final snapshot = await _getDecksCollection().doc(deckId).collection('cards').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = data['id'] ?? doc.id;
      return DeckCard.fromJson(data);
    }).toList();
  }

  @override
  Future<void> addDeck(Deck deck) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final docRef = _getDecksCollection().doc();
      final cards = deck.cards;

      final Deck fullDeck = Deck(
        id: docRef.id,
        title: deck.title,
        description: deck.description,
        authorId: user.uid,
        cardCount: cards.length,
        createdAt: DateTime.now(),
        isPublic: deck.isPublic,
        tags: deck.tags,
        category: deck.category,
        lastOpenedAt: null,
        progress: 0.0,
      );

      await docRef.set(fullDeck.toJson());

      final cardsCollection = docRef.collection('cards');
      for (var card in cards) {
        final cardDocRef = cardsCollection.doc();
        await cardDocRef.set(card.toJson());
      }
    } catch (e) {
      print('Error adding deck: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateDeck(Deck deck) async {
    try {
      final deckRef = _getDecksCollection().doc(deck.id);
      final cardsCollection = deckRef.collection('cards');

      final batch = _firestore.batch();

      batch.update(deckRef, deck.toJson(preserveCreatedAt: true));

      final existingCards = await cardsCollection.get();
      final remainingIds = existingCards.docs.map((d) => d.id).toSet();

      for (final card in deck.cards) {
        final cardRef = cardsCollection.doc(card.id);
        batch.set(cardRef, card.toJson(), SetOptions(merge: true));
        remainingIds.remove(card.id);
      }

      for (final obsoleteId in remainingIds) {
        batch.delete(cardsCollection.doc(obsoleteId));
      }

      await batch.commit();
    } catch (e) {
      print("Error updating deck: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    try {
      await _getDecksCollection().doc(deckId).delete();
    } catch (e) {
      print("Error deleting deck: $e");
      rethrow;
    }
  }

  @override
  Future<void> markDeckOpened(String deckId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _getDecksCollection().doc(deckId).update({
        'last_opened_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last opened: $e');
    }
  }

  @override
  Future<void> updateDeckProgress(String deckId, double progress, int lastStudiedIndex) async {
    try {
      await _getDecksCollection().doc(deckId).update({
        'progress': progress,
        'last_studied_index': lastStudiedIndex,
        'last_opened_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  @override
  Future<void> updateCardDistractors(String deckId, String cardId, List<String> distractors) async {
    try {
      await _getDecksCollection()
          .doc(deckId)
          .collection('cards')
          .doc(cardId)
          .update({'distractors': distractors});
    } catch (e) {
      print('Error updating distractors: $e');
    }
  }
}
