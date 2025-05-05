import 'package:assets_differ/core/config/asset_config.dart';
import 'package:assets_differ/core/managers/asset_module_provider.dart';
import 'package:assets_differ/core/services/asset_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'module_assets_screen.dart';

/// Home screen that lists available modules
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<AssetModuleProvider> _providerFuture;

  @override
  void initState() {
    super.initState();
    _initializeAssetProvider();
  }

  Future<void> _initializeAssetProvider() async {
    _providerFuture = AssetService.getInstance(
      baseApiUrl: AssetConfig.baseApiUrl,
      appVersion: AssetConfig.appVersion,
      brandId: AssetConfig.defaultBrandId,
    ).then((assetService) {
      return AssetModuleProvider(assetService: assetService);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Differ Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializeAssetProvider();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<AssetModuleProvider>(
        future: _providerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
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
                    'Error initializing asset service',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeAssetProvider();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final provider = snapshot.data!;
          return _buildModuleList(provider);
        },
      ),
    );
  }

  Widget _buildModuleList(AssetModuleProvider provider) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewScreen(),
                ),
              );
            },
            child: const Text("demo")),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: AssetConfig.modules.length,
            itemBuilder: (context, index) {
              final moduleName = AssetConfig.modules[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    moduleName.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      'Contains ${AssetConfig.demoAssets[moduleName]?.length ?? 0} assets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final moduleManager =
                        await provider.getModuleManager(moduleName);
                    if (!mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModuleAssetsScreen(
                          moduleName: moduleName,
                          moduleManager: moduleManager,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

final v1Json = {
  "version": "1.0.0",
  "module": "lobby",
  "assets": [
    {
      "path": "images/logo.png",
      "hash": "<commit hash>",
      "url": "https://cdn.example.com/assets/v1.0.0/images/logo.png",
      "priority": 0
    },
    {
      "path": "icons/menu/menu_icon.png",
      "hash": "<commit hash>",
      "url": "https://cdn.example.com/assets/v1.0.0/icons/menu/menu_icon.png",
      "priority": 1
    },
    {
      "path": "banners/home/banner1.jpg",
      "hash": "<commit hash>",
      "url": "https://cdn.example.com/assets/v1.0.0/banners/home/banner1.jpg",
      "priority": 2
    }
  ]
};

final v2Json = {
  "version": "1.0.0",
  "module": "lobby",
  "assets": [
    {
      "path": "images/logo.png",
      "hash": "<commit hash>",
      "url": "https://cdn.example.com/assets/v1.0.0/images/logo.png",
      "priority": 0
    },
    {
      "path": "icons/menu/menu_icon.png",
      "hash": "<commit hash>",
      "url": "https://cdn.example.com/assets/v1.0.0/icons/menu/menu_icon.png",
      "priority": 1
    },
    {
      "path": "banners/home/banner1.jpg",
      "hash": "<commit hash>",
      "url": "https://cdn.example.com/assets/v1.0.0/banners/home/banner1.jpg",
      "priority": 2
    }
  ]
};


class DummyAssets {
  final List<String> p0AssetList;
  final List<String> p1AssetList;
  final List<String> p2AssetList;

  DummyAssets({
    required this.p0AssetList,
    required this.p1AssetList,
    required this.p2AssetList,
  });
}

class NewScreen extends StatelessWidget {
  const NewScreen({
    Key? key,
    required this.dummyAssets,
  }) : super(key: key);
  final Rx<DummyAssets> dummyAssets;

  @override
  Widget build(BuildContext context) {
    // final assets = AssetProvider.instance.getSortedByPriority();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Demo'),
      ),
      body: Column(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            scrollDirection: Axis.horizontal,
            itemCount: dummyAssets.p0AssetList.length,
            itemBuilder: (context, index) {
              final asset = dummyAssets.p0AssetList[index];
              return CommonImage(asset: asset);
            },
          ),
          ListView.builder(
            padding: const EdgeInsets.all(16),
            scrollDirection: Axis.horizontal,
            itemCount: dummyAssets.p1AssetList.length,
            itemBuilder: (context, index) {
              final asset = dummyAssets.p1AssetList[index];
              return CommonImage(asset: asset);
            },
          ),
          ListView.builder(
            padding: const EdgeInsets.all(16),
            scrollDirection: Axis.horizontal,
            itemCount: dummyAssets.p2AssetList.length,
            itemBuilder: (context, index) {
              final asset = dummyAssets.p2AssetList[index];
              return CommonImage(asset: asset);
            },
          ),
        ],
      ),
    );
  }
}

class CommonImage extends StatelessWidget {
  const CommonImage({
    super.key,
    required this.asset,
  });

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Priority: 0',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Center(
              child: Image.network(
                asset,
                height: 150,
                // errorBuilder: (_, __, ___) => Image.network(
                //   'https://via.placeholder.com/150?text=${Uri.encodeComponent(asset.displayName)}',
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
