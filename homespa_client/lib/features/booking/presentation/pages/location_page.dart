import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/flow_widgets.dart';
import '../../../profile/data/address_repository.dart';
import '../../domain/entities/service_address.dart';
import '../providers/booking_cart.dart';
import '../widgets/booking_step_indicator.dart';

class LocationPage extends ConsumerStatefulWidget {
  const LocationPage({super.key});

  @override
  ConsumerState<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends ConsumerState<LocationPage> {
  final _mapController = MapController();
  final _addressController = TextEditingController();
  final _buildingController = TextEditingController();
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();

  // Jakarta city centre as default
  LatLng _center = const LatLng(-6.2088, 106.8456);
  String _detectedAddress = '';
  bool _isGeocoding = false;
  bool _isLocating = false;

  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    _reverseGeocode(_center);
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _mapController.dispose();
    _addressController.dispose();
    _buildingController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Map event handling ─────────────────────────────────────────────────────

  void _onMapEvent(MapEvent event) {
    // Update centre while dragging
    if (event is MapEventMove || event is MapEventFlingAnimation) {
      _geocodeDebounce?.cancel();
      setState(() => _center = event.camera.center);
    }
    // Trigger geocode when movement ends
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      setState(() => _center = event.camera.center);
      _geocodeDebounce = Timer(const Duration(milliseconds: 500), () {
        _reverseGeocode(_center);
      });
    }
  }

  // ── Reverse geocoding ──────────────────────────────────────────────────────

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isGeocoding = true);
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).toList();
        final addr = parts.join(', ');
        setState(() => _detectedAddress = addr);
        _addressController.text = addr;
      }
    } catch (_) {
      if (mounted) {
        final addr =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        setState(() => _detectedAddress = addr);
        _addressController.text = addr;
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  // ── GPS location ───────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      _mapController.move(target, 16.0);
      setState(() => _center = target);
      _reverseGeocode(target);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── Confirm ────────────────────────────────────────────────────────────────

  void _confirm() {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    final parts = [
      address,
      if (_buildingController.text.trim().isNotEmpty)
        _buildingController.text.trim(),
      if (_unitController.text.trim().isNotEmpty) _unitController.text.trim(),
    ].join(', ');

    ref
        .read(bookingCartProvider.notifier)
        .setAddress(
          ServiceAddress(
            fullAddress: parts,
            latitude: _center.latitude,
            longitude: _center.longitude,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          ),
        );
    context.push('/booking/voucher');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canConfirm = !_isGeocoding && _addressController.text.isNotEmpty;

    return FlowScaffold(
      title: 'Your Location',
      header: const BookingStepIndicator(currentStep: 4),
      bottomBar: FlowPrimaryButton(
        label: 'Confirm Location',
        onTap: canConfirm ? _confirm : null,
      ),
      body: Column(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                kFlowGutter,
                16,
                kFlowGutter,
                0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kFlowRadius),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _center,
                        initialZoom: 15,
                        onMapEvent: _onMapEvent,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.homespa.client',
                        ),
                      ],
                    ),

                    // Fixed centre pin — stays still while map moves underneath
                    const IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_pin,
                            size: 52,
                            color: kFlowHeaderColor,
                          ),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // My-location FAB
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: FloatingActionButton.small(
                        onPressed: _isLocating ? null : _goToMyLocation,
                        backgroundColor: kFlowCardColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kFlowRadius),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        tooltip: 'Use my location',
                        child: _isLocating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Address panel ──────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                kFlowGutter,
                16,
                kFlowGutter,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Saved address quick-select ─────────────────────────────
                  Consumer(
                    builder: (context, ref, _) {
                      final addressesAsync = ref.watch(savedAddressesProvider);
                      return addressesAsync.maybeWhen(
                        data: (addresses) {
                          if (addresses.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FlowSectionLabel('Saved addresses'),
                              SizedBox(
                                height: 76,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  clipBehavior: Clip.none,
                                  itemCount: addresses.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (_, i) {
                                    final addr = addresses[i];
                                    final isSelected =
                                        _detectedAddress == addr.fullAddress;
                                    return SizedBox(
                                      width: 156,
                                      child: FlowCard(
                                        selected: isSelected,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _detectedAddress = addr.fullAddress;
                                            if (addr.notes != null &&
                                                addr.notes!.isNotEmpty) {
                                              _notesController.text =
                                                  addr.notes!;
                                            }
                                          });
                                          _addressController.text =
                                              addr.fullAddress;
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  _savedAddressIcon(addr.label),
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    addr.label,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: flowBody(
                                                      12,
                                                      weight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                if (addr.isDefault) ...[
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.star_rounded,
                                                    size: 11,
                                                    color: kFlowGold,
                                                  ),
                                                ],
                                                const Spacer(),
                                                FlowCheckMark(
                                                  selected: isSelected,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Expanded(
                                              child: Text(
                                                addr.fullAddress,
                                                style: flowBody(
                                                  11,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : kFlowMuted,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 14),
                            ],
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),

                  // Detected address strip
                  FlowCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _isGeocoding
                              ? Text(
                                  'Detecting address…',
                                  style: flowBody(13, color: kFlowMuted),
                                )
                              : TextField(
                                  controller: _addressController,
                                  onChanged: (v) =>
                                      setState(() => _detectedAddress = v),
                                  style: flowBody(14, weight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isCollapsed: true,
                                    hintText:
                                        'Move the map to set your location',
                                    hintStyle: flowBody(13, color: kFlowMuted),
                                  ),
                                ),
                        ),
                        if (_isGeocoding)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kFlowMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const _FieldLabel('Building / Subdivision'),
                  TextField(
                    controller: _buildingController,
                    textCapitalization: TextCapitalization.words,
                    style: flowBody(14),
                    decoration: const InputDecoration(
                      hintText: 'e.g. The Residences Tower 1 (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),

                  const _FieldLabel('Unit / Floor / Apt'),
                  TextField(
                    controller: _unitController,
                    style: flowBody(14),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Unit 12B, 3rd Floor (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),

                  const _FieldLabel('Notes for therapist'),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: flowBody(14),
                    decoration: const InputDecoration(
                      hintText: 'Gate code, landmarks, instructions (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: flowBody(13, weight: FontWeight.w600)),
  );
}

IconData _savedAddressIcon(String label) => switch (label.toLowerCase()) {
  'home' => Icons.home_rounded,
  'office' || 'work' => Icons.business_rounded,
  _ => Icons.location_on_rounded,
};
