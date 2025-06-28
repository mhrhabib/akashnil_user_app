import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/location/controllers/location_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/location/domain/models/prediction_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class LocationSearchDialogWidget extends StatelessWidget {
  final GoogleMapController? mapController;
  const LocationSearchDialogWidget({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Container(
      margin: const EdgeInsets.only(top: 80),
      alignment: Alignment.topCenter,
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 1170,
          child: TypeAheadField<PredictionModel>(
            suggestionsCallback: (pattern) async {
              return await Provider.of<LocationController>(context, listen: false).searchLocation(context, pattern);
            },
            builder: (context, controller, focusNode) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.streetAddress,
                decoration: InputDecoration(
                  hintText: getTranslated('search_location', context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(style: BorderStyle.none, width: 0),
                  ),
                  hintStyle: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  labelText: 'Location',
                ),
                style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeLarge),
              );
            },
            itemBuilder: (context, PredictionModel suggestion) {
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(
                  suggestion.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeLarge),
                ),
              );
            },
            onSelected: (PredictionModel suggestion) {
              Provider.of<LocationController>(context, listen: false).setLocation(suggestion.placeId, suggestion.description, mapController);
              Navigator.pop(context);
            },

            loadingBuilder: (context) => const Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Center(child: CircularProgressIndicator()),
            ),
            errorBuilder: (context, error) => Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Text(getTranslated('error_occurred', context) ?? 'An error occurred', style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
          ),
        ),
      ),
    );
  }
}
