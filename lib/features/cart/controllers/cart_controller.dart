// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/services/cart_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';

class CartController extends ChangeNotifier {
  final CartServiceInterface cartServiceInterface;

  List<CartModel> _cartList = [];
  List<bool> _isSelectedList = [];
  bool _cartLoading = false;
  bool _getData = true;
  bool _addToCartLoading = false;
  String? _updateQuantityErrorText;

  List<CartModel> get cartList => _cartList;
  List<bool> get isSelectedList => _isSelectedList;
  bool get cartLoading => _cartLoading;
  bool get getData => _getData;
  bool get addToCartLoading => _addToCartLoading;
  String? get addOrderStatusErrorText => _updateQuantityErrorText;

  CartController({required this.cartServiceInterface});

  void setCartData() {
    _getData = true;
    notifyListeners();
  }

  void getCartDataLoaded() {
    _getData = false;
    notifyListeners();
  }

  Future<void> getCartData(BuildContext context, {bool reload = true}) async {
    if (reload) {
      _cartLoading = true;
      notifyListeners();
    }

    try {
      final apiResponse = await cartServiceInterface.getList();
      if (apiResponse.response?.statusCode == 200) {
        _cartList = [];
        apiResponse.response?.data.forEach((cart) => _cartList.add(CartModel.fromJson(cart)));
        _isSelectedList = List<bool>.filled(_cartList.length, true);
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    } finally {
      _cartLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCartProductQuantity(int? key, int quantity, BuildContext context, bool increment, int index) async {
    try {
      if (increment) {
        _cartList[index].increment = true;
      } else {
        _cartList[index].decrement = true;
      }
      notifyListeners();

      final apiResponse = await cartServiceInterface.updateQuantity(key, quantity);
      if (apiResponse.response?.statusCode == 200) {
        showCustomSnackBar(apiResponse.response?.data['message'], context, isError: false);
        await getCartData(context, reload: false);
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    } finally {
      _cartList[index].increment = false;
      _cartList[index].decrement = false;
      notifyListeners();
    }
  }

  Future<ApiResponse> addToCartAPI(CartModelBody cart, BuildContext context, List<ChoiceOptions> choices, List<int>? variationIndexes) async {
    _addToCartLoading = true;
    notifyListeners();
    ApiResponse apiResponse = await cartServiceInterface!.addToCartListData(cart, choices, variationIndexes);
    _addToCartLoading = false;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Navigator.of(Get.context!).pop();
      _addToCartLoading = false;
      showCustomSnackBar(apiResponse.response!.data['message'], Get.context!, isError: false, isToaster: true);
      getCartData(Get.context!);
    } else {
      _addToCartLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<void> removeFromCart(int? key, int index) async {
    _cartList[index].decrement = true;
    notifyListeners();

    try {
      final apiResponse = await cartServiceInterface.delete(key!);
      if (apiResponse.response?.statusCode == 200) {
        await getCartData(Get.context!, reload: false);
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    } finally {
      _cartList[index].decrement = false;
      notifyListeners();
    }
  }
}
