import '../models/nursery.dart';
import '../models/plant.dart';
import '../models/plant_order.dart';
import '../services/nursery_service.dart';

abstract class NurseryRepository {
  Future<List<Nursery>> getNurseries();
  Future<Nursery?> getNurseryById(String id);
  Future<Nursery?> getUserNursery(String userId);
  Future<void> registerNursery(Nursery nursery);
  Future<void> updateNursery(Nursery nursery);
  Future<void> updateNurseryStatus(String nurseryId, String status);

  Future<List<Plant>> getPlants({String? nurseryId, String? category, String? query});
  Future<Plant?> getPlantById(String id);
  Future<void> addPlant(Plant plant);
  Future<void> updatePlant(Plant plant);
  Future<void> deletePlant(String plantId);

  Future<List<PlantOrder>> getAllOrders();
  Future<void> placeOrder(PlantOrder order);
  Future<List<PlantOrder>> getOrdersForUser(String userId);
  Future<List<PlantOrder>> getOrdersForNursery(String nurseryId);
  Future<void> updateOrderStatus(String orderId, String newStatus);

  Future<List<String>> getWishlist(String userId);
  Future<bool> isPlantInWishlist(String userId, String plantId);
  Future<bool> toggleWishlist(String userId, String plantId);
}

class NurseryRepositoryImpl implements NurseryRepository {
  NurseryRepositoryImpl({NurseryService? service}) : _service = service ?? NurseryService();

  final NurseryService _service;

  @override
  Future<List<Nursery>> getNurseries() => _service.getNurseries();

  @override
  Future<Nursery?> getNurseryById(String id) => _service.getNurseryById(id);

  @override
  Future<Nursery?> getUserNursery(String userId) => _service.getUserNursery(userId);

  @override
  Future<void> registerNursery(Nursery nursery) => _service.registerNursery(nursery);

  @override
  Future<void> updateNursery(Nursery nursery) => _service.updateNursery(nursery);

  @override
  Future<void> updateNurseryStatus(String nurseryId, String status) =>
      _service.updateNurseryStatus(nurseryId, status);

  @override
  Future<List<Plant>> getPlants({String? nurseryId, String? category, String? query}) =>
      _service.getPlants(nurseryId: nurseryId, category: category, query: query);

  @override
  Future<Plant?> getPlantById(String id) => _service.getPlantById(id);

  @override
  Future<void> addPlant(Plant plant) => _service.addPlant(plant);

  @override
  Future<void> updatePlant(Plant plant) => _service.updatePlant(plant);

  @override
  Future<void> deletePlant(String plantId) => _service.deletePlant(plantId);

  @override
  Future<List<PlantOrder>> getAllOrders() => _service.getAllOrders();

  @override
  Future<void> placeOrder(PlantOrder order) => _service.placeOrder(order);

  @override
  Future<List<PlantOrder>> getOrdersForUser(String userId) =>
      _service.getOrdersForUser(userId);

  @override
  Future<List<PlantOrder>> getOrdersForNursery(String nurseryId) =>
      _service.getOrdersForNursery(nurseryId);

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) =>
      _service.updateOrderStatus(orderId, newStatus);

  @override
  Future<List<String>> getWishlist(String userId) => _service.getWishlist(userId);

  @override
  Future<bool> isPlantInWishlist(String userId, String plantId) =>
      _service.isPlantInWishlist(userId, plantId);

  @override
  Future<bool> toggleWishlist(String userId, String plantId) =>
      _service.toggleWishlist(userId, plantId);
}
