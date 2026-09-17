import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MobileApiService {
  static final MobileApiService _instance = MobileApiService._internal();
  static MobileApiService get instance => _instance;

  MobileApiService._internal();

  String _baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'https://giftmart.hirall.com/api/v1');
  String? _token;
  String _organizationId = '67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad';
  String _branchId = '5309fdb8-4344-43eb-9b5b-e9cedd308470';

  String get baseUrl => _baseUrl;
  String? get token => _token;
  String get organizationId => _organizationId;
  String get branchId => _branchId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('hirall_mobile_api_url') ?? _detectDefaultBaseUrl();
    _token = prefs.getString('hirall_mobile_token');
    _organizationId = prefs.getString('hirall_mobile_org_id') ?? '67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad';
    _branchId = prefs.getString('hirall_mobile_branch_id') ?? '5309fdb8-4344-43eb-9b5b-e9cedd308470';
  }

  String _detectDefaultBaseUrl() {
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'https://giftmart.hirall.com/api/v1',
    );
  }

  Future<void> configure({
    String? baseUrl,
    String? token,
    String? organizationId,
    String? branchId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = baseUrl.trim();
      await prefs.setString('hirall_mobile_api_url', _baseUrl);
    }
    if (token != null && token.isNotEmpty) {
      _token = token.trim();
      await prefs.setString('hirall_mobile_token', _token!);
    }
    if (organizationId != null && organizationId.isNotEmpty) {
      _organizationId = organizationId.trim();
      await prefs.setString('hirall_mobile_org_id', _organizationId);
    }
    if (branchId != null && branchId.isNotEmpty) {
      _branchId = branchId.trim();
      await prefs.setString('hirall_mobile_branch_id', _branchId);
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  /// Query live products from AWS Backend Catalog
  Future<List<Map<String, dynamic>>> getProducts({
    String? search,
    String? barcode,
    String? orgId,
  }) async {
    final effectiveOrg = (orgId != null && orgId.isNotEmpty) ? orgId : _organizationId;
    try {
      final uri = Uri.parse('$_baseUrl/products').replace(
        queryParameters: {
          if (effectiveOrg.isNotEmpty) 'organization_id': effectiveOrg,
          if (search != null && search.isNotEmpty) 'search': search,
          if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        },
      );

      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('[MobileApiService] Error fetching products: $e');
    }
    return [];
  }

  /// Look up a single product by exact barcode from the AWS Backend
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final cleanCode = barcode.trim();
    if (cleanCode.isEmpty) return null;

    final results = await getProducts(barcode: cleanCode);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// Post Checkout Sale to Rust Backend
  Future<Map<String, dynamic>?> recordSale(Map<String, dynamic> salePayload) async {
    try {
      final uri = Uri.parse('$_baseUrl/pos/sales');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(salePayload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[MobileApiService] Error recording sale: $e');
    }
    return null;
  }
}
