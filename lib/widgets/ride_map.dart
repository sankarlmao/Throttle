import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/pit_stop_model.dart';

class RideMap extends StatefulWidget {
  final List<LatLng> routePoints;
  final List<PitStopModel> pitStops;
  final LatLng? currentPosition;
  final bool isInteractive;
  final double height;
  final Color? routeColor;

  const RideMap({
    Key? key,
    required this.routePoints,
    required this.pitStops,
    this.currentPosition,
    this.isInteractive = true,
    this.height = 200.0,
    this.routeColor,
  }) : super(key: key);

  @override
  State<RideMap> createState() => _RideMapState();
}

class _RideMapState extends State<RideMap> {
  GoogleMapController? _mapController;

  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#111111"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#747474"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#111111"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [{"color": "#333333"}]
    },
    {
      "featureType": "landscape",
      "elementType": "geometry",
      "stylers": [{"color": "#181818"}]
    },
    {
      "featureType": "poi",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#2a2a2a"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#3c3c3c"}]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [{"color": "#2f2f2f"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#0d0d0d"}]
    }
  ]
  ''';

  @override
  void didUpdateWidget(covariant RideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInteractive && _mapController != null) {
      if (widget.currentPosition != null &&
          widget.currentPosition != oldWidget.currentPosition) {
        _animateToPosition(widget.currentPosition!);
      } else if (widget.routePoints.isNotEmpty &&
          (oldWidget.routePoints.isEmpty ||
              widget.routePoints.last != oldWidget.routePoints.last)) {
        _animateToPosition(widget.routePoints.last);
      }
    }
  }

  void _animateToPosition(LatLng pos) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: pos, zoom: 16.0),
      ),
    );
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    controller.setMapStyle(_darkMapStyle);

    if (widget.routePoints.isNotEmpty) {
      if (!widget.isInteractive) {
        // In detail view, fit the map bounds to show the entire route with padding
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_mapController != null && mounted) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(_getBounds(widget.routePoints), 40),
            );
          }
        });
      } else {
        // In active view, center on latest position
        _animateToPosition(widget.currentPosition ?? widget.routePoints.last);
      }
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (widget.routePoints.isNotEmpty) {
      // 1. Green Start Pin
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: widget.routePoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start Location'),
        ),
      );

      // 2. Red End Pin (for static detail map)
      if (!widget.isInteractive) {
        markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: widget.routePoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'End Location'),
          ),
        );
      }
    }

    // 3. Amber/Orange Pit Stop Pins
    for (var pit in widget.pitStops) {
      markers.add(
        Marker(
          markerId: MarkerId('pit_${pit.pitNumber}'),
          position: LatLng(pit.lat, pit.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'PIT ${pit.pitNumber}',
            snippet: pit.locationName,
          ),
        ),
      );
    }

    // 4. Blue Current Location Marker (for live tracking map)
    if (widget.isInteractive && widget.currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: widget.currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Current Position'),
          zIndex: 10,
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: widget.routePoints,
        color: widget.routeColor ?? const Color(0xFFFF5722), // Glowing route path
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    LatLng initialCenter = const LatLng(10.0159, 76.3419); // Kakkanad, Kochi fallback
    if (widget.currentPosition != null) {
      initialCenter = widget.currentPosition!;
    } else if (widget.routePoints.isNotEmpty) {
      initialCenter = widget.routePoints.last;
    }

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialCenter,
            zoom: 15.0,
          ),
          onMapCreated: _onMapCreated,
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
          zoomControlsEnabled: widget.isInteractive,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: widget.isInteractive,
          zoomGesturesEnabled: widget.isInteractive,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
        ),
      ),
    );
  }
}
