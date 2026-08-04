import 'package:flutter/material.dart';
import 'package:urbancare_frontend/theme/app_theme.dart';

class TextInput extends StatefulWidget {
  const TextInput({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscure,
      maxLines: widget.maxLines,
<<<<<<< HEAD
      style: TextStyle(color: textColor),
=======
      style: const TextStyle(color: Colors.white),
>>>>>>> origin/main
      validator: widget.validator,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.icon == null
            ? null
<<<<<<< HEAD
            : Icon(widget.icon, color: context.onSurfaceVariant, size: 18),
=======
            : Icon(widget.icon, color: const Color(0xFF6B7280), size: 18),
>>>>>>> origin/main
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility : Icons.visibility_off,
                  color: context.onSurfaceVariant,
                  size: 18,
                ),
              )
            : null,
      ),
    );
  }
}
