import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'product_card.dart';

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
  List<Product> _products = [];
  String _errorMessage = '';
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final products = await _productService.loadProductsFromFirestore();
      
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading products: $e';
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> _manuallyUploadCsv() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      await _productService.uploadCsvToFirestore();
      await _loadProducts();
      
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

  List<Product> _getRecommendedProducts() {
    if (_products.isEmpty) return [];
    
    // Default set of products if no skin scores available
    if (widget.skinScores == null) {
      return _products.take(4).toList();
    }
    
    // Match products based on skin scores
    List<Product> matchedProducts = [];
    
    // Get skin concerns based on scores
    Set<String> skinConcerns = _productService.getSkinConcerns(widget.skinScores!);
    
    // Find products with matching tags
    for (var product in _products) {
      // Check if product tags match any of our skin concerns
      bool isMatch = false;
      for (var concern in skinConcerns) {
        if (product.tags.toLowerCase().contains(concern.toLowerCase())) {
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
              onPressed: _loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    List<Product> recommendedProducts = _getRecommendedProducts();
    
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
  final Product product;
  
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
    // Clean up the Cloudflare URL
    String imageUrl = '';
    if (product.imageUrl.isNotEmpty) {
      imageUrl = _cleanImageUrl(product.imageUrl);
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
                                product.name,
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
                  product.brand,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  product.price,
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