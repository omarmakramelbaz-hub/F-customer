import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/address_lookup_service.dart';
import '../../../../helpers/utils/location_service.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_loading/custome_dots_loading.dart';
import '../../map/model/place_autocomplete_model/place_autocomplete_model.dart';
import '../../map/utils/google_maps_place_service.dart';

/// Callback function invoked with the selected latitude and longitude when navigating back.
typedef OnBackCallback = void Function(double lat, double lng);

/// Represents the current location state
@immutable
class LocationState {
  final double? latitude;
  final double? longitude;
  final List<Placemark>? placemarks;
  final bool isLoading;
  final String? error;

  const LocationState({this.latitude, this.longitude, this.placemarks, this.isLoading = false, this.error});

  LocationState copyWith({
    double? latitude,
    double? longitude,
    List<Placemark>? placemarks,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placemarks: placemarks ?? this.placemarks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get hasValidCoordinates => latitude != null && longitude != null;

  LatLng get latLng => LatLng(latitude ?? 0, longitude ?? 0);
}

/// Represents the search state
@immutable
class SearchState {
  final List<PlaceModel> results;
  final bool isVisible;
  final bool isLoading;
  final String? error;

  const SearchState({this.results = const [], this.isVisible = false, this.isLoading = false, this.error});

  SearchState copyWith({List<PlaceModel>? results, bool? isVisible, bool? isLoading, String? error}) {
    return SearchState(
      results: results ?? this.results,
      isVisible: isVisible ?? this.isVisible,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  SearchState hide() => copyWith(isVisible: false, results: []);
  SearchState show() => copyWith(isVisible: true);
  SearchState loading() => copyWith(isLoading: true, error: null);
  SearchState withResults(List<PlaceModel> results) => copyWith(results: results, isLoading: false, isVisible: true);
  SearchState withError(String error) => copyWith(error: error, isLoading: false);
}

/// Arguments for the map screen, including a callback for when the user navigates back.
@immutable
class MapScreenArgs {
  /// Callback function invoked with the selected latitude and longitude when navigating back.
  final OnBackCallback onBack;

  /// Creates a new instance of [MapScreenArgs].
  const MapScreenArgs({required this.onBack});

  /// Safely invokes the [onBack] callback only if the latitude and longitude are valid.
  void safeOnBack(double lat, double lng) {
    if (_isValidCoordinate(lat, lng)) {
      onBack(lat, lng);
    } else {
      log('Invalid coordinates: lat=$lat, lng=$lng');
    }
  }

  static bool _isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}

class MapScreen extends StatefulWidget {
  static const String routeName = 'MapScreen';
  final MapScreenArgs args;

  const MapScreen({super.key, required this.args});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  // Controllers and Services
  late final LocationService _locationService;
  final AddressLookupService _addressLookupService = AddressLookupService();
  late final PlacesService _placesService;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  GoogleMapController? _mapController;

  // State
  LocationState _locationState = const LocationState();
  SearchState _searchState = const SearchState();

  // Configuration
  bool _isManualSelection = false;
  String? _sessionToken;
  Timer? _searchDebounce;

  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);
  static const double _defaultZoom = 14.0;
  static const double _initialZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupListeners();
    _determineInitialPosition();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _cleanupResources();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeServices() {
    _locationService = LocationService();
    _placesService = PlacesService();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  void _setupListeners() {
    _searchController.addListener(_onSearchTextChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);

    _locationService.listenToLocation((locationData) {
      if (!_isManualSelection && locationData.latitude != null && locationData.longitude != null) {
        _updateLocationState(locationData.latitude!, locationData.longitude!, shouldUpdatePlacemarks: true);
      }
    });
  }

  void _cleanupResources() {
    _locationService.dispose();
    _searchController.removeListener(_onSearchTextChanged);
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
  }

  Future<void> _determineInitialPosition() async {
    setState(() {
      _locationState = _locationState.copyWith(isLoading: true);
    });

    try {
      final location = await _locationService.getCurrentLocation();
      if (location?.latitude != null && location?.longitude != null) {
        await _updateLocationState(location!.latitude!, location.longitude!, shouldUpdatePlacemarks: true);
      }
    } catch (e) {
      setState(() {
        _locationState = _locationState.copyWith(isLoading: false, error: 'Failed to get current location: $e');
      });
      log('Failed to get location: $e');
    }
  }

  Future<void> _updateLocationState(double lat, double lng, {bool shouldUpdatePlacemarks = false}) async {
    if (!mounted) return;
    List<Placemark>? placemarks;

    if (shouldUpdatePlacemarks) {
      try {
        placemarks = await _addressLookupService.lookup(lat, lng);
      } catch (e) {
        log('Failed to get placemarks: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _locationState = _locationState.copyWith(
        latitude: lat,
        longitude: lng,
        placemarks: placemarks ?? _locationState.placemarks,
        isLoading: false,
        error: null,
      );
    });

    // Update map camera
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    }
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchState = _searchState.hide();
      });
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDelay, () => _performSearch(query));
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      _forceHideSearchUI();
    } else if (_searchController.text.isNotEmpty) {
      setState(() {
        _searchState = _searchState.show();
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _searchState = _searchState.loading();
    });

    try {
      _sessionToken ??= const Uuid().v4();
      final results = await _placesService.getPredictions(input: query, sesstionToken: _sessionToken!);

      if (mounted) {
        setState(() {
          _searchState = _searchState.withResults(results);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchState = _searchState.withError('Search failed: $e');
        });
      }
      log('Search error: $e');
    }
  }

