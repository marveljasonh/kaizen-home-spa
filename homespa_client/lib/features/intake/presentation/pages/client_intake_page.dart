import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/intake_providers.dart';

// Client Intake Form: full-screen stepper, one question per screen, on the
// reference's light cream page. New clients land here after sign-up / login
// (/intake, can't be left by going back); Profile → Health & Preferences
// opens it prefilled (/intake/edit).

const Color _kPage = Color(0xFFEDEDE3);
const Color _kInk = Color(0xFF313129);
const Color _kMuted = Color(0xFF7A7A70);
const Color _kPillBorder = Color(0xFFD6D6CA);
const Color _kSelectedFill = Color(0xFFA9B38A);
const Color _kSelectedInk = Color(0xFF434930); // dark olive
const Color _kButton = Color(0xFF5B6142);
const double _kGutter = 30;
const double _kRadius = 10;
const double _kButtonHeight = 54;
const int _kQuestionCount = 4;

const String _kNone = 'None of these';
const List<String> _kHealthConditions = [
  'Stroke',
  'Vertigo',
  'Migraine',
  'Diabetes',
  'Arthritis',
  'Pregnant',
  'Heart Attack',
  'Infection',
  'Cancer',
  'Skin Condition',
  'Osteoporosis',
  'Fractures',
  'Hypertension',
  'High Fever',
];
const List<String> _kFocusAreas = [
  'Feet Palms',
  'Lower Back',
  'Calf',
  'Head',
  'Upper Back',
  'Arms & Hands',
  'Inner & Outer Thighs',
];
const List<(String, String)> _kPressures = [
  ('light', 'Light Pressure'),
  ('medium', 'Medium Pressure'),
  ('firm', 'Firm Pressure'),
];

