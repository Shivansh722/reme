import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<List<Product>> loadProductsFromFirestore() async {
    try {
      // Check if products collection exists in Firestore
      final productsCollection = _firestore.collection('products');
      final snapshot = await productsCollection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // No products in Firestore yet, upload CSV data
        await uploadCsvToFirestore();
      }
      
      // Now fetch products from Firestore
      final productsSnapshot = await productsCollection.get();
      final List<Product> loadedProducts = [];
      
      for (var doc in productsSnapshot.docs) {
        loadedProducts.add(Product.fromMap(doc.data()));
      }
      
      return loadedProducts;
    } catch (e) {
      print('Error loading products: $e');
      
      // Fall back to mock data if there's an error
      return _loadMockProducts();
    }
  }

  Future<void> uploadCsvToFirestore() async {
    try {
      // Load CSV file from assets
      print('Starting CSV upload...');
      final String csvData = await rootBundle.loadString('assets/data/LIPS.csv');
      print('CSV file loaded, size: ${csvData.length} bytes');
      
      // Debug first few characters to see the format
      print('CSV first 100 chars: ${csvData.substring(0, 100)}');
      
      // Parse CSV with proper configuration
      List<List<dynamic>> csvTable = const CsvToListConverter(
        shouldParseNumbers: false,  // Prevent parsing numbers to keep as strings
        fieldDelimiter: ',',        // Make sure comma is used as delimiter
        eol: '\n',                  // Set explicit end of line character
      ).convert(csvData);
      
      print('CSV parsed, rows: ${csvTable.length}');
      
      // Debug first few rows
      for (int i = 0; i < min(3, csvTable.length); i++) {
        print('Row $i: ${csvTable[i]}');
      }
      
      // Extract headers (first row)
      List<String> headers = csvTable[0].map((item) => item.toString()).toList();
      print('Headers: ${headers.join(", ")}');
      
      // Batch write for better performance
      WriteBatch batch = _firestore.batch();
      final productsCollection = _firestore.collection('products');
      
      int count = 0;
      // Convert rows to documents (starting from second row)
      for (int i = 1; i < csvTable.length; i++) {
        if (csvTable[i].isEmpty || csvTable[i].length < 3) continue; // Skip empty or incomplete rows
        count++;
        
        Map<String, dynamic> product = {};
        
        // Create a document with fields from CSV
        for (int j = 0; j < headers.length && j < csvTable[i].length; j++) {
          product[headers[j]] = csvTable[i][j].toString();
        }
        
        // Debug the product data
        if (count <= 2) {
          print('Product $count: $product');
        }
        
        // Add document to batch
        final docRef = productsCollection.doc();
        batch.set(docRef, product);
      }
      
      print('About to commit $count products to Firestore');
      // Commit the batch
      await batch.commit();
      print('CSV data uploaded to Firestore successfully');
    } catch (e) {
      print('Error uploading CSV to Firestore: $e');
      throw e; // Rethrow to handle in the calling function
    }
  }

  // Fallback to mock data if Firestore fails
  List<Product> _loadMockProducts() {
    // Mock data based on your CSV structure
    List<Map<String, dynamic>> mockData = [
      {
        "商品名": "マイルドオイルクレンジング",
        "ブランド名": "無印良品",
        "カテゴリ": "オイルクレンジング",
        "商品画像URL": "https://cloudflare.lipscosme.com/product/69b48fe1aad38403a1069fa2-1553263256.png",
        "商品詳細": "ブランド名 無印良品(MUJI) 容量・参考価格 50ml: 390円 200ml: 750円 400ml: 1,190円",
        "タグ": "コストパフォーマンス, 洗浄力, 持ち運び, 大容量, 保湿, さっぱり, 香り, 毛穴ケア, 毛穴カバー"
      },
      {
        "商品名": "メイク落とし パーフェクトオイル",
        "ブランド名": "ビオレ",
        "カテゴリ": "オイルクレンジング",
        "商品画像URL": "https://cloudflare.lipscosme.com/image/76e1b5100f74f55cd564b13c-1684910248.png",
        "商品詳細": "ブランド名 ビオレ(Biore) 容量・参考価格 230ml(本体): 1,694円 210ml(つめかえ用): 997円 390ml(つめかえ用): 1,540円",
        "タグ": "つっぱりにくい, 洗浄力, コストパフォーマンス, 保湿, 香り, さっぱり, 毛穴ケア, 毛穴カバー"
      },
      // Add more mock products as needed
    ];
    
    return mockData.map((map) => Product.fromMap(map)).toList();
  }
  
  Set<String> getSkinConcerns(Map<String, int> scores) {
    Set<String> concerns = {};
    
    // Map skin scores to relevant tags
    if ((scores['pores'] ?? 0) < 70) concerns.add('毛穴ケア');
    if ((scores['pores'] ?? 0) < 70) concerns.add('毛穴カバー');
    if ((scores['redness'] ?? 0) < 70) concerns.add('保湿');
    if ((scores['firmness'] ?? 0) < 70) concerns.add('大容量');
    if ((scores['sagging'] ?? 0) < 70) concerns.add('コストパフォーマンス');
    if ((scores['pimples'] ?? 0) < 70) concerns.add('洗浄力');
    
    return concerns;
  }
}