  Future<void> _onPlaceSelected(PlaceModel place) async {
    if (place.placeId == null) return;

    try {
      // 1. Immediately hide keyboard using system channels
      SystemChannels.textInput.invokeMethod('TextInput.hide');

      // 2. Clear focus from all nodes
      _searchFocusNode.unfocus();
      FocusScope.of(context).requestFocus(FocusNode());

      // 3. Update search text and UI
      _searchController.text = place.description ?? '';
      setState(() => _searchState = _searchState.hide());

      // 4. Add a minimal delay to ensure UI settles
      await Future.delayed(const Duration(milliseconds: 30));

      final details = await _placesService.getPlaceDetails(placeId: place.placeId!);

      final lat = details.geometry?.location?.lat;
      final lng = details.geometry?.location?.lng;

      if (lat == null || lng == null) return;

      _locationService.pauseLocationStream();
      _isManualSelection = true;

      await _updateLocationState(lat, lng);

      if (_mapController != null) {
        await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), _defaultZoom));
      }

      widget.args.safeOnBack(lat, lng);
    } catch (e, stack) {
      log('Place selection error: $e');
      log('Stack trace: $stack');
    }
  }

  void _onMapTap(LatLng latLng) {
    // Pause automatic location updates
    _locationService.pauseLocationStream();
    _isManualSelection = true;

    // Force hide search UI
    _forceHideSearchUI();

    // Update location immediately
    _updateLocationState(latLng.latitude, latLng.longitude);

    // Notify parent
    widget.args.safeOnBack(latLng.latitude, latLng.longitude);
  }

  void _forceHideSearchUI() {
    // System channel method (most reliable)
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Focus node methods
    _searchFocusNode.unfocus();
    FocusScope.of(context).requestFocus(FocusNode());

    // Additional safety
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _searchState = _searchState.hide());
  }

  Future<void> _resumeLocationTracking() async {
    _isManualSelection = false;
    _locationService.resumeLocationStream();
    await _determineInitialPosition();
  }

  void _onCameraIdle() {
    // Hide search results when camera stops moving
    if (_searchState.isVisible) {
      _forceHideSearchUI();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchState = _searchState.hide();
    });
  }

  void _onScaffoldTap() {
    if (_searchState.isVisible) {
      _forceHideSearchUI();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onScaffoldTap,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        floatingActionButton: _buildLocationButton(),
        body: _locationState.isLoading ? const Center(child: CustomDotsLoading()) : _buildMapContent(),
        bottomNavigationBar: _buildConfirmButton(),
      ),
    );
  }

  Widget _buildLocationButton() {
    return FloatingActionButton(
      backgroundColor: Theme.of(context).primaryColor,
      onPressed: _resumeLocationTracking,
      child: const Icon(Icons.my_location),
    );
  }

  Widget _buildMapContent() {
    if (!_locationState.hasValidCoordinates) {
      return const Center(child: CustomDotsLoading());
    }

    return Stack(children: [_buildGoogleMap(), _buildSearchOverlay()]);
  }

  Widget _buildGoogleMap() {
    return Positioned.fill(
      child: GoogleMap(
        onTap: _onMapTap,
        markers: _buildMarkers(),
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        onCameraIdle: _onCameraIdle,
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(target: _locationState.latLng, zoom: _initialZoom),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    if (!_locationState.hasValidCoordinates) return {};

    return {Marker(markerId: const MarkerId('currentLocation'), position: _locationState.latLng)};
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_locationState.hasValidCoordinates) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(_locationState.latLng));
    }
  }

  Widget _buildSearchOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(children: [_buildSearchField(), if (_searchState.isVisible) _buildSearchResultsList()]),
      ),
    );
  }

  Widget _buildSearchField() {
    return Focus(
      focusNode: _searchFocusNode,
      child: CustomFormField(
        controller: _searchController,
        hintText: 'search'.tr,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
            : const Icon(Icons.search),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    if (_searchState.isLoading) {
      return Container(
        height: 100,
        margin: const EdgeInsets.only(top: 10),
        decoration: _searchContainerDecoration(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_searchState.error != null) {
      return Container(
        height: 60,
        margin: const EdgeInsets.only(top: 10),
        decoration: _searchContainerDecoration(),
        child: Center(
          child: Text(_searchState.error!, style: TextStyle(color: Colors.red[600])),
        ),
      );
    }

    if (_searchState.results.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: context.height * 0.4, minHeight: 50),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: _searchContainerDecoration(),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: _searchState.results.length,
          itemBuilder: _buildSearchResultItem,
        ),
      ),
    );
  }

  BoxDecoration _searchContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 4))],
    );
  }

  Widget _buildSearchResultItem(BuildContext context, int index) {
    final place = _searchState.results[index];
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: Text(place.description ?? 'Unknown location'),
      onTap: () => _onPlaceSelected(place),
    );
  }

  Widget? _buildConfirmButton() {
    if (!_locationState.hasValidCoordinates) return null;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: CustomButton(
        text: 'confirm'.tr,
        onPressed: () {
          widget.args.safeOnBack(_locationState.latitude!, _locationState.longitude!);
          Navigator.pop(context);
        },
      ),
    );
  }
}
