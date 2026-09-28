import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glass chip matching the Figma category cards: white 10% fill with a 0.5px
/// white 50% border; selected chips invert to solid white with olive text.
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color _selectedText = Color(0xFF4E523B);

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.50),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: isSelected ? _selectedText : Colors.white,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
