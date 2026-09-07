import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> login(String email, String password) async {
    final cred = await auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    final token = await cred.user!.getIdTokenResult(true);
    if (token.claims?['admin'] != true) {
      await auth.signOut();
      throw Exception('This account is not an administrator. Add the admin custom claim first.');
    }
  }

  Future<void> logout() => auth.signOut();

  Stream<QuerySnapshot<Map<String, dynamic>>> collection(String name) =>
      db.collection(name).orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> users() => db.collection('users').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> listings() => db.collection('listings').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> orders() => db.collection('orders').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> verifications() => db.collection('verifications').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> walletTransactions() => db.collection('wallet_transactions').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> supportRequests() => db.collection('support_requests').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> disputes() => db.collection('disputes').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> topups() => db.collection('topups').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> withdrawals() => db.collection('withdrawals').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> bankChanges() => db.collection('bank_details_changes').orderBy('createdAt', descending: true).snapshots();

  Future<void> updateDoc(String collection, String id, Map<String, dynamic> data) =>
      db.collection(collection).doc(id).update(data);

  Future<void> setDoc(String collection, String id, Map<String, dynamic> data) =>
      db.collection(collection).doc(id).set(data, SetOptions(merge: true));

  Future<void> createNotification(String uid, String title, String body) =>
      db.collection('notifications').add({
        'userId': uid,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> approveVerification(String uid) async {
    await updateDoc('verifications', uid, {
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': auth.currentUser?.uid,
    });
  }

  Future<void> rejectVerification(String uid, String reason) async {
    await updateDoc('verifications', uid, {
      'status': 'rejected',
      'rejectionReason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': auth.currentUser?.uid,
    });
  }

  Future<void> setUserBanned(String uid, bool banned, {String? reason}) async {
    await updateDoc('users', uid, {
      'banned': banned,
      if (reason != null) 'banReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
