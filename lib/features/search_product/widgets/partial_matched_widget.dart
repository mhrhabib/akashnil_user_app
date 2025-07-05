import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';
import 'package:substring_highlight/substring_highlight.dart';

class SearchSuggestion extends StatefulWidget {
  final bool fromCompare;
  final int? id;
  const SearchSuggestion({super.key, this.fromCompare = false, this.id});

  @override
  State<SearchSuggestion> createState() => _SearchSuggestionState();
}

class _SearchSuggestionState extends State<SearchSuggestion> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      child: Consumer<SearchProductController>(
        builder: (context, searchProvider, _) {
          return SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty || searchProvider.suggestionModel == null) {
                    return const Iterable<String>.empty();
                  }
                  return searchProvider.nameList.where((word) => word.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Material(
                    elevation: 4,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            searchProvider.searchController.text = option;
                            searchProvider.saveSearchAddress(option);
                            if (widget.fromCompare) {
                              searchProvider.setSelectedProductId(index, widget.id);
                              Navigator.of(context).pop();
                            } else {
                              searchProvider.searchProduct(query: option, offset: 1);
                              FocusScope.of(context).unfocus();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
                            child: SubstringHighlight(
                              text: option,
                              term: searchProvider.searchController.text,
                              textStyle: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.6), fontSize: Dimensions.fontSizeLarge),
                              textStyleHighlight: textMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeLarge),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        searchProvider.getSuggestionProductName(val.trim());
                      } else {
                        searchProvider.cleanSearchProduct(notify: true);
                      }
                    },
                    onFieldSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        searchProvider.saveSearchAddress(value.trim());
                        searchProvider.searchProduct(query: value.trim(), offset: 1);
                        FocusScope.of(context).unfocus();
                      } else {
                        showCustomSnackBar(getTranslated('enter_somethings', context), context);
                      }
                    },
                    style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      hintText: getTranslated('search_product', context),
                      suffixIcon: SizedBox(
                        width: controller.text.isNotEmpty ? 70 : 50,
                        child: Row(
                          children: [
                            if (controller.text.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  controller.clear();
                                  searchProvider.cleanSearchProduct(notify: true);
                                },
                                child: const Icon(Icons.clear, size: 20),
                              ),
                            InkWell(
                              onTap: () {
                                if (controller.text.trim().isNotEmpty) {
                                  focusNode.unfocus();
                                  searchProvider.saveSearchAddress(controller.text.trim());
                                  searchProvider.searchProduct(query: controller.text.trim(), offset: 1);
                                } else {
                                  showCustomSnackBar(getTranslated('enter_somethings', context), context);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Container(
                                  width: 40,
                                  height: 50,
                                  decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeSmall))),
                                  child: Padding(
                                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                    child: Image.asset(Images.search, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
