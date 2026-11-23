import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nursery.dart';
import '../models/plant.dart';
import '../models/plant_order.dart';

class NurseryService {
  static const _nurseriesKey = 'baghbani.nurseries';
  static const _plantsKey = 'baghbani.plants';
  static const _ordersKey = 'baghbani.orders';
  static const _wishlistKey = 'baghbani.wishlist';

  // Seed sample nurseries in Pakistan
  static final List<Nursery> _seedNurseries = [
    Nursery(
      id: 'nurs_1',
      ownerUserId: 'owner_asad',
      nurseryName: 'Green Haven Botanical Nursery',
      ownerName: 'Malik Asad',
      phone: '0300 4567890',
      address: '14-E Main Market, Gulberg III',
      city: 'Lahore',
      latitude: 31.5204,
      longitude: 74.3587,
      description:
          'Premier urban nursery in Lahore with over 300+ indoor, ornamental, and exotic house plants. Verified organic compost, terracotta pots, and plant care advice.',
      openingHours: '8:00 AM - 8:00 PM (Daily)',
      image: 'nursery_lahore',
      approvalStatus: 'Approved',
      rating: 4.9,
      reviewsCount: 42,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    Nursery(
      id: 'nurs_2',
      ownerUserId: 'owner_ghulam',
      nurseryName: 'Punjab Flora & Garden Center',
      ownerName: 'Haji Ghulam Nabi',
      phone: '0301 9876543',
      address: 'Link Road, Model Town C-Block',
      city: 'Lahore',
      latitude: 31.4826,
      longitude: 74.3182,
      description:
          'Renowned nursery specializing in citrus saplings, hybrid roses, outdoor garden trees, and seasonal flower beds with 20+ years of horticultural expertise.',
      openingHours: '7:30 AM - 7:30 PM (Daily)',
      image: 'nursery_modeltown',
      approvalStatus: 'Approved',
      rating: 4.8,
      reviewsCount: 38,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Nursery(
      id: 'nurs_3',
      ownerUserId: 'owner_ayesha',
      nurseryName: 'Botanical Bliss Nursery',
      ownerName: 'Dr. Ayesha Siddiqui',
      phone: '0302 3344556',
      address: 'Street 18, F-7/2',
      city: 'Islamabad',
      latitude: 33.7215,
      longitude: 73.0560,
      description:
          'Sustainable botanical nursery providing air-purifying indoor plants, rare succulents, bonsai trees, and expert landscaping consultations in the capital.',
      openingHours: '9:00 AM - 8:00 PM (Mon-Sat)',
      image: 'nursery_islamabad',
      approvalStatus: 'Approved',
      rating: 5.0,
      reviewsCount: 65,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Nursery(
      id: 'nurs_4',
      ownerUserId: 'owner_zafar',
      nurseryName: 'Sultani Agro & Fruit Saplings',
      ownerName: 'Chaudhry Zafar',
      phone: '0303 7788990',
      address: 'High Canal Road, Sahiwal Bypass',
      city: 'Sahiwal',
      latitude: 30.6682,
      longitude: 73.1114,
      description:
          'Certified agricultural fruit nursery offering certified olive, kinnow, guava, and mango graft saplings for commercial orchards and home growers.',
      openingHours: '7:00 AM - 6:30 PM (Daily)',
      image: 'nursery_sahiwal',
      approvalStatus: 'Approved',
      rating: 4.7,
      reviewsCount: 29,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  // Seed sample plants
  static final List<Plant> _seedPlants = [
    Plant(
      id: 'plant_1',
      nurseryId: 'nurs_1',
      nurseryName: 'Green Haven Botanical Nursery',
      name: 'Monstera Deliciosa',
      scientificName: 'Monstera deliciosa',
      category: 'Indoor',
      price: 1450,
      quantity: 18,
      height: '2 - 3 Feet',
      description:
          'Classic indoor tropical plant with iconic natural split leaves. Thrives in bright indirect light with moderate watering. Known for effective air purification.',
      images: ['monstera_1', 'monstera_2'],
      availability: true,
      rating: 4.9,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Plant(
      id: 'plant_2',
      nurseryId: 'nurs_1',
      nurseryName: 'Green Haven Botanical Nursery',
      name: 'Ficus Lyrata (Fiddle Leaf Fig)',
      scientificName: 'Ficus lyrata',
      category: 'Indoor',
      price: 2800,
      quantity: 8,
      height: '3 - 4 Feet',
      description:
          'Dramatic statement plant with large violin-shaped lustrous green foliage. Perfect centerpiece for living rooms, hallways, and modern offices.',
      images: ['ficus_1'],
      availability: true,
      rating: 4.8,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
    Plant(
      id: 'plant_3',
      nurseryId: 'nurs_2',
      nurseryName: 'Punjab Flora & Garden Center',
      name: 'Kinnow Citrus Grafted Sapling',
      scientificName: 'Citrus reticulata',
      category: 'Fruit Trees',
      price: 650,
      quantity: 45,
      height: '2.5 - 3.5 Feet',
      description:
          'High-yielding, disease-resistant grafted Punjab sweet kinnow sapling. Acclimatized for local soil conditions with fruit yield expected within two seasons.',
      images: ['kinnow_1'],
      availability: true,
      rating: 4.9,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Plant(
      id: 'plant_4',
      nurseryId: 'nurs_3',
      nurseryName: 'Botanical Bliss Nursery',
      name: 'Sansevieria Trifasciata (Snake Plant)',
      scientificName: 'Dracaena trifasciata',
      category: 'Indoor',
      price: 750,
      quantity: 32,
      height: '1.5 - 2 Feet',
      description:
          'Virtually indestructible hardy houseplant. NASA-validated top air cleaner that releases oxygen overnight. Requires very minimal watering.',
      images: ['snake_1'],
      availability: true,
      rating: 5.0,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Plant(
      id: 'plant_5',
      nurseryId: 'nurs_2',
      nurseryName: 'Punjab Flora & Garden Center',
      name: 'Rosa Damascena (Desi Gulab)',
      scientificName: 'Rosa damascena',
      category: 'Flowering',
      price: 350,
      quantity: 50,
      height: '1.5 Feet',
      description:
          'Intensely fragrant traditional pink damask rose. Continual bloomer, perfect for sunny gardens, decorative pots, and fresh floral tea preparations.',
      images: ['rose_1'],
      availability: true,
      rating: 4.8,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    Plant(
      id: 'plant_6',
      nurseryId: 'nurs_1',
      nurseryName: 'Green Haven Botanical Nursery',
      name: 'Bougainvillea Spectabilis (Purple)',
      scientificName: 'Bougainvillea spectabilis',
      category: 'Outdoor',
      price: 550,
      quantity: 26,
      height: '3 Feet',
      description:
          'Prolific sun-loving flowering vine with dazzling magenta bracts. Drought-tolerant once established; ideal for perimeter fences, gates, and pergolas.',
      images: ['bougainvillea_1'],
      availability: true,
      rating: 4.7,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    Plant(
      id: 'plant_7',
      nurseryId: 'nurs_3',
      nurseryName: 'Botanical Bliss Nursery',
      name: 'Medicinal Aloe Vera',
      scientificName: 'Aloe barbadensis miller',
      category: 'Succulents',
      price: 280,
      quantity: 40,
      height: '1 Foot',
      description:
          'Popular healing succulent packed with soothing gel. Excellent for balcony planters and bright sunny windowsills. Very low maintenance.',
      images: ['aloe_1'],
      availability: true,
      rating: 4.9,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Plant(
      id: 'plant_8',
      nurseryId: 'nurs_4',
      nurseryName: 'Sultani Agro & Fruit Saplings',
      name: 'Anwar Ratol Mango Graft',
      scientificName: 'Mangifera indica',
      category: 'Fruit Trees',
      price: 1100,
      quantity: 20,
      height: '3 - 4 Feet',
      description:
          'Famous aromatic sweet mango grafted variety of Punjab. Certified nursery graft on healthy deshi rootstock for fast field establishment.',
      images: ['mango_1'],
      availability: true,
      rating: 4.9,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Plant(
      id: 'plant_9',
      nurseryId: 'nurs_1',
      nurseryName: 'Green Haven Botanical Nursery',
      name: 'Peace Lily (Spathiphyllum)',
      scientificName: 'Spathiphyllum wallisii',
      category: 'Indoor',
      price: 950,
      quantity: 15,
      height: '1.5 Feet',
      description:
          'Elegant indoor favorite with glossy dark leaves and pure white bloom spathes. Outstanding at removing volatile toxins from room air.',
      images: ['peacelily_1'],
      availability: true,
      rating: 4.8,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Plant(
      id: 'plant_10',
      nurseryId: 'nurs_2',
      nurseryName: 'Punjab Flora & Garden Center',
      name: 'Jasmine Sambac (Motia)',
      scientificName: 'Jasminum sambac',
      category: 'Flowering',
      price: 300,
      quantity: 60,
      height: '1 - 2 Feet',
      description:
          'Beloved national flower fragrance shrub. Prolific white blossom clusters from early spring through autumn. Thrives in full to partial sun.',
      images: ['motia_1'],
      availability: true,
      rating: 5.0,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Plant(
      id: 'plant_11',
      nurseryId: 'nurs_3',
      nurseryName: 'Botanical Bliss Nursery',
      name: 'Areca Palm (Butterfly Palm)',
      scientificName: 'Dypsis lutescens',
      category: 'Indoor',
      price: 1850,
      quantity: 12,
      height: '3.5 - 4.5 Feet',
      description:
          'Feathery golden-green tropical fronds that provide instant lush warmth. Natural indoor air humidifier and safe for pet households.',
      images: ['areca_1'],
      availability: true,
      rating: 4.8,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Plant(
      id: 'plant_12',
      nurseryId: 'nurs_4',
      nurseryName: 'Sultani Agro & Fruit Saplings',
      name: 'Neem Tree Sapling',
      scientificName: 'Azadirachta indica',
      category: 'Outdoor',
      price: 400,
      quantity: 35,
      height: '3 Feet',
      description:
          'Indigenous hardy shade tree prized for medicinal properties, pest-deterring foliage, and strong drought resistance.',
      images: ['neem_1'],
      availability: true,
      rating: 4.8,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  // Seed sample orders
  static final List<PlantOrder> _seedOrders = [
    PlantOrder(
      id: 'ORD-98214',
      buyerUserId: 'demo_user',
      buyerName: 'Usman Ghani',
      buyerPhone: '0321 5566778',
      nurseryId: 'nurs_1',
      nurseryName: 'Green Haven Botanical Nursery',
      plantId: 'plant_1',
      plantName: 'Monstera Deliciosa',
      plantImage: 'monstera_1',
      quantity: 2,
      totalPrice: 2900,
      paymentMethod: 'Cash on Pickup',
      status: 'Ready for Pickup',
      pickupAddress: '14-E Main Market, Gulberg III, Lahore',
      pickupNotes: 'Will collect Saturday morning.',
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    PlantOrder(
      id: 'ORD-76123',
      buyerUserId: 'demo_user',
      buyerName: 'Usman Ghani',
      buyerPhone: '0321 5566778',
      nurseryId: 'nurs_2',
      nurseryName: 'Punjab Flora & Garden Center',
      plantId: 'plant_5',
      plantName: 'Rosa Damascena (Desi Gulab)',
      plantImage: 'rose_1',
      quantity: 4,
      totalPrice: 1400,
      paymentMethod: 'Cash on Pickup',
      status: 'Pending',
      pickupAddress: 'Link Road, Model Town C-Block, Lahore',
      pickupNotes: 'Please keep healthy potted samples.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // --------------------------------------------------
  // NURSERY METHODS
  // --------------------------------------------------

  Future<List<Nursery>> getNurseries() async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_nurseriesKey) ?? [];
    final custom = customRaw.map((e) {
      return Nursery.fromJson(jsonDecode(e) as Map<String, dynamic>);
    }).toList();

    return [...custom, ..._seedNurseries];
  }

  Future<Nursery?> getNurseryById(String id) async {
    final list = await getNurseries();
    try {
      return list.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Nursery?> getUserNursery(String userId) async {
    final list = await getNurseries();
    try {
      return list.firstWhere((n) => n.ownerUserId == userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> registerNursery(Nursery nursery) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_nurseriesKey) ?? [];
    // remove existing if any
    customRaw.removeWhere((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['ownerUserId'] == nursery.ownerUserId || map['id'] == nursery.id;
    });
    customRaw.insert(0, jsonEncode(nursery.toJson()));
    await prefs.setStringList(_nurseriesKey, customRaw);
  }

  Future<void> updateNurseryStatus(String nurseryId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_nurseriesKey) ?? [];
    final updated = <String>[];
    bool found = false;

    for (final raw in customRaw) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['id'] == nurseryId) {
        map['approvalStatus'] = status;
        updated.add(jsonEncode(map));
        found = true;
      } else {
        updated.add(raw);
      }
    }

    if (!found) {
      // check seed nurseries and create an override
      for (final seed in _seedNurseries) {
        if (seed.id == nurseryId) {
          final copy = seed.copyWith(approvalStatus: status);
          updated.insert(0, jsonEncode(copy.toJson()));
          break;
        }
      }
    }

    await prefs.setStringList(_nurseriesKey, updated);
  }

  Future<void> updateNursery(Nursery nursery) async {
    await registerNursery(nursery);
  }

  // --------------------------------------------------
  // PLANT METHODS
  // --------------------------------------------------

  Future<List<Plant>> getAllPlants() => getPlants();

  Future<List<Plant>> getPlants({
    String? nurseryId,
    String? category,
    String? query,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_plantsKey) ?? [];
    final custom = customRaw.map((e) {
      return Plant.fromJson(jsonDecode(e) as Map<String, dynamic>);
    }).toList();

    List<Plant> all = [...custom, ..._seedPlants];

    if (nurseryId != null && nurseryId.isNotEmpty) {
      all = all.where((p) => p.nurseryId == nurseryId).toList();
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      all = all.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      all = all.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.scientificName.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.nurseryName.toLowerCase().contains(q);
      }).toList();
    }

    return all;
  }

  Future<Plant?> getPlantById(String id) async {
    final list = await getPlants();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addPlant(Plant plant) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_plantsKey) ?? [];
    customRaw.insert(0, jsonEncode(plant.toJson()));
    await prefs.setStringList(_plantsKey, customRaw);
  }

  Future<void> updatePlant(Plant plant) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_plantsKey) ?? [];
    final updated = <String>[];
    bool replaced = false;

    for (final raw in customRaw) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['id'] == plant.id) {
        updated.add(jsonEncode(plant.toJson()));
        replaced = true;
      } else {
        updated.add(raw);
      }
    }

    if (!replaced) {
      updated.insert(0, jsonEncode(plant.toJson()));
    }

    await prefs.setStringList(_plantsKey, updated);
  }

  Future<void> deletePlant(String plantId) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_plantsKey) ?? [];
    customRaw.removeWhere((raw) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['id'] == plantId;
    });
    await prefs.setStringList(_plantsKey, customRaw);
  }

  // --------------------------------------------------
  // ORDER METHODS
  // --------------------------------------------------

  Future<List<PlantOrder>> getAllOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_ordersKey) ?? [];
    final custom = customRaw.map((e) {
      return PlantOrder.fromJson(jsonDecode(e) as Map<String, dynamic>);
    }).toList();

    return [...custom, ..._seedOrders];
  }

  Future<void> placeOrder(PlantOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_ordersKey) ?? [];
    customRaw.insert(0, jsonEncode(order.toJson()));
    await prefs.setStringList(_ordersKey, customRaw);
  }

  Future<List<PlantOrder>> getOrdersForUser(String userId) async {
    final list = await getAllOrders();
    return list.where((o) => o.buyerUserId == userId || o.buyerUserId == 'demo_user').toList();
  }

  Future<List<PlantOrder>> getOrdersForNursery(String nurseryId) async {
    final list = await getAllOrders();
    return list.where((o) => o.nurseryId == nurseryId).toList();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_ordersKey) ?? [];
    final updated = <String>[];
    bool found = false;

    for (final raw in customRaw) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['id'] == orderId) {
        map['status'] = newStatus;
        updated.add(jsonEncode(map));
        found = true;
      } else {
        updated.add(raw);
      }
    }

    if (!found) {
      for (final seed in _seedOrders) {
        if (seed.id == orderId) {
          final copy = seed.copyWith(status: newStatus);
          updated.insert(0, jsonEncode(copy.toJson()));
          break;
        }
      }
    }

    await prefs.setStringList(_ordersKey, updated);
  }

  // --------------------------------------------------
  // WISHLIST METHODS
  // --------------------------------------------------

  Future<List<String>> getWishlist(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_wishlistKey}_$userId') ?? ['plant_1', 'plant_4'];
  }

  Future<bool> isPlantInWishlist(String userId, String plantId) async {
    final list = await getWishlist(userId);
    return list.contains(plantId);
  }

  Future<bool> toggleWishlist(String userId, String plantId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getWishlist(userId);
    final key = '${_wishlistKey}_$userId';
    bool nowInWishlist = false;

    if (list.contains(plantId)) {
      list.remove(plantId);
      nowInWishlist = false;
    } else {
      list.add(plantId);
      nowInWishlist = true;
    }

    await prefs.setStringList(key, list);
    return nowInWishlist;
  }
}
