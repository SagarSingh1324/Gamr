import 'package:flutter/material.dart';
import '../models/explore_item.dart';      
import '../services/api_service.dart';      

class ExploreViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();  
  List<ExploreItem> _items = [];              
  List<ExploreItem> get items => _items;      
  bool _isLoading = false;                
  bool get isLoading => _isLoading;      
  String? _error;                              
  String? get error => _error;          

  Future<void> loadItems() async {
    _isLoading = true;      
    _error = null;          
    notifyListeners();      
    
    try {
      // Option 1: Using the method that returns raw JSON
      final jsonList = await _apiService.fetchExploreItems();
      _items = jsonList
          .map<ExploreItem>((json) => ExploreItem.fromJson(json))
          .toList();
      
      // Option 2: Using the method that returns parsed objects
      // _items = await _apiService.fetchExploreItemsParsed();
      
    } catch (e) {
      _error = e.toString();  
    } finally {
      _isLoading = false;      
      notifyListeners();        
    }
  }
  
  // Method to refresh data
  Future<void> refreshItems() async {
    await loadItems();
  }
  
  // Method to clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}