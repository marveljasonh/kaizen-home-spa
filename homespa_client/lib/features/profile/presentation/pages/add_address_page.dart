import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/flow_widgets.dart';
import '../../../../core/widgets/kaizen_page.dart';
import '../../data/address_repository.dart';
import '../../domain/entities/saved_address.dart';

// Add / Edit Address: hero with back button, map picker in a rounded glass
// frame (booking Location step map: fixed centre pin, drag to move, my
// location), then address, label tabs, notes and default switch.

const double _kMapHeight = 220;

class AddAddressPage extends ConsumerStatefulWidget {
  /// The address to edit; null adds a new one.
  final SavedAddress? address;
  const AddAddressPage({super.key, this.address});

  @override
  ConsumerState<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends ConsumerState<AddAddressPage> {
  String _selectedLabel = 'Home';
  final _customLabelCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isDefault = false;
  bool _isSaving = false;

  final _mapController = MapController();
  // Jakarta city centre as default (booking Location step).
  LatLng _center = const LatLng(-6.2088, 106.8456);
  bool _isGeocoding = false;
  bool _isLocating = false;
  Timer? _geocodeDebounce;

  /// True while a finger is on the map, so the page doesn't scroll.
  bool _mapTouched = false;

  static const _presetLabels = ['Home', 'Office', 'Other'];

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    if (a != null) {
      if (_presetLabels.contains(a.label)) {
        _selectedLabel = a.label;
      } else {
        _selectedLabel = 'Other';
        _customLabelCtrl.text = a.label;
      }
      _addressCtrl.text = a.fullAddress;
      _notesCtrl.text = a.notes ?? '';
      _isDefault = a.isDefault;
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _mapController.dispose();
    _customLabelCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _effectiveLabel =>
      _selectedLabel == 'Other' && _customLabelCtrl.text.trim().isNotEmpty
      ? _customLabelCtrl.text.trim()
      : _selectedLabel;

  // ── Map (booking Location step behaviour) ──────────────────────────────────

  void _onMapEvent(MapEvent event) {
    // Programmatic moves (my location) geocode themselves.
    if (event.source == MapEventSource.mapController) return;
    if (event is MapEventMove || event is MapEventFlingAnimation) {
      _geocodeDebounce?.cancel();
      setState(() => _center = event.camera.center);
    }
    // Fill the address when the user stops moving the map.
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      setState(() => _center = event.camera.center);
      _geocodeDebounce = Timer(const Duration(milliseconds: 500), () {
        _reverseGeocode(_center);
      });
    }
  }

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
        _addressCtrl.text = parts.join(', ');
      }
    } catch (_) {
      if (mounted) {
        _addressCtrl.text =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

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

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a full address')),
      );
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final notes = _notesCtrl.text.trim().isNotEmpty
        ? _notesCtrl.text.trim()
        : null;
    final repo = ref.read(addressRepositoryProvider);

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await repo.updateAddress(
          id: widget.address!.id,
          userId: userId,
          label: _effectiveLabel,
          fullAddress: address,
          notes: notes,
          isDefault: _isDefault,
        );
      } else {
        await repo.addAddress(
          userId: userId,
          label: _effectiveLabel,
          fullAddress: address,
          notes: notes,
          isDefault: _isDefault,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return KaizenHeroPage(
      label: 'My Addresses',
      title: _isEditing ? 'Edit Address' : 'Add Address',
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/profile/addresses'),
      scrollable: !_mapTouched,
      bottomBar: FlowPrimaryButton(
        label: 'Save Address',
        isLoading: _isSaving,
        onTap: _save,
      ),
      children: [
        KaizenGutter(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMap(),
              const SizedBox(height: 8),
              Text(
                'Drag the map to place the pin, or type the address below.',
                style: flowBody(12, color: kFlowMuted, height: 1.35),
              ),
              const SizedBox(height: 20),

              // ── Full address ─────────────────────────────────────────────
              const FlowSectionLabel('Full Address *'),
              TextField(
                controller: _addressCtrl,
                maxLines: 3,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: flowBody(14, height: 1.4),
                decoration: InputDecoration(
                  hintText:
                      'e.g. Jl. Sudirman No. 45, Kelurahan Senayan, Jakarta Selatan',
                  suffixIcon: _isGeocoding
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // ── Label ────────────────────────────────────────────────────
              const FlowSectionLabel('Label'),
              KaizenChoiceTabs<String>(
                options: [for (final l in _presetLabels) (l, l)],
                selected: _selectedLabel,
                onSelected: (l) => setState(() => _selectedLabel = l),
              ),
              if (_selectedLabel == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customLabelCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: flowBody(14),
                  decoration: const InputDecoration(
                    hintText: "Custom label (e.g. Parents' House)",
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 20),

              // ── Notes ────────────────────────────────────────────────────
              const FlowSectionLabel('Notes (optional)'),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                style: flowBody(14),
                decoration: const InputDecoration(
                  hintText: 'Gate code, landmarks, floor number…',
                ),
              ),
              const SizedBox(height: 20),

              // ── Set as default ───────────────────────────────────────────
              KaizenGlassCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                onTap: () => setState(() => _isDefault = !_isDefault),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set as default address',
                            style: flowBody(15, weight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Used automatically in booking',
                            style: flowBody(12, color: kFlowMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                      activeThumbColor: AppColors.darkOliveLight,
                      activeTrackColor: Colors.white,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                      trackOutlineColor: WidgetStatePropertyAll(
                        Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Map in a rounded glass frame: hairline white border, card corners.
  Widget _buildMap() {
    final radius = BorderRadius.circular(kGlassCardRadius);
    return Listener(
      onPointerDown: (_) => setState(() => _mapTouched = true),
      onPointerUp: (_) => setState(() => _mapTouched = false),
      onPointerCancel: (_) => setState(() => _mapTouched = false),
      child: Container(
        height: _kMapHeight,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: kFlowCardShadow,
        ),
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: radius,
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

              // Fixed centre pin — stays still while the map moves.
              const IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_pin, size: 52, color: kFlowHeaderColor),
                    SizedBox(height: 24),
                  ],
                ),
              ),

              // My location
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: null,
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
