import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../map/model/place_autocomplete_model/place_autocomplete_model.dart';
import '../../map/model/place_details_model/place_details_model.dart';
import '../../map/utils/map_services.dart';

class CustomListView extends StatelessWidget {
  const CustomListView({
    super.key,
    required this.places,
    required this.mapServices,
    required this.onPlaceSelect,
  });

  final List<PlaceModel> places;
  final void Function(PlaceDetailsModel) onPlaceSelect;
  final MapServices mapServices;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightDarkColor,
      child: ListView.separated(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return ListTile(
            onTap: () async {
              var placeDetails = await mapServices.getPlaceDetails(
                placeId: places[index].placeId!,
              );
              onPlaceSelect(placeDetails);
            },
            title: Text(
              places[index].description!,
              style: AppTextStyle.text16BW(),
            ),
            leading: Icon(Icons.location_on, color: FasakhanstaBrand.text),
            // trailing: IconButton(
            //   onPressed: () async {
            //     // var placeDetails = await mapServices.getPlaceDetails(
            //     //     placeId: places[index].placeId!);
            //     // onPlaceSelect(placeDetails);
            //   },
            //   icon: Icon(Icons.arrow_circle_right_outlined,
            //       color: AppColor.whiteColor),
            // ),
          );
        },
        separatorBuilder: (context, index) {
          return const Divider(height: 0);
        },
        itemCount: places.length,
      ),
    );
  }
}
