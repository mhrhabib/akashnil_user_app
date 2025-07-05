import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/widgets/partial_matched_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/widgets/search_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchProvider = Provider.of<SearchProductController>(context, listen: false);
      searchProvider.searchController.addListener(_onSearchTextChanged);
      searchProvider.initHistoryList();
      searchProvider.cleanSearchProduct(notify: false);
    });
  }

  void _onSearchTextChanged() {
    final searchProvider = Provider.of<SearchProductController>(context, listen: false);
    if (searchProvider.searchController.text.isEmpty) {
      searchProvider.cleanSearchProduct(notify: true);
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    final searchProvider = Provider.of<SearchProductController>(context, listen: false);
    searchProvider.searchController.removeListener(_onSearchTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('search_product', context)),
      body: Consumer<SearchProductController>(
        builder: (context, searchProvider, _) {
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).canvasColor,
                        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))],
                      ),
                      child: const SearchSuggestion(),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    // Show search results or history/popular tags
                    if (searchProvider.searchedProduct != null && !searchProvider.isClear)
                      searchProvider.searchedProduct!.products!.isNotEmpty ? const SearchProductWidget() : Center(child: Text(getTranslated('no_products_found', context) ?? 'No products found'))
                    else
                      _buildSearchHistoryAndPopularTags(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchHistoryAndPopularTags(BuildContext context) {
    final searchProvider = Provider.of<SearchProductController>(context, listen: false);
    final splashProvider = Provider.of<SplashController>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (searchProvider.historyList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(getTranslated('search_history', context)!, style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => searchProvider.clearSearchAddress(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                        child: Text(
                          getTranslated('clear_all', context)!,
                          style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Provider.of<ThemeController>(context).darkTheme ? Colors.white : Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
                Wrap(children: searchProvider.historyList.map((history) => _buildHistoryItem(context, history)).toList()),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
          child: Text(getTranslated('popular_tag', context)!, style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Wrap(children: splashProvider.configModel!.popularTags!.map((tag) => _buildPopularTagItem(context, tag.tag ?? '')).toList()),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, String history) {
    final searchProvider = Provider.of<SearchProductController>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Provider.of<ThemeController>(context).darkTheme ? Colors.grey.withValues(alpha: 0.2) : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1)),
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall - 3, horizontal: Dimensions.paddingSizeSmall),
        margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
        child: InkWell(
          onTap: () {
            searchProvider.searchController.text = history;
            searchProvider.searchProduct(query: history, offset: 1);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  history,
                  style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              InkWell(
                onTap: () {
                  searchProvider.historyList.remove(history);
                  //searchProvider.saveSearchProductName(history); // This will update the saved list
                  searchProvider.cleanSearchProduct(notify: true);
                },
                child: SizedBox(
                  width: 20,
                  child: Image.asset(Images.cancel, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5), fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularTagItem(BuildContext context, String tag) {
    final searchProvider = Provider.of<SearchProductController>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 0.5, color: Theme.of(context).primaryColor.withValues(alpha: 0.125)),
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall - 3, horizontal: Dimensions.paddingSizeSmall),
        margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
        child: InkWell(
          onTap: () {
            searchProvider.searchController.text = tag;
            searchProvider.searchProduct(query: tag, offset: 1);
          },
          child: Text(tag, style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
        ),
      ),
    );
  }
}