TextStyle _body(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = _kInk,
  double? height,
}) => GoogleFonts.montserrat(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

class ClientIntakePage extends ConsumerStatefulWidget {
  /// Opened from Profile: prefilled, "Save Changes", pops back when saved.
  final bool editMode;
  const ClientIntakePage({super.key, this.editMode = false});

  @override
  ConsumerState<ClientIntakePage> createState() => _ClientIntakePageState();
}

class _ClientIntakePageState extends ConsumerState<ClientIntakePage> {
  int _step = 0;
  bool _isSaving = false;

  final Set<String> _health = {};
  bool _healthNone = false;
  final Set<String> _focus = {};
  String _pressure = 'medium';
  bool _avoidYes = false;
  final _avoidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Already cached: the router reads it before letting the user in.
    final saved = ref.read(clientIntakeProvider).valueOrNull;
    if (saved != null) {
      _health.addAll(saved.healthConditions.where(_kHealthConditions.contains));
      _healthNone = _health.isEmpty;
      _focus.addAll(saved.focusAreas.where(_kFocusAreas.contains));
      if (_kPressures.any((p) => p.$1 == saved.pressure)) {
        _pressure = saved.pressure;
      }
      final avoid = saved.avoidAreas?.trim() ?? '';
      if (avoid.isNotEmpty) {
        _avoidYes = true;
        _avoidCtrl.text = avoid;
      }
    }
  }

  @override
  void dispose() {
    _avoidCtrl.dispose();
    super.dispose();
  }

  bool get _isLast => _step == _kQuestionCount - 1;

  /// Only "Yes (Insert Body Area)" needs input; everything else can be left
  /// as "none / no preference".
  bool get _canContinue =>
      !_isSaving && !(_isLast && _avoidYes && _avoidCtrl.text.trim().isEmpty);

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else if (widget.editMode) {
      context.pop();
    }
  }

  void _toggleHealth(String condition) => setState(() {
    if (condition == _kNone) {
      _healthNone = !_healthNone;
      if (_healthNone) _health.clear();
      return;
    }
    _healthNone = false;
    if (!_health.remove(condition)) _health.add(condition);
  });

  void _toggleFocus(String area) => setState(() {
    if (!_focus.remove(area)) _focus.add(area);
  });

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    if (!_isLast) {
      setState(() => _step++);
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('client_intake').upsert({
        'client_id': userId,
        'health_conditions': _healthNone
            ? <String>[]
            : [
                for (final c in _kHealthConditions)
                  if (_health.contains(c)) c,
              ],
        'focus_areas': [
          for (final a in _kFocusAreas)
            if (_focus.contains(a)) a,
        ],
        'pressure': _pressure,
        'avoid_areas': _avoidYes ? _avoidCtrl.text.trim() : null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'client_id');

      // Refetch before navigating, so the router sees the saved row and
      // doesn't send the user back here.
      ref.invalidate(clientIntakeProvider);
      await ref.read(clientIntakeProvider.future);
      if (!mounted) return;

      if (widget.editMode) {
        context.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Preferences updated')),
        );
      } else {
        context.go('/');
      }
    } catch (e) {
      debugPrint('[Intake] save error: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Couldn’t save your answers. Please try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        // Back goes to the previous question; the first-time form can't be
        // left, the edit form pops from question 1.
        canPop: widget.editMode && _step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          backgroundColor: _kPage,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  step: _step,
                  showBack: _step > 0 || widget.editMode,
                  onBack: _back,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      _kGutter,
                      32,
                      _kGutter,
                      24,
                    ),
                    child: _buildQuestion(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_kGutter, 8, _kGutter, 16),
                  child: _ContinueButton(
                    label: !_isLast
                        ? 'Continue'
                        : widget.editMode
                        ? 'Save Changes'
                        : 'Finish',
                    isLoading: _isSaving,
                    onTap: _canContinue ? _continue : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return switch (_step) {
      0 => _Question(
        title: 'I have indications of the following health conditions.',
        subtitle: '(Shared to ensure a safe and comfortable treatment.)',
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in _kHealthConditions)
              _Chip(
                label: c,
                selected: _health.contains(c),
                onTap: () => _toggleHealth(c),
              ),
            _Chip(
              label: _kNone,
              selected: _healthNone,
              onTap: () => _toggleHealth(_kNone),
            ),
          ],
        ),
      ),
      1 => _Question(
        title:
            'Which body areas would you like to receive more intensive focus?',
        subtitle:
            '(The therapist will still massage the full body according to SOP)',
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final a in _kFocusAreas)
              _Chip(
                label: a,
                selected: _focus.contains(a),
                onTap: () => _toggleFocus(a),
              ),
          ],
        ),
      ),
      2 => _Question(
        title: 'What type of pressure would you like?',
        subtitle: '(Applied within standard massage procedures.)',
        child: Column(
          children: [
            for (final (value, label) in _kPressures) ...[
              _OptionPill(
                label: label,
                selected: _pressure == value,
                onTap: () => setState(() => _pressure = value),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      _ => _Question(
        title:
            'Are there any specific body areas you prefer not to be massaged?',
        subtitle:
            '(The therapist does not massage the genital area, abdomen, thighs, '
            'buttocks for male clients, or the breasts, except for postnatal '
            'massage.)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionPill(
              label: 'Yes (Insert Body Area)',
              selected: _avoidYes,
              onTap: () => setState(() => _avoidYes = true),
            ),
            if (_avoidYes) ...[
              const SizedBox(height: 12),
              _AvoidField(
                controller: _avoidCtrl,
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 12),
            _OptionPill(
              label: 'No Preference',
              selected: !_avoidYes,
              onTap: () => setState(() => _avoidYes = false),
            ),
          ],
        ),
      ),
    };
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

/// "Client Intake Form" + "Question N of 4", then a thin progress bar.
class _Header extends StatelessWidget {
  final int step;
  final bool showBack;
  final VoidCallback onBack;

  const _Header({
    required this.step,
    required this.showBack,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter - 12, 8, _kGutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                // Keeps the title in place when there is no back arrow.
                SizedBox(
                  width: 48,
                  child: showBack
                      ? IconButton(
                          tooltip: 'Back',
                          onPressed: onBack,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: _kInk,
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Text(
                    'Client Intake Form',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _body(16, weight: FontWeight.w600),
                  ),
                ),
                Text(
                  'Question ${step + 1} of $_kQuestionCount',
                  style: _body(13, color: _kMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: (step + 1) / _kQuestionCount),
                duration: const Duration(milliseconds: 250),
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  color: _kButton,
                  backgroundColor: _kButton.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Question pieces ───────────────────────────────────────────────────────────

class _Question extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Question({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'CalSans',
            fontWeight: FontWeight.w600,
            fontSize: 26,
            height: 1.25,
            color: _kInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: _body(13, color: _kMuted, height: 1.4)),
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}

/// Multi-select chip: white pill with "+" / soft olive pill with a check.
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected ? _kSelectedInk : _kInk;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? _kSelectedFill : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? _kSelectedInk : _kPillBorder,
            width: selected ? 1 : 0.8,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_rounded : Icons.add_rounded,
                  size: 18,
                  color: ink,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: _body(
                    14,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-select full-width pill with a check when selected.
class _OptionPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected ? _kSelectedInk : _kInk;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? _kSelectedFill : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? _kSelectedInk : _kPillBorder,
            width: selected ? 1 : 0.8,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: _kButtonHeight,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: _body(
                        15,
                        weight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: ink,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: _kSelectedInk,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvoidField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _AvoidField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kRadius),
      borderSide: const BorderSide(color: _kPillBorder, width: 0.8),
    );
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      maxLines: 2,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: _kSelectedInk,
      style: _body(15),
      decoration: InputDecoration(
        hintText: 'e.g. Neck, left shoulder',
        hintStyle: _body(15, color: _kMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: _kSelectedInk),
        ),
      ),
    );
  }
}

/// Olive #5B6142, white Montserrat, radius 10, 54 tall.
class _ContinueButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ContinueButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final radius = BorderRadius.circular(_kRadius);
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: _kButton.withValues(alpha: enabled || isLoading ? 1 : 0.4),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            height: _kButtonHeight,
            child: Center(
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: _body(
                        17,
                        weight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown by the router while it checks whether the client has an intake.
class IntakeCheckPage extends StatelessWidget {
  const IntakeCheckPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF434930),
    body: Center(child: CircularProgressIndicator(color: Colors.white)),
  );
}
