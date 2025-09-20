import 'package:flutter/material.dart';
import 'package:my_pro9/services/api_service.dart';
import 'package:my_pro9/models/product.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Product")),
      body: FutureBuilder<Product>(
        future: fetchProduct(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final product = snapshot.data!;
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Image.network(product.image.url, height: 200, fit: BoxFit.cover),
              SizedBox(height: 16),
              Text(product.name,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(product.description),
              SizedBox(height: 12),
              Text("Series: ${product.series}"),
              Text("SKU: ${product.SKU}"),
              Text("Unit: ${product.unit}"),
              SizedBox(height: 12),
              Text("Ingredients: ${product.ingredients.join(", ")}"),
              SizedBox(height: 12),
              Text("Toppings: ${product.toppings.join(", ")}"),
              SizedBox(height: 12),
              Text("Sizes:"),
              ...product.sizes.map((s) =>
                  Text("${s.label} - \$${s.price.toStringAsFixed(2)}")),
              SizedBox(height: 12),
              Text("Fasting Friendly: ${product.isFastingFriendly ? "Yes" : "No"}"),
            ],
          );
        },
      ),
    );
  }
}
