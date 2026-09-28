import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../treatments/presentation/widgets/category_treatments_view.dart';
import '../../../treatments/presentation/widgets/glass_icon_button.dart';
import '../providers/search_providers.dart';

const String _kIconBack = 'assets/icons/chevron_left_33.svg';
const double _kGutter = 30;
const double _kCardSide = 32;
const Duration _kDebounce = Duration(milliseconds: 350);

/// Treatment search (Home hero → Search). Debounced as the user types;
/// results reuse the Treatments list card and open the treatment detail.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_kDebounce, () => _search(value));
  }

  void _search(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q != _query && mounted) setState(() => _query = q);
  }

  void _clear() {
    _controller.clear();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkOliveLight,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(_kGutter, 16, _kGutter, 16),
                child: Row(
                  children: [
                    GlassIconButton(
                      svgAsset: _kIconBack,
                      iconSize: 33,
                      iconOffset: const Offset(6.5, 8.5),
                      fillAlpha: 0.20,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _field()),
                  ],
                ),
              ),
              Expanded(child: _results()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24.5),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.5),
        width: 0.746,
      ),
    );
    return SizedBox(
      height: 49,
      child: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: _onChanged,
        onSubmitted: _search,
        cursorColor: Colors.white,
        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search treatments',
          hintStyle: GoogleFonts.montserrat(
            fontSize: 14,
            color: AppColors.textOnDarkMuted,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          suffixIcon: ListenableBuilder(
            listenable: _controller,
            builder: (_, __) => _controller.text.isEmpty
                ? const Icon(Icons.search_rounded, color: Colors.white)
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: _clear,
                  ),
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _results() {
    if (_query.isEmpty) {
      return const _Message('Search treatments by name or description.');
    }
    final resultsAsync = ref.watch(treatmentSearchProvider(_query));
    return resultsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.cream),
      ),
      error: (_, __) => _Message(
        'We couldn’t search right now.',
        onRetry: () => ref.invalidate(treatmentSearchProvider(_query)),
      ),
      data: (treatments) {
        if (treatments.isEmpty) {
          return _Message('No treatments found for “$_query”');
        }
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            _kCardSide,
            0,
            _kCardSide,
            16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: treatments.length,
          itemBuilder: (_, i) => TreatmentPhotoCard(
            key: ValueKey(treatments[i].id),
            treatment: treatments[i],
            onTap: () => context.push('/treatments/${treatments[i].id}'),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message(this.text, {this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 40, _kGutter, 0),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textOnDarkMuted,
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cream,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
