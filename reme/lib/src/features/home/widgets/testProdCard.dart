import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';

class ProductRecommendationCard extends StatefulWidget {
  final Map<String, int>? skinScores;
  
  const ProductRecommendationCard({
    Key? key, 
    this.skinScores,
  }) : super(key: key);

  @override
  State<ProductRecommendationCard> createState() => _ProductRecommendationCardState();
}

class _ProductRecommendationCardState extends State<ProductRecommendationCard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Load products from Firestore
    _loadProductsFromFirestore();
  }

  Future<void> _loadProductsFromFirestore() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Check if products collection exists in Firestore
      final productsCollection = FirebaseFirestore.instance.collection('products');
      final snapshot = await productsCollection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // No products in Firestore yet, upload CSV data
        await _uploadCsvToFirestore();
      }
      
      // Now fetch products from Firestore
      final productsSnapshot = await productsCollection.get();
      final List<Map<String, dynamic>> loadedProducts = [];
      
      for (var doc in productsSnapshot.docs) {
        loadedProducts.add(doc.data());
      }
      
      setState(() {
        _products = loadedProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading products: $e';
        _isLoading = false;
      });
      print('Error: $e');
      
      // Fall back to mock data if there's an error
      _loadMockProducts();
    }
  }

  Future<void> _uploadCsvToFirestore() async {
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
      WriteBatch batch = FirebaseFirestore.instance.batch();
      final productsCollection = FirebaseFirestore.instance.collection('products');
      
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
  void _loadMockProducts() {
    // Mock data based on your CSV structure
    _products = [
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
      {
        "商品名": "オイルクレンジング・敏感肌用",
        "ブランド名": "無印良品",
        "カテゴリ": "オイルクレンジング",
        "商品画像URL": "https://cloudflare.lipscosme.com/product/9c5d991d67e7c97853d40fb7-1553264660.png",
        "商品詳細": "ブランド名 無印良品(MUJI) 容量・参考価格 200ml: 950円 400ml: 1,790円 50ml: 390円",
        "タグ": "大容量, コストパフォーマンス, つっぱりにくい, 洗浄力, 保湿, さっぱり, 毛穴ケア, 毛穴カバー"
      },
      {
        "商品名": "ニベア クレンジングオイル ディープクリア",
        "ブランド名": "ニベア",
        "カテゴリ": "オイルクレンジング",
        "商品画像URL": "https://cloudflare.lipscosme.com/image/faefba3398d629a9a905fabe-1645704343.png",
        "商品詳細": "ブランド名 ニベア(Nivea) 容量・参考価格 本体195ml: 1,430円 詰替170ml: 1,100円",
        "タグ": "洗浄力, つっぱりにくい, 毛穴ケア, 毛穴カバー, コストパフォーマンス, 保湿, 大容量, さっぱり, 香り"
      },
      {
        "商品名": "The クレンズ オイルメイク落とし",
        "ブランド名": "ビオレ",
        "カテゴリ": "オイルクレンジング",
        "商品画像URL": "https://cloudflare.lipscosme.com/image/cf570691b3a9ed36324c5cad-1739416373.png",
        "商品詳細": "ブランド名 ビオレ(Biore) 容量・参考価格 本体 190ml: 1,408円 詰替 280ml: 1,540円 ミニサイズ 50ml: 385円",
        "タグ": "つっぱりにくい, 洗浄力, 持ち運び, さっぱり, 香り, 毛穴ケア, 毛穴カバー, コストパフォーマンス, 大容量, 保湿"
      },
    ];
    setState(() {
      _isLoading = false;
    });
  }

  // Add a button to manually trigger CSV upload (useful for admin/testing)
  Future<void> _manuallyUploadCsv() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      await _uploadCsvToFirestore();
      
      // Refresh products from Firestore
      await _loadProductsFromFirestore();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV uploaded to Firestore successfully!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading CSV: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _getRecommendedProducts() {
    if (_products.isEmpty) return [];
    
    // Default set of products if no skin scores available
    if (widget.skinScores == null) {
      return _products.take(4).toList();
    }
    
    // Match products based on skin scores
    List<Map<String, dynamic>> matchedProducts = [];
    
    // Get skin concerns based on scores
    Set<String> skinConcerns = _getSkinConcerns(widget.skinScores!);
    
    // Find products with matching tags
    for (var product in _products) {
      String tags = product['タグ'] ?? '';
      
      // Check if product tags match any of our skin concerns
      bool isMatch = false;
      for (var concern in skinConcerns) {
        if (tags.toLowerCase().contains(concern.toLowerCase())) {
          isMatch = true;
          break;
        }
      }
      
      if (isMatch) {
        matchedProducts.add(product);
      }
    }
    
    // If we don't have enough matches, add some popular products
    if (matchedProducts.length < 4) {
      // Add products until we have at least 4
      for (var product in _products) {
        if (!matchedProducts.contains(product)) {
          matchedProducts.add(product);
          if (matchedProducts.length >= 4) break;
        }
      }
    }
    
    return matchedProducts.take(4).toList();
  }
  
  Set<String> _getSkinConcerns(Map<String, int> scores) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProductsFromFirestore,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    List<Map<String, dynamic>> recommendedProducts = _getRecommendedProducts();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'おすすめ製品',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // Uncomment for admin functionality
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: _manuallyUploadCsv,
                tooltip: 'Upload CSV to Firestore',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // First row of products
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: recommendedProducts.isNotEmpty
                    ? ProductCard(product: recommendedProducts[0])
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: recommendedProducts.length > 1
                    ? ProductCard(product: recommendedProducts[1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Second row of products
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: recommendedProducts.length > 2
                    ? ProductCard(product: recommendedProducts[2])
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: recommendedProducts.length > 3
                    ? ProductCard(product: recommendedProducts[3])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  
  const ProductCard({
    Key? key,
    required this.product,
  }) : super(key: key);
  
  // Clean up the Cloudflare URL by removing parameters
  String _cleanImageUrl(String url) {
    // Remove query parameters that might be causing issues
    final uri = Uri.parse(url);
    return uri.origin + uri.path;
  }
  
  @override
  Widget build(BuildContext context) {
    // Extract product details
    final String title = product['商品名'] ?? 'Unknown Product';
    final String brand = product['ブランド名'] ?? '';
    String imageUrl = product['商品画像URL'] ?? '';
    final String details = product['商品詳細'] ?? '';
    
    // Clean up the Cloudflare URL
    if (imageUrl.isNotEmpty) {
      imageUrl = _cleanImageUrl(imageUrl);
    }
    
    // Extract price from details if available
    String price = '価格情報なし';
    if (details.contains('参考価格')) {
      final priceRegex = RegExp(r'参考価格\s*([^:]*?円)');
      final match = priceRegex.firstMatch(details);
      if (match != null && match.groupCount >= 1) {
        price = match.group(1) ?? price;
      }
    }
    
    // Create a short description from details
    String description = '';
    if (details.isNotEmpty) {
      // Take the first sentence or first 50 characters
      description = details.split('。').first;
      if (description.length > 80) {
        description = description.substring(0, 80) + '...';
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 1,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image from $imageUrl: $error');
                        return Container(
                          color: Colors.grey[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40),
                              const SizedBox(height: 8),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
          ),
          
          // Product info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}