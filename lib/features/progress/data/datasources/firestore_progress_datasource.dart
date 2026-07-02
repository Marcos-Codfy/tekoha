// lib/features/progress/data/datasources/firestore_progress_datasource.dart
// Camada: Data (Progress). Camada mais baixa — fala direto com o
// Cloud Firestore.
//
// ESTRUTURA PRONTA, INATIVA ate o login ser reativado (kBypassAuth).
// As regras de seguranca ja publicadas no projeto tekoha-d0179 exigem
// request.auth.uid == uid — ou seja, este datasource SO funciona com
// usuario autenticado (por design).

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProgressDataSource {
  final FirebaseFirestore _firestore;

  FirestoreProgressDataSource(this._firestore);

  /// Colecao coberta pelas security rules per-user (21/05/2026).
  static const String kCollection = 'user_progress';

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(kCollection).doc(uid);

  /// Mapa bruto do documento do usuario, ou null se nunca salvou.
  Future<Map<String, dynamic>?> fetch(String uid) async =>
      (await _doc(uid).get()).data();

  /// Grava com MERGE — campos nao presentes em [data] sao preservados.
  Future<void> save(String uid, Map<String, dynamic> data) =>
      _doc(uid).set(data, SetOptions(merge: true));
}
