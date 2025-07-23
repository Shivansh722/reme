import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';

// Extract skin types from product data
List<String> extractSkinTypes(Map<String, dynamic> product) {
  // The logic below is an example - adjust based on your CSV structure
  List<String> skinTypes = [];
  
  // Example: Check if product tags contain skin type information
  String tags = product['タグ'] as String? ?? '';
  
  // Add relevant skin types based on tags
  if (tags.contains('乾燥肌')) skinTypes.add('Dry');
  if (tags.contains('脂性肌') || tags.contains('オイリー')) skinTypes.add('Oily');
  if (tags.contains('混合肌')) skinTypes.add('Combination');
  if (tags.contains('敏感肌')) skinTypes.add('Sensitive');
  if (tags.contains('普通肌') || tags.contains('ノーマル')) skinTypes.add('Normal');
  
  return skinTypes;
}

// Extract skin concerns from product data
List<String> extractSkinConcerns(Map<String, dynamic> product) {
  // Similar to above, adjust based on your CSV data
  List<String> concerns = [];
  
  String tags = product['タグ'] as String? ?? '';
  String description = product['商品詳細'] as String? ?? '';
  
  // Add concerns based on tags
  if (tags.contains('毛穴ケア') || description.contains('毛穴')) concerns.add('Pores');
  if (tags.contains('保湿') || description.contains('乾燥')) concerns.add('Dryness');
  if (tags.contains('ニキビ') || description.contains('ニキビ')) concerns.add('Acne');
  if (tags.contains('美白') || description.contains('シミ')) concerns.add('Pigmentation');
  if (tags.contains('しわ') || description.contains('エイジング')) concerns.add('Aging');
  
  return concerns;
}

Future<void> uploadCsvToFirebase(String filePath) async {
  final input = File(filePath).openRead();
  final fields = await input
      .transform(utf8.decoder)
      .transform(const CsvToListConverter())
      .toList();
  
  // Assuming first row contains headers
  final headers = fields[0];
  final data = fields.sublist(1);
  
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  
  for (var row in data) {
    final product = {
      for (var i = 0; i < headers.length; i++) 
        headers[i].toString(): row[i]
    };
    
    // Add skin type and concern fields
    product['suitableForSkinTypes'] = extractSkinTypes(product);
    product['skinConcerns'] = extractSkinConcerns(product);
    
    final docRef = firestore.collection('products').doc();
    batch.set(docRef, product);
  }
  
  await batch.commit();
  print('CSV uploaded to Firestore successfully');
}

// Function to fetch products based on user's skin type and concerns
Future<List<Map<String, dynamic>>> getRecommendedProducts(
    String userSkinType, List<String> userSkinConcerns) async {
  
  final productsRef = FirebaseFirestore.instance.collection('products');
  
  // Get products that match the user's skin type
  final snapshot = await productsRef
      .where('suitableForSkinTypes', arrayContains: userSkinType)
      .get();
      
  final products = snapshot.docs.map((doc) => doc.data()).toList();
  
  // Calculate match score for each product
  for (var product in products) {
    double matchScore = 0;
    
    // Base score for matching skin type
    matchScore += 50;
    
    // Additional score for addressing skin concerns
    final productConcerns = List<String>.from(product['skinConcerns'] ?? []);
    for (var concern in userSkinConcerns) {
      if (productConcerns.contains(concern)) {
        matchScore += 50 / userSkinConcerns.length; // Distribute remaining 50% across concerns
      }
    }
    
    product['matchScore'] = matchScore > 100 ? 100 : matchScore;
  }
  
  // Sort by match score
  products.sort((a, b) => (b['matchScore'] - a['matchScore']).toInt());
  
  return products;
}