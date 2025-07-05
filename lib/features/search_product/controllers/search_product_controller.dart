import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/compare/controllers/compare_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/models/suggestion_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/services/search_product_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';

class SearchProductController with ChangeNotifier {
  final SearchProductServiceInterface? searchProductServiceInterface;
  SearchProductController({required this.searchProductServiceInterface});

  // State variables
  int _filterIndex = 0;
  List<String> _historyList = [];
  bool _isClear = true;
  bool _isLoading = false;
  bool _isSearching = false;
  ProductModel? searchedProduct;
  SuggestionModel? suggestionModel;
  List<String> nameList = [];
  List<int> idList = [];
  int selectedSearchedProductId = 0;
  final TextEditingController searchController = TextEditingController();

  // Filter variables
  bool filterApply = false;
  String sortText = 'low-high';
  double minPriceForFilter = AppConstants.minFilter;
  double maxPriceForFilter = AppConstants.maxFilter;
  double minFilterValue = 0;
  double maxFilterValue = 0;

  // Getters
  int get filterIndex => _filterIndex;
  List<String> get historyList => _historyList;
  bool get isClear => _isClear;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;

  // Search methods
  void cleanSearchProduct({bool notify = true}) {
    searchedProduct = null;
    _isClear = true;
    if (notify) notifyListeners();
  }

  Future<void> searchProduct({required String query, String? categoryIds, String? brandIds, String? sort, String? priceMin, String? priceMax, required int offset}) async {
    if (query.isEmpty) {
      cleanSearchProduct();
      return;
    }

    _isLoading = true;
    _isSearching = true;
    notifyListeners();

    try {
      ApiResponse apiResponse = await searchProductServiceInterface!.getSearchProductList(query, categoryIds, brandIds, sort ?? sortText, priceMin ?? minPriceForFilter.toStringAsFixed(2), priceMax ?? maxPriceForFilter.toStringAsFixed(2), offset);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        if (offset == 1) {
          searchedProduct = ProductModel.fromJson(apiResponse.response!.data);
        } else {
          searchedProduct = ProductModel(
            products: [...?searchedProduct?.products, ...?ProductModel.fromJson(apiResponse.response!.data).products],
            offset: ProductModel.fromJson(apiResponse.response!.data).offset,
            totalSize: ProductModel.fromJson(apiResponse.response!.data).totalSize,
          );
        }
        _isClear = false;
      } else {
        ApiChecker.checkApi(apiResponse);
        searchedProduct = null;
      }
    } catch (e) {
      debugPrint('Search error: $e');
      searchedProduct = null;
    } finally {
      _isLoading = false;
      _isSearching = false;
      notifyListeners();
    }
  }

  // Suggestion methods
  Future<void> getSuggestionProductName(String name) async {
    if (name.isEmpty) {
      suggestionModel = null;
      nameList.clear();
      idList.clear();
      notifyListeners();
      return;
    }

    ApiResponse apiResponse = await searchProductServiceInterface!.getSearchProductName(name);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      nameList.clear();
      idList.clear();
      suggestionModel = SuggestionModel.fromJson(apiResponse.response?.data);

      for (var product in suggestionModel!.products!) {
        nameList.add(product.name!);
        idList.add(product.id!);
      }
      notifyListeners();
    }
  }

  // History methods
  void initHistoryList() {
    _historyList = searchProductServiceInterface!.getSavedSearchProductName();
    notifyListeners();
  }

  Future<void> saveSearchAddress(String searchAddress) async {
    if (searchAddress.trim().isEmpty) return;

    await searchProductServiceInterface!.saveSearchProductName(searchAddress);
    if (!_historyList.contains(searchAddress)) {
      _historyList.insert(0, searchAddress);
      notifyListeners();
    }
  }

  Future<void> clearSearchAddress() async {
    await searchProductServiceInterface!.clearSavedSearchProductName();
    _historyList.clear();
    notifyListeners();
  }

  // Filter methods
  void setFilterIndex(int index) {
    _filterIndex = index;
    switch (index) {
      case 0:
        sortText = 'latest';
        break;
      case 1:
        sortText = 'a-z';
        break;
      case 2:
        sortText = 'z-a';
        break;
      case 3:
        sortText = 'low-high';
        break;
      case 4:
        sortText = 'high-low';
        break;
    }
    notifyListeners();
  }

  void setFilterApply() {
    filterApply = true;
    notifyListeners();
  }

  void setMinMaxPriceForFilter(RangeValues currentRangeValues) {
    minPriceForFilter = currentRangeValues.start;
    maxPriceForFilter = currentRangeValues.end;
    notifyListeners();
  }

  void setFilterValue(double min, double max) {
    minFilterValue = min;
    maxFilterValue = max;
  }

  // Product selection
  void setSelectedProductId(int index, int? compareId) {
    if (suggestionModel?.products?.isNotEmpty ?? false) {
      selectedSearchedProductId = suggestionModel!.products![index].id!;

      final compareController = Provider.of<CompareController>(Get.context!, listen: false);
      if (compareId != null) {
        compareController.replaceCompareList(compareId, selectedSearchedProductId);
      } else {
        compareController.addCompareList(selectedSearchedProductId);
      }
      notifyListeners();
    }
  }

  void disposeController() {
    searchController.dispose();
  }
}
