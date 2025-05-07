import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A controller to manage the selected app version
class VersionSelectorController extends GetxController {
  static VersionSelectorController get to => Get.find<VersionSelectorController>();
  
  // Available versions
  final List<String> availableVersions = ['1.0.0', '1.1.0', '1.2.0'];
  
  // Currently selected version
  final Rx<String> selectedVersion = '1.0.0'.obs;
  
  // Change the selected version
  void changeVersion(String version) {
    if (availableVersions.contains(version)) {
      selectedVersion.value = version;
    }
  }
}

/// A widget to display a dropdown for selecting app versions
class VersionSelector extends StatelessWidget {
  const VersionSelector({
    Key? key,
    required this.onVersionChanged,
  }) : super(key: key);
  
  final Function(String) onVersionChanged;
  
  @override
  Widget build(BuildContext context) {
    // Get or create the version controller
    final controller = Get.put(VersionSelectorController());
    
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
          Obx(() => DropdownButton<String>(
            value: controller.selectedVersion.value,
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.changeVersion(newValue);
                onVersionChanged(newValue);
              }
            },
            items: controller.availableVersions
                .map<DropdownMenuItem<String>>((String value) {
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
          )),
        ],
      ),
    );
  }
}