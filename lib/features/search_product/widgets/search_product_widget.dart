import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/widgets/search_filter_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_filter_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class SearchProductWidget extends StatefulWidget {
  const SearchProductWidget({super.key});

  @override
  State<SearchProductWidget> createState() => _SearchProductWidgetState();
}

class _SearchProductWidgetState extends State<SearchProductWidget> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProductController>(
      builder: (context, searchProvider, _) {
        return Column(
          children: [
            // Filter and Sort Header
            _buildFilterSortHeader(context, searchProvider),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Product List
            Expanded(child: _buildProductList(context, searchProvider)),
          ],
        );
      },
    );
  }

  Widget _buildFilterSortHeader(BuildContext context, SearchProductController searchProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Row(
        children: [
          Expanded(
            child: Text('${getTranslated('product_list', context)} (${searchProvider.searchedProduct?.totalSize ?? 0})', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          ),
          _buildSortButton(context, searchProvider),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          _buildFilterButton(context, searchProvider),
        ],
      ),
    );
  }

  Widget _buildSortButton(BuildContext context, SearchProductController searchProvider) {
    return InkWell(
      onTap: () {
        searchProvider.setFilterValue(searchProvider.minPriceForFilter, searchProvider.maxPriceForFilter);
        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => const SearchFilterBottomSheet());
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeExtraSmall),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Theme.of(context).hintColor.withOpacity(.25)),
            ),
            child: SizedBox(width: 25, height: 24, child: Image.asset(Images.sort, color: Provider.of<ThemeController>(context).darkTheme ? Colors.white : Theme.of(context).primaryColor)),
          ),
          if (searchProvider.filterApply) Positioned(top: 0, right: 0, child: CircleAvatar(radius: 5, backgroundColor: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, SearchProductController searchProvider) {
    return InkWell(
      onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => const ProductFilterDialog(fromShop: false)),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeExtraSmall),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Theme.of(context).hintColor.withOpacity(.25)),
            ),
            child: SizedBox(width: 25, height: 24, child: Image.asset(Images.dropdown, color: Provider.of<ThemeController>(context).darkTheme ? Colors.white : Theme.of(context).primaryColor)),
          ),
          if (searchProvider.filterApply) Positioned(top: 0, right: 0, child: CircleAvatar(radius: 5, backgroundColor: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }

  Widget _buildProductList(BuildContext context, SearchProductController searchProvider) {
    if (searchProvider.isLoading && searchProvider.searchedProduct == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchProvider.searchedProduct == null || searchProvider.searchedProduct!.products == null || searchProvider.searchedProduct!.products!.isEmpty) {
      return Center(
        child: Text(getTranslated('no_products_found', context) ?? 'No products found', style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await searchProvider.searchProduct(query: searchProvider.searchController.text, offset: 1);
      },
      child: PaginatedListView(
        scrollController: scrollController,
        onPaginate: (offset) async {
          await searchProvider.searchProduct(query: searchProvider.searchController.text, offset: offset!);
        },
        totalSize: searchProvider.searchedProduct?.totalSize,
        offset: searchProvider.searchedProduct?.offset,
        itemView: MasonryGridView.count(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(0),
          crossAxisCount: ResponsiveHelper.isTab(context) ? 3 : 2,
          shrinkWrap: true,
          itemCount: searchProvider.searchedProduct!.products!.length,
          itemBuilder: (BuildContext context, int index) {
            return ProductWidget(productModel: searchProvider.searchedProduct!.products![index]);
          },
        ),
      ),
    );
  }
}
