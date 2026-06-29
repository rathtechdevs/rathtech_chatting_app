import 'package:flutter/material.dart';

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(context, ['1', '2', '3']),
        const SizedBox(height: 8),
        _row(context, ['4', '5', '6']),
        const SizedBox(height: 8),
        _row(context, ['7', '8', '9']),
        const SizedBox(height: 8),
        _bottomRow(context),
      ],
    );
  }

  Widget _row(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _DigitButton(
                digit: d,
                onTap: enabled ? () => onDigit(d) : null,
              ))
          .toList(),
    );
  }

  Widget _bottomRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 80, height: 80),
        _DigitButton(digit: '0', onTap: enabled ? () => onDigit('0') : null),
        SizedBox(
          width: 80,
          height: 80,
          child: enabled
              ? IconButton(
                  onPressed: onBackspace,
                  iconSize: 28,
                  icon: const Icon(Icons.backspace_outlined),
                )
              : null,
        ),
      ],
    );
  }
}

class _DigitButton extends StatelessWidget {
  const _DigitButton({required this.digit, required this.onTap});

  final String digit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
        ),
        child: Text(
          digit,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
