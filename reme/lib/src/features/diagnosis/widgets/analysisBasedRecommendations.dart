import 'package:flutter/material.dart';
import 'package:reme/src/features/home/models/product.dart';
import 'package:reme/src/features/home/services/product_service.dart';
import 'package:reme/src/features/home/widgets/product_card.dart';

class AnalysisBasedRecommendations extends StatefulWidget {
  final Map<String, int> skinScores;
  
  const AnalysisBasedRecommendations({
    Key? key, 
    required this.skinScores,
  }) : super(key: key);

  @override
  State<AnalysisBasedRecommendations> createState() => _AnalysisBasedRecommendationsState();
}

class _AnalysisBasedRecommendationsState extends State<AnalysisBasedRecommendations> {
  bool _isLoading = true;
  List<Product> _recommendedProducts = [];
  String _errorMessage = '';
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _loadRecommendedProducts();
  }

  Future<void> _loadRecommendedProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // First check if we need to upload CSV data
      final productsCollection = await _productService.loadProductsFromFirestore();
      if (productsCollection.isEmpty) {
        // Try uploading the CSV if no products found
        await _productService.uploadCsvToFirestore();
      }
      
      // Now fetch all products 
      final allProducts = await _productService.loadProductsFromFirestore();
      
      if (allProducts.isEmpty) {
        setState(() {
          _errorMessage = '製品が見つかりませんでした';
          _isLoading = false;
        });
        return;
      }
      
      // Get skin concerns based on analysis scores
      final concerns = _getSkinConcernsFromScores(widget.skinScores);
      
      print('Skin concerns identified: $concerns');
      print('Total products loaded: ${allProducts.length}');
      
      // Filter products based on skin concerns
      List<Product> matchedProducts = [];
      
      // First pass: find products that match multiple concerns (highest priority)
      for (var product in allProducts) {
        int matchCount = 0;
        for (var concern in concerns) {
          if (product.tags.toLowerCase().contains(concern.toLowerCase())) {
            matchCount++;
          }
        }
        
        if (matchCount > 1) {
          matchedProducts.add(product);
          print('Multi-match found: ${product.name} (${matchCount} matches)');
        }
      }
      
      // Second pass: add products that match at least one concern
      if (matchedProducts.length < 4) {
        for (var product in allProducts) {
          if (!matchedProducts.contains(product)) {
            for (var concern in concerns) {
              if (product.tags.toLowerCase().contains(concern.toLowerCase())) {
                matchedProducts.add(product);
                print('Single match found: ${product.name} (matched: $concern)');
                break;
              }
            }
          }
          
          if (matchedProducts.length >= 4) break;
        }
      }
      
      // Fill remaining slots with random products if needed
      if (matchedProducts.length < 4) {
        // Shuffle the products to get random ones
        final remainingProducts = allProducts
            .where((p) => !matchedProducts.contains(p))
            .toList()
          ..shuffle();
            
        for (var product in remainingProducts) {
          matchedProducts.add(product);
          print('Added random product: ${product.name}');
          if (matchedProducts.length >= 4) break;
        }
      }
      
      // Take exactly 4 products or fewer if we don't have enough
      final finalProducts = matchedProducts.take(4).toList();
      
      print('Final recommendations: ${finalProducts.map((p) => p.name).join(', ')}');
      
      setState(() {
        _recommendedProducts = finalProducts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recommended products: $e');
      setState(() {
        _errorMessage = 'Error loading recommended products: $e';
        _isLoading = false;
      });
    }
  }

  // Get skin concerns based on analysis scores
  Set<String> _getSkinConcernsFromScores(Map<String, int> scores) {
    Set<String> concerns = {};
    
    // Map each skin issue to relevant tags that would be in the CSV
    if ((scores['pores'] ?? 100) < 70) {
      concerns.add('毛穴ケア');
      concerns.add('毛穴カバー');
    }
    
    if ((scores['redness'] ?? 100) < 70) {
      concerns.add('敏感肌');
      concerns.add('保湿');
      concerns.add('低刺激');
    }
    
    if ((scores['pimples'] ?? 100) < 70) {
      concerns.add('ニキビケア');
      concerns.add('洗浄力');
      concerns.add('抗炎症');
    }
    
    if ((scores['firmness'] ?? 100) < 70) {
      concerns.add('ハリ');
      concerns.add('弾力');
      concerns.add('コラーゲン');
    }
    
    if ((scores['sagging'] ?? 100) < 70) {
      concerns.add('たるみ');
      concerns.add('リフトアップ');
    }
    
    if ((scores['dark spots'] ?? 100) < 70) {
      concerns.add('美白');
      concerns.add('シミケア');
      concerns.add('ブライトニング');
    }
    
    // Always include some general tags to ensure matches
    concerns.add('コストパフォーマンス');
    concerns.add('人気');
    
    return concerns;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRecommendedProducts,
                child: const Text('再試行'),
              ),
              // Add a button to manually upload CSV
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  try {
                    setState(() {
                      _isLoading = true;
                    });
                    await _productService.uploadCsvToFirestore();
                    await _loadRecommendedProducts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('製品データを更新しました')),
                    );
                  } catch (e) {
                    setState(() {
                      _errorMessage = 'CSV更新エラー: $e';
                      _isLoading = false;
                    });
                  }
                },
                child: const Text('製品データを更新'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_recommendedProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('おすすめ製品が見つかりませんでした。'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRecommendedProducts,
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Display available products in a grid
    return Column(
      children: [
        // First row of products
        Row(
          children: [
            Expanded(
              child: _recommendedProducts.isNotEmpty
                  ? ProductCard(product: _recommendedProducts[0])
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _recommendedProducts.length > 1
                  ? ProductCard(product: _recommendedProducts[1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Second row of products
        Row(
          children: [
            Expanded(
              child: _recommendedProducts.length > 2
                  ? ProductCard(product: _recommendedProducts[2])
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _recommendedProducts.length > 3
                  ? ProductCard(product: _recommendedProducts[3])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}