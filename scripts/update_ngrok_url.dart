/// Script to automatically update ngrok URL in api_config.dart
/// Run this whenever ngrok URL changes
/// Usage: dart scripts/update_ngrok_url.dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔄 Fetching current ngrok URL...');
  
  try {
    // Get ngrok API status
    final response = await HttpClient().getUrl(Uri.parse('http://127.0.0.1:4040/api/tunnels'))
        .then((request) => request.close());
    
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);
    
    if (json['tunnels'] == null || json['tunnels'].isEmpty) {
      print('❌ No active ngrok tunnels found!');
      exit(1);
    }
    
    final ngrokUrl = json['tunnels'][0]['public_url'];
    print('✅ Found ngrok URL: $ngrokUrl');
    
    // Update api_config.dart
    final configFile = File('lib/config/api_config.dart');
    String content = await configFile.readAsString();
    
    // Replace the production URL
    final regex = RegExp(r"static const String _productionBaseUrl = '[^']*';");
    content = content.replaceFirst(regex, "static const String _productionBaseUrl = '$ngrokUrl';");
    
    await configFile.writeAsString(content);
    print('✅ Updated api_config.dart with new ngrok URL!');
    print('🚀 Now run: flutter build web --release && firebase deploy --only hosting');
    
  } catch (e) {
    print('❌ Error: $e');
    print('Make sure ngrok is running on port 4040');
    exit(1);
  }
}
