import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  final Set<Polyline> _polylines = {};
  MarkerId? _selectedMarkerId;
  late PolylinePoints polylinePoints;
  String? _distance;
  String? _duration;
  bool _showDirections = false;

  // Friend data from FriendListScreen
  final List<Map<String, String>> _friends = const [
    {'name': 'Alice', 'uid': 'user_id_1'},
    {'name': 'Bob', 'uid': 'user_id_2'},
    {'name': 'Charlie', 'uid': 'user_id_3'},
    {'name': 'Diana', 'uid': 'user_id_4'},
  ];

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints();
    _initLocation();
    _fetchFriendLocations();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Permissions permanently denied. Enable from settings.');
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateMarkers();
      });
    } catch (e) {
      _showError('Failed to get location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchFriendLocations() async {
    try {
      for (var friend in _friends) {
        final uid = friend['uid'];
        if (uid == null) continue;

        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['latitude'] != null && data['longitude'] != null) {
            setState(() {
              _markers.add(
                Marker(
                  markerId: MarkerId(uid),
                  position: LatLng(data['latitude'], data['longitude']),
                  infoWindow: InfoWindow(
                    title: friend['name'] ?? 'Friend',
                    onTap: () => _showDirectionOptions(LatLng(data['latitude'], data['longitude'])),
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    _getMarkerColor(friend['name'] ?? ''),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedMarkerId = MarkerId(uid);
                      _getDirections(LatLng(data['latitude'], data['longitude']));
                    });
                  },
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching friend locations: $e');
    }
  }

  void _updateMarkers() {
    if (_currentPosition == null) return;

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'me');
      _markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'My Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  Future<void> _getDirections(LatLng destination) async {
    if (_currentPosition == null) return;

    // Get route points
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyByXmJzeOqrv5OHHlA7onEgIrpAKrGzFOc', // Replace with your API key
      PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isEmpty) return;

    // Decode polyline points
    List<LatLng> polylineCoordinates = result.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    // Calculate distance and duration
    double distance = 0;
    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      distance += _coordinateDistance(
        polylineCoordinates[i].latitude,
        polylineCoordinates[i].longitude,
        polylineCoordinates[i + 1].latitude,
        polylineCoordinates[i + 1].longitude,
      );
    }

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: polylineCoordinates,
        ),
      );
      _distance = '${(distance / 1000).toStringAsFixed(1)} km';
      _duration = '${(distance / 500).toStringAsFixed(0)} mins'; // Rough estimate
      _selectedMarkerId = null;
      _showDirections = true;
    });
  }

  double _coordinateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)) * 1000; // Meters
  }

  void _showDirectionOptions(LatLng destination) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Directions to ${_markers.firstWhere((m) => m.position == destination).infoWindow.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_distance != null && _duration != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Distance: $_distance'),
                  Text('Duration: ~$_duration'),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _getDirections(destination);
                  },
                  child: const Text('Show Route'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchGoogleMaps(destination);
                  },
                  child: const Text('Open in Maps'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchGoogleMaps(LatLng destination) async {
    if (_currentPosition == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not launch Google Maps');
    }
  }

  double _getMarkerColor(String name) {
    switch (name.isNotEmpty ? name[0].toUpperCase() : '') {
      case 'A': return BitmapDescriptor.hueBlue;
      case 'B': return BitmapDescriptor.hueGreen;
      case 'C': return BitmapDescriptor.hueOrange;
      case 'D': return BitmapDescriptor.hueRose;
      default: return BitmapDescriptor.hueViolet;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _isLoading || _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              mapController = controller;
            },
            onTap: (_) {
              setState(() {
                _selectedMarkerId = null;
                _showDirections = false;
                _polylines.clear();
              });
            },
            myLocationEnabled: true,
          ),

          // Zoom to fit button
          Positioned(
            right: 7,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'zoomToFitButton',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _zoomToFitMarkers,
              child: const Icon(Icons.location_searching_sharp, color: Colors.grey),
            ),
          ),

          // Directions info panel
          if (_showDirections && _distance != null && _duration != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route Info',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Distance: $_distance'),
                        Text('Duration: ~$_duration'),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showDirections = false;
                          _polylines.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _zoomToFitMarkers() {
    if (mapController == null || _markers.isEmpty) return;
    LatLngBounds boundsFromMarkers = _boundsFromMarkers();
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(boundsFromMarkers, 100),
    );
  }

  LatLngBounds _boundsFromMarkers() {
    double? minLat, maxLat, minLng, maxLng;
    for (var marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
    }
    return LatLngBounds(
      northeast: LatLng(maxLat!, maxLng!),
      southwest: LatLng(minLat!, minLng!),
    );
  }
}