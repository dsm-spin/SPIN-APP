import 'package:flutter/material.dart';

class InputComponent extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool secureText;

  const InputComponent({
    super.key,
    required this.controller,
    required this.hintText,
    this.secureText = false,
  });

  @override
  State<InputComponent> createState() => _InputComponentState();
}

class _InputComponentState extends State<InputComponent> {
  late bool _obscured = widget.secureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(width: 1.0),
      ),
      width: double.infinity,
      height: 60,
      child: TextFormField(
        obscureText: _obscured,
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
        controller: widget.controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          suffixIcon: widget.secureText
              ? IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black.withAlpha(120),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
