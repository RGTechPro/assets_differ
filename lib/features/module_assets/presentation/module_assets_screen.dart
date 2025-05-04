import 'package:assets_differ/core/config/asset_config.dart';
import 'package:assets_differ/core/managers/module_asset_manager.dart';
import 'package:assets_differ/core/widgets/dynamic_image.dart';
import 'package:flutter/material.dart';
/// Screen to showcase module assets
class ModuleAssetsScreen extends StatefulWidget {
  final String moduleName;
  final ModuleAssetManager moduleManager;

  const ModuleAssetsScreen({
    Key? key,
    required this.moduleName,
    required this.moduleManager,
  }) : super(key: key);

  @override
  State<ModuleAssetsScreen> createState() => _ModuleAssetsScreenState();
}

class _ModuleAssetsScreenState extends State<ModuleAssetsScreen> {
  late AssetUpdateState _state;
  String? _errorMessage;
  String? _version;

  @override
  void initState() {
    super.initState();
    _state = widget.moduleManager.state;
    _setupListeners();
    
    if (_state == AssetUpdateState.needsUpdate) {
      _checkForUpdates();
    }
  }
  
  void _setupListeners() {
    widget.moduleManager.updateEvents.listen((event) {
      setState(() {
        _state = event.state;
        _errorMessage = event.error;
        _version = event.version;
      });
    });
  }
  
  Future<void> _checkForUpdates() async {
    await widget.moduleManager.checkForUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.moduleName.toUpperCase()} Assets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _state == AssetUpdateState.updating 
                ? null 
                : _checkForUpdates,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    switch (_state) {
      case AssetUpdateState.notInitialized:
      case AssetUpdateState.initializing:
        return const Center(
          child: CircularProgressIndicator(),
        );
      
      case AssetUpdateState.needsUpdate:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Assets need to be downloaded',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkForUpdates,
                child: const Text('Download Assets'),
              ),
            ],
          ),
        );
      
      case AssetUpdateState.updating:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Downloading assets...'),
            ],
          ),
        );
      
      case AssetUpdateState.ready:
        return _buildAssetGrid();
      
      case AssetUpdateState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'Error downloading assets',
                style: TextStyle(fontSize: 18),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkForUpdates,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
    }
  }
  
  Widget _buildAssetGrid() {
    final assetList = AssetConfig.demoAssets[widget.moduleName] ?? [];
    
    if (assetList.isEmpty) {
      return const Center(
        child: Text('No assets available for this module'),
      );
    }
    
    return Column(
      children: [
        if (_version != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Version: $_version',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: assetList.length,
            itemBuilder: (context, index) {
              final assetPath = assetList[index];
              return _buildAssetItem(assetPath);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildAssetItem(String assetPath) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DynamicImage(
                imagePath: '${widget.moduleName}/$assetPath',
                fit: BoxFit.contain,
                placeholder: const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              assetPath.split('/').last,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}