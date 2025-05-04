import 'dart:io';
import 'package:flutter/material.dart';
import '../services/asset_service.dart';

/// Widget to display a dynamic image from the asset service
class DynamicImage extends StatefulWidget {
  /// The path of the image relative to the asset base directory
  final String imagePath;
  
  /// Widget to display while loading the image
  final Widget? placeholder;
  
  /// Widget to display if the image fails to load
  final Widget? errorWidget;
  
  /// Width of the image
  final double? width;
  
  /// Height of the image
  final double? height;
  
  /// BoxFit for the image
  final BoxFit? fit;
  
  /// Optional asset service instance, if not provided the global instance will be used
  final AssetService? assetService;

  const DynamicImage({
    Key? key,
    required this.imagePath,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit,
    this.assetService,
  }) : super(key: key);

  @override
  State<DynamicImage> createState() => _DynamicImageState();
}

class _DynamicImageState extends State<DynamicImage> {
  late Future<File> _imageFuture;
  late AssetService _assetService;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }
  
  @override
  void didUpdateWidget(DynamicImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _fetchImage();
    }
  }

  Future<void> _fetchImage() async {
    _isLoading = true;
    _hasError = false;
    
    if (mounted) {
      setState(() {});
    }
    
    try {
      _assetService = widget.assetService ?? 
          await AssetService.getInstance(
            baseApiUrl: 'https://cdn.example.com/api',
            appVersion: '1.0.0',
            brandId: 'default',
          );
      
      final String assetPath = _assetService.getAssetPath(widget.imagePath);
      final File file = File(assetPath);
      
      if (await file.exists()) {
        _imageFuture = Future.value(file);
        _isLoading = false;
      } else {
        _hasError = true;
      }
    } catch (e) {
      _hasError = true;
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? 
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    }
    
    if (_hasError) {
      return widget.errorWidget ?? 
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
    }
    
    return FutureBuilder<File>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder ?? 
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return widget.errorWidget ?? 
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
        }
        
        return Image.file(
          snapshot.data!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      },
    );
  }
}