class Product {
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final String details;
  final String tags;
  final String description;
  final String price;
  
  Product({
    required this.name,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.details,
    required this.tags,
    this.description = '',
    this.price = '価格情報なし',
  });
  
  factory Product.fromMap(Map<String, dynamic> map) {
    String details = map['商品詳細'] ?? '';
    
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
    
    return Product(
      name: map['商品名'] ?? 'Unknown Product',
      brand: map['ブランド名'] ?? '',
      category: map['カテゴリ'] ?? '',
      imageUrl: map['商品画像URL'] ?? '',
      details: details,
      tags: map['タグ'] ?? '',
      description: description,
      price: price,
    );
  }
}