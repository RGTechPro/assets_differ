/// Constants for the asset differ application
class AssetConfig {
  /// Base URL for the asset API
  static const String baseApiUrl = 'https://cdn.example.com/api';
  
  /// Current app version
  static const String appVersion = '1.0.0';
  
  /// Default brand ID
  static const String defaultBrandId = 'default';
  
  /// Available modules
  static const List<String> modules = [
    'lobby',
    'cashier',
    'games',
    'profile',
  ];
  
  /// Demo assets for testing
  static const Map<String, List<String>> demoAssets = {
    'lobby': [
      'images/logo.png',
      'icons/menu/menu_icon.png',
      'banners/home/banner1.jpg',
    ],
    'cashier': [
      'images/payment_icons/credit_card.png',
      'images/payment_icons/paypal.png',
    ],
    'games': [
      'images/game_thumbnails/poker.png',
      'images/game_thumbnails/blackjack.png',
      'images/game_thumbnails/roulette.png',
    ],
    'profile': [
      'icons/profile/avatar.png',
      'icons/profile/settings.png',
    ],
  };

  static const Map<String, List<String>> demoAssetsTest = {
    'lobby': [
      'id/1',
      'id/2',
      'id/3',
    ],
    'cashier': [
      'id/4',
      'id/5',
    ],
    'games': [
      'id/6',
      'id/7',
      'id/8',
    ],
    'profile': [
      'id/9',
      'id/10',
    ],
  };
}