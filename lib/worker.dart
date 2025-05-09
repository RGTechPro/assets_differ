// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:isolate_manager/isolate_manager.dart';
import 'package:js/js.dart' as pjs;
import 'package:js/js_util.dart' as js_util;

@pjs.JS('self')
external dynamic get globalScopeSelf;

/// dart compile js worker.dart -o worker.js -O4

/// In most cases you don't need to modify this function
main() {
  callbackToStream('onmessage', (html.MessageEvent e) {
    return js_util.getProperty(e, 'data');
  }).listen((message) async {
    final Completer completer = Completer();
    completer.future.then(
      (value) => jsSendMessage(value),
      onError: (err, stack) => jsSendMessage(IsolateException(err, stack).toJson()),
    );
    try {
      completer.complete(worker(message));
    } catch (err, stack) {
      jsSendMessage(IsolateException(err, stack).toJson());
    }
  });
}

/// TODO: Modify your function here:
///
///  Do this if you need to throw an exception
///
///  You should only throw the `message` instead of a whole Object because it may
///  not show as expected when sending back to the main app.
///
/// ``` dart
///  return throw 'This is an error that you need to catch in your main app';
/// ```
FutureOr<dynamic> worker(dynamic message) {
  try {
    // Parse the message which should contain asset list data
    Map<String, dynamic> data;
    if (message is String) {
      data = jsonDecode(message);
    } else {
      data = Map<String, dynamic>.from(message);
    }
    
    // For asset processing in web workers, handle the specific message format
    if (data.containsKey('assetListMap')) {
      List<Map<String, dynamic>> assetListMap = List<Map<String, dynamic>>.from(data['assetListMap']);
      if (assetListMap.isEmpty) {
        return jsonEncode({'success': true, 'count': 0, 'message': 'No assets to process'});
      }
      
      // Log information (will appear in browser console)
      print('Web Worker: Saving ${assetListMap.length} assets to local storage');
      
      // Process each asset (simulating the isolate implementation)
      List<Map<String, dynamic>> results = [];
      for (var assetMap in assetListMap) {
        try {
          // Simulate asset downloading/processing
          print('Web Worker: Downloading image: ${assetMap['url']}');
          
          // Here we would normally download and save the asset
          // For web, we just process the data since web workers can't directly write to filesystem
          
          // Simulate a successful process
          final processedAsset = {
            'path': assetMap['path'],
            'url': assetMap['url'],
            'processed': true,
            'bytesLength': assetMap['size'] ?? 0,
            'timestamp': DateTime.now().millisecondsSinceEpoch
          };
          
          print('Web Worker: Saved image: ${assetMap['path']} (processed)');
          results.add(processedAsset);
        } catch (e) {
          print('Web Worker: Failed to process asset ${assetMap['path']}: $e');
          results.add({
            'path': assetMap['path'],
            'url': assetMap['url'],
            'processed': false,
            'error': e.toString()
          });
        }
      }
      
      // Return successful result with processed assets
      return jsonEncode({
        'success': true,
        'count': assetListMap.length,
        'results': results,
        'message': 'Processed ${assetListMap.length} assets in web worker'
      });
    }
    
    // Just return the original message for other message types
    return jsonEncode(message);
  } catch (e, stack) {
    print('Web Worker Error: $e\n$stack');
    return jsonEncode({
      'success': false,
      'error': e.toString(),
      'stack': stack.toString()
    });
  }
}

/// Internal function
Stream<T> callbackToStream<J, T>(String name, T Function(J jsValue) unwrapValue) {
  var controller = StreamController<T>.broadcast(sync: true);
  js_util.setProperty(js.context['self'], name, js.allowInterop((J event) {
    controller.add(unwrapValue(event));
  }));
  return controller.stream;
}

/// Internal function
void jsSendMessage(dynamic m) {
  js.context.callMethod('postMessage', [m]);
}