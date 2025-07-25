import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmailInputComponent extends StatelessWidget {
  final String hintText;
  final void Function(String?) onSaved;
  final Color luxuryGold;

  const EmailInputComponent({
    super.key,
    required this.hintText,
    required this.onSaved,
    this.luxuryGold = const Color(0xFFE8D26D),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: luxuryGold.withOpacity(0.2),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
      ),
      child: TextFormField(
        style: GoogleFonts.lato(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.email_outlined, color: luxuryGold.withOpacity(0.7), size: 20),
          hintText: hintText,
          hintStyle: GoogleFonts.lato(
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w400,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          errorStyle: const TextStyle(height: 0, fontSize: 0, color: Colors.transparent),
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorMaxLines: 1,
          helperStyle: const TextStyle(height: 0, fontSize: 0),
          errorText: null,
        ),
        autovalidateMode: AutovalidateMode.disabled,
        // Automatically trim whitespace when text changes
        onChanged: (value) {
          // Remove any whitespace as the user types
          if (value.contains(' ')) {
            final trimmedValue = value.replaceAll(' ', '');
            // Only update if actually changed to avoid cursor jumping
            if (trimmedValue != value) {
              final controller = TextEditingController(text: trimmedValue)
                ..selection = TextSelection.collapsed(offset: trimmedValue.length);
              Future.microtask(() {
                controller.dispose();
              });
            }
          }
        },
        // Trim whitespace when saving
        onSaved: (value) => onSaved(value?.trim()),
      ),
    );
  }
} 