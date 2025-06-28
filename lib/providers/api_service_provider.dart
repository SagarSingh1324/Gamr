import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Create the ApiService provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
