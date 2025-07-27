import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Users collection reference
  CollectionReference get usersCollection => _firestore.collection('users');
  
  // User document reference
  DocumentReference getUserDocument(String userId) {
    return usersCollection.doc(userId);
  }
  
  // Create or update user data
  Future<void> saveUserData({
    required String userId,
    required String email,
    String? displayName,
    String? photoURL,
    String? provider,
  }) async {
    await getUserDocument(userId).set({
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'provider': provider,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  // Save skin analysis results
  Future<String> saveSkinAnalysisResults({
    required String userId,
    required Map<String, int> scores,
    required String analysisResult,
    String? imagePath,
  }) async {
    final userDoc = getUserDocument(userId);
    
    // First, ensure the user document exists
    await userDoc.set({
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // Create a subcollection for analysis history
    final analysisRef = await userDoc.collection('skinAnalysis').add({
      'scores': scores,
      'analysisResult': analysisResult,
      'imagePath': imagePath,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Update the user document with the latest analysis
    // Changed from update() to set() with merge: true
    await userDoc.set({
      'latestAnalysisId': analysisRef.id,
      'latestAnalysisDate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    return analysisRef.id;
  }
  
  // Get user's latest analysis
  Future<Map<String, dynamic>?> getLatestAnalysis(String userId) async {
    final userDoc = await getUserDocument(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    
    if (userData != null && userData.containsKey('latestAnalysisId')) {
      final analysisDoc = await getUserDocument(userId)
          .collection('skinAnalysis')
          .doc(userData['latestAnalysisId'])
          .get();
          
      return analysisDoc.data();
    }
    return null;
  }
  
  // Get user's analysis history
  Future<List<Map<String, dynamic>>> getAnalysisHistory(String userId, {required int limit}) async {
    final querySnapshot = await getUserDocument(userId)
        .collection('skinAnalysis')
        .orderBy('timestamp', descending: true)
        .get();
        
    return querySnapshot.docs
        .map((doc) => doc.data())
        .toList();
  }
  
  // Get paginated analysis history
  Future<List<Map<String, dynamic>>> getPaginatedAnalysisHistory(
    String userId, {
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    Query query = getUserDocument(userId)
      .collection('skinAnalysis')
      .orderBy('timestamp', descending: true)
      .limit(limit);
      
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    final querySnapshot = await query.get();
    
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Add the document ID to the data for reference
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}