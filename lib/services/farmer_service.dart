import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farmer.dart';
import '../models/hiring_request.dart';

class FarmerService {
  static const _customFarmersKey = 'baghbani.custom_farmers';
  static const _hiringRequestsKey = 'baghbani.hiring_requests';

  // 8-10 realistic sample farmers from agricultural hubs in Pakistan
  static final List<Farmer> _sampleFarmers = [
    const Farmer(
      id: 'farmer_1',
      userId: 'usr_f1',
      name: 'Muhammad Ali',
      location: 'Lahore, Punjab',
      address: 'Raiwind Road, Lahore',
      experienceYears: 8,
      skills: ['Crop Farming', 'Irrigation Management', 'Wheat & Rice'],
      services: ['Field Preparation', 'Sowing & Transplanting', 'Drip Irrigation Setup'],
      availability: true,
      rating: 4.9,
      reviewsCount: 28,
      dailyRate: 'Rs. 2,200 / day',
      phone: '0300 4561234',
      whatsapp: '0300 4561234',
      description:
          'Specialist in wheat, basmati rice, and modern crop management techniques. 8 years of hands-on experience handling laser land leveling, water distribution, and seasonal harvests.',
    ),
    const Farmer(
      id: 'farmer_2',
      userId: 'usr_f2',
      name: 'Tariq Mehmood',
      location: 'Sahiwal, Punjab',
      address: 'Chak 89/6-R, Sahiwal',
      experienceYears: 12,
      skills: ['Crop Farming', 'Farm Maintenance', 'Tractor Operation'],
      services: ['Soil Tillage', 'Fodder Cultivation', 'Harvesting Operations'],
      availability: true,
      rating: 4.8,
      reviewsCount: 41,
      dailyRate: 'Rs. 2,500 / day',
      phone: '0301 9876543',
      whatsapp: '0301 9876543',
      description:
          'Master farmer specializing in soil conditioning, crop rotation, and mechanized tillage. Extensive background working with mixed agricultural and livestock farms in Sahiwal division.',
    ),
    const Farmer(
      id: 'farmer_3',
      userId: 'usr_f3',
      name: 'Abdul Rehman',
      location: 'Multan, Punjab',
      address: 'Bosan Road, Multan',
      experienceYears: 10,
      skills: ['Crop Farming', 'Tree Plantation', 'Pest Management'],
      services: ['Orchard Pruning', 'Pest Control Spraying', 'Cotton Picking Supervision'],
      availability: true,
      rating: 4.9,
      reviewsCount: 35,
      dailyRate: 'Rs. 2,400 / day',
      phone: '0302 7654321',
      whatsapp: '0302 7654321',
      description:
          'Specialized in southern Punjab horticulture and cash crops. Expert in mango canopy management, integrated pest management (IPM), and whitefly prevention for cotton crops.',
    ),
    const Farmer(
      id: 'farmer_4',
      userId: 'usr_f4',
      name: 'Bashir Ahmad',
      location: 'Faisalabad, Punjab',
      address: 'Jaranwala Road, Faisalabad',
      experienceYears: 6,
      skills: ['Crop Farming', 'Irrigation Management', 'Farm Maintenance'],
      services: ['Canal Water Management', 'Fertilizer Application', 'Weed Removal'],
      availability: false,
      rating: 4.7,
      reviewsCount: 19,
      dailyRate: 'Rs. 2,000 / day',
      phone: '0303 1122334',
      whatsapp: '0303 1122334',
      description:
          'Hardworking, reliable farm specialist focused on sugarcane yield maximization and precise furrow irrigation scheduling. Currently engaged until next week.',
    ),
    const Farmer(
      id: 'farmer_5',
      userId: 'usr_f5',
      name: 'Ghulam Rasool',
      location: 'Sargodha, Punjab',
      address: 'Bhalwal Road, Sargodha',
      experienceYears: 15,
      skills: ['Tree Plantation', 'Pest Management', 'Irrigation Management'],
      services: ['Kinnow Pruning', 'Fruit Nursery Grafting', 'Drip Tube Installation'],
      availability: true,
      rating: 5.0,
      reviewsCount: 52,
      dailyRate: 'Rs. 2,800 / day',
      phone: '0304 9988776',
      whatsapp: '0304 9988776',
      description:
          'Veteran citrus grower with 15 years experience in Sargodha orchards. Expert in kinnow bud grafting, organic tree feeding, and seasonal die-back disease prevention.',
    ),
    const Farmer(
      id: 'farmer_6',
      userId: 'usr_f6',
      name: 'Imran Khan',
      location: 'Gujranwala, Punjab',
      address: 'Kamoke Road, Gujranwala',
      experienceYears: 5,
      skills: ['Crop Farming', 'Farm Maintenance'],
      services: ['Nursery Raising', 'Puddle Seeding', 'Field Fencing'],
      availability: true,
      rating: 4.6,
      reviewsCount: 14,
      dailyRate: 'Rs. 1,900 / day',
      phone: '0305 4433221',
      whatsapp: '0305 4433221',
      description:
          'Dedicated agricultural worker specializing in rice nursery management, field bund repair, and post-harvest grain cleaning.',
    ),
    const Farmer(
      id: 'farmer_7',
      userId: 'usr_f7',
      name: 'Zahid Hussain',
      location: 'Rahim Yar Khan, Punjab',
      address: 'Khanpur Road, Rahim Yar Khan',
      experienceYears: 9,
      skills: ['Irrigation Management', 'Crop Farming'],
      services: ['Micro-irrigation Setup', 'Bed Preparation', 'Weed Control'],
      availability: true,
      rating: 4.8,
      reviewsCount: 23,
      dailyRate: 'Rs. 2,300 / day',
      phone: '0306 5566778',
      whatsapp: '0306 5566778',
      description:
          'Experienced in precision water management and drought-tolerant farming systems. Trained in modern solar drip and sprinkler farm equipment.',
    ),
    const Farmer(
      id: 'farmer_8',
      userId: 'usr_f8',
      name: 'Muhammad Nawaz',
      location: 'Bahawalpur, Punjab',
      address: 'Yazman Road, Bahawalpur',
      experienceYears: 7,
      skills: ['Tree Plantation', 'Irrigation Management', 'Farm Maintenance'],
      services: ['Boundary Tree Planting', 'Tube-well Operations', 'Land Clearing'],
      availability: true,
      rating: 4.7,
      reviewsCount: 18,
      dailyRate: 'Rs. 2,100 / day',
      phone: '0307 8899001',
      whatsapp: '0307 8899001',
      description:
          'Specialist in desert-margin cultivation and shelterbelt tree plantations (Conocarpus, Neem, Eucalyptus). Reliable, skilled, and energetic worker.',
    ),
    const Farmer(
      id: 'farmer_9',
      userId: 'usr_f9',
      name: 'Sikandar Hayat',
      location: 'Okara, Punjab',
      address: 'Depalpur Road, Okara',
      experienceYears: 11,
      skills: ['Crop Farming', 'Pest Management'],
      services: ['Potato Sowing', 'Rotavator Tillage', 'Spraying Operations'],
      availability: true,
      rating: 4.9,
      reviewsCount: 31,
      dailyRate: 'Rs. 2,400 / day',
      phone: '0308 2233445',
      whatsapp: '0308 2233445',
      description:
          'Potato and grain crop specialist from Okara. Experienced in cold storage transport coordination, seed grading, and mechanized planter operation.',
    ),
  ];

  Future<List<Farmer>> getFarmers() async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_customFarmersKey) ?? [];
    final customFarmers = customRaw.map((e) {
      return Farmer.fromJson(jsonDecode(e) as Map<String, dynamic>);
    }).toList();

    return [...customFarmers, ..._sampleFarmers];
  }

  Future<void> addFarmer(Farmer farmer) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_customFarmersKey) ?? [];
    customRaw.insert(0, jsonEncode(farmer.toJson()));
    await prefs.setStringList(_customFarmersKey, customRaw);
  }

  Future<void> submitHiringRequest(HiringRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_hiringRequestsKey) ?? [];
    existing.insert(0, jsonEncode(request.toJson()));
    await prefs.setStringList(_hiringRequestsKey, existing);
  }

  Future<List<HiringRequest>> getHiringRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_hiringRequestsKey) ?? [];
    return existing
        .map((e) => HiringRequest.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }
}
