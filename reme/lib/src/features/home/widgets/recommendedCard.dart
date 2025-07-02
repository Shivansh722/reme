import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;

  const ProductCard({
    required this.title,
    required this.description,
    required this.price,
  });

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
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.grey[400],
                    size: 24,
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
                      title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                  ),
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      price,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
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

