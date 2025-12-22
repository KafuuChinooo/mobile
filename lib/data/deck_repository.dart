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

    try {
      final querySnapshot = await _getDecksCollection()
          .where('authorId', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Deck.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching decks: $e');
      return [];
    }
  }

  @override
  Future<List<DeckCard>> fetchCards(String deckId) async {
    try {
      final snapshot = await _getDecksCollection().doc(deckId).collection('cards').get();
      return snapshot.docs.map((doc) => DeckCard.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error fetching cards: $e');
      return [];
    }
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
       await _getDecksCollection().doc(deck.id).update(deck.toJson());
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
}
