import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A widget to display a dropdown for selecting app versions
class VersionSelector extends StatelessWidget {
  const VersionSelector({
    Key? key,
    required this.onVersionChanged,
    required this.selectedVersion,
    required this.versions,
  }) : super(key: key);

  final Function(String) onVersionChanged;
  final List<String> versions;

  final RxString selectedVersion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'App Version:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => DropdownButton<String>(
              value: selectedVersion.value,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onVersionChanged(newValue);
                }
              },
              items: versions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down),
            ),
          ),
        ],
      ),
    );
  }
}
