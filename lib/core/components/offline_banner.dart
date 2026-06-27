import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.amber.shade700,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.offlineBannerLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
