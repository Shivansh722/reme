import 'package:flutter/material.dart';

class ProductCard extends StatefulWidget {
  final String title;
  final String description;
  final String price;

  const ProductCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.45,
      child: Card(
        elevation: 0,
        color: Colors.grey[50],
        child: Column(
          children: [
            // Position for the heart icon
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLiked = !_isLiked;
                    });
                  },
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.pink : Colors.grey[400],
                    size: 24,
                  ),
                ),
              ),
            ),
            
            // Image separate from the heart icon
            Image.asset(
              'lib/assets/images/prod1.png',
              height: 160,
              width: double.infinity,
              fit: BoxFit.fill,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      widget.price,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

