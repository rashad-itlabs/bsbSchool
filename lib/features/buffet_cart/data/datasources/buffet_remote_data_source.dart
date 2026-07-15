import '../models/product_model.dart';

abstract class BuffetRemoteDataSource {
  Future<List<ProductModel>> getProducts();

  /// Records the order on the backend. Returns nothing on success; the
  /// repository handles balance deduction separately.
  Future<void> submitOrder(Map<String, int> productIdToQty);
}

class BuffetRemoteDataSourceMock implements BuffetRemoteDataSource {
  @override
  Future<List<ProductModel>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      ProductModel(id: '1', name: 'Su (0.5L)', price: 0.50, category: 'İçki', emoji: '💧'),
      ProductModel(id: '2', name: 'Çay', price: 0.80, category: 'İçki', emoji: '☕'),
      ProductModel(id: '3', name: 'Sendviç', price: 2.50, category: 'Yemək', emoji: '🥪'),
      ProductModel(id: '4', name: 'Pizza dilimi', price: 3.00, category: 'Yemək', emoji: '🍕'),
      ProductModel(id: '5', name: 'Alma', price: 0.60, category: 'Meyvə', emoji: '🍎'),
      ProductModel(id: '6', name: 'Şokolad', price: 1.20, category: 'Şirniyyat', emoji: '🍫'),
      ProductModel(id: '7', name: 'Peçenye', price: 1.00, category: 'Şirniyyat', emoji: '🍪'),
      ProductModel(id: '8', name: 'Şirə', price: 1.50, category: 'İçki', emoji: '🧃'),
    ];
  }

  @override
  Future<void> submitOrder(Map<String, int> productIdToQty) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // No-op for the mock. A real implementation would POST the order.
  }
}
