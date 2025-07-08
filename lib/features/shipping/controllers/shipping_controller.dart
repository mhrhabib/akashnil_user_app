import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/models/selected_shipping_type.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/domain/models/chosen_shipping_method.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/domain/models/shipping_method_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/domain/models/shipping_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/domain/services/shipping_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:provider/provider.dart';

class ShippingController extends ChangeNotifier {
  final ShippingServiceInterface shippingServiceInterface;

  List<ChosenShippingMethodModel> _chosenShippingList = [];
  List<ShippingModel>? _shippingList;
  bool _isLoading = false;
  String? _selectedShippingType;
  final List<SelectedShippingType> _selectedShippingTypeList = [];

  List<ChosenShippingMethodModel> get chosenShippingList => _chosenShippingList;
  List<ShippingModel>? get shippingList => _shippingList;
  bool get isLoading => _isLoading;
  String? get selectedShippingType => _selectedShippingType;
  List<SelectedShippingType> get selectedShippingTypeList => _selectedShippingTypeList;

  ShippingController({required this.shippingServiceInterface});

  Future<void> getShippingMethod(BuildContext context, List<List<CartModel>> cartProdList) async {
    _isLoading = true;
    Provider.of<CartController>(context, listen: false).getCartDataLoaded();
    notifyListeners();

    try {
      final sellerIdList = cartProdList.map((e) => e[0].sellerId).toList();
      final sellerTypeList = cartProdList.map((e) => e[0].sellerIs).toList();
      final groupList = cartProdList.map((e) => e[0].cartGroupId).toList();

      _shippingList = List<ShippingModel>.generate(cartProdList.length, (index) => ShippingModel(-1, groupList[index], []));

      await getChosenShippingMethod(context);

      for (int i = 0; i < sellerIdList.length; i++) {
        final apiResponse = await shippingServiceInterface.getShippingMethod(sellerIdList[i], sellerTypeList[i]);

        if (apiResponse.response?.statusCode == 200) {
          final shippingMethodList = (apiResponse.response?.data as List).map((shipping) => ShippingMethodModel.fromJson(shipping)).toList();

          _shippingList![i].shippingMethodList = shippingMethodList;

          final chosenMethod = _chosenShippingList.firstWhere((cs) => cs.cartGroupId == groupList[i], orElse: () => ChosenShippingMethodModel());

          if (chosenMethod.shippingMethodId != null) {
            final index = shippingMethodList.indexWhere((method) => method.id == chosenMethod.shippingMethodId);
            _shippingList![i].shippingIndex = index;
          } else {
            // ✅ Step 4: If no method is chosen, set index 0 as default
            if (shippingMethodList.isNotEmpty) {
              _shippingList![i].shippingIndex = 0;
              calculateTotalShippingCost();
            }
          }
        } else {
          ApiChecker.checkApi(apiResponse);
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getAdminShippingMethodList(BuildContext context) async {
    _isLoading = true;
    Provider.of<CartController>(context, listen: false).getCartDataLoaded();
    notifyListeners();

    try {
      _shippingList = [ShippingModel(-1, '', [])];
      await getChosenShippingMethod(context);

      final apiResponse = await shippingServiceInterface.getShippingMethod(1, 'admin');
      if (apiResponse.response?.statusCode == 200) {
        final shippingMethodList = (apiResponse.response?.data as List).map((shipping) => ShippingMethodModel.fromJson(shipping)).toList();

        _shippingList![0].shippingMethodList = shippingMethodList;

        if (_chosenShippingList.isNotEmpty) {
          final index = shippingMethodList.indexWhere((method) => method.id == _chosenShippingList[0].shippingMethodId);
          _shippingList![0].shippingIndex = index;
        }
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getChosenShippingMethod(BuildContext context) async {
    try {
      final apiResponse = await shippingServiceInterface.getChosenShippingMethod();
      if (apiResponse.response?.statusCode == 200) {
        _chosenShippingList = (apiResponse.response?.data as List).map((shipping) => ChosenShippingMethodModel.fromJson(shipping)).toList();
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    } finally {
      notifyListeners();
    }
  }

  void setSelectedShippingMethod(int? index, int sellerIndex) {
    if (_shippingList != null && sellerIndex < _shippingList!.length) {
      _shippingList![sellerIndex].shippingIndex = index;
      calculateTotalShippingCost();
      notifyListeners();
    }
  }

  Future<void> addShippingMethod(BuildContext context, int? id, String? cartGroupId) async {
    try {
      final apiResponse = await shippingServiceInterface.addShippingMethod(id, cartGroupId);
      if (apiResponse.response?.statusCode == 200) {
        Navigator.pop(context);
        await getChosenShippingMethod(context);
        calculateTotalShippingCost();
        showCustomSnackBar(getTranslated('shipping_method_added_successfully', context), context, isError: false);
      } else {
        Navigator.pop(context);
        ApiChecker.checkApi(apiResponse);
      }
    } finally {
      notifyListeners();
    }
  }

  // In ShippingController
  double calculateTotalShippingCost() {
    double total = 0.0;

    if (_shippingList != null) {
      for (final shipping in _shippingList!) {
        final index = shipping.shippingIndex;
        if (index != null && index >= 0 && index < shipping.shippingMethodList!.length) {
          final method = shipping.shippingMethodList![index];
          total += method.cost ?? 0;
        }
      }
    }

    // Apply free shipping discounts if any
    return total;
  }

  // Add this method to force UI update
  void updateShippingCost() {
    notifyListeners();
  }
}
