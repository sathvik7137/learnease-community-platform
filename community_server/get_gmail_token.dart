import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Run this script to get OAuth refresh token for Gmail API
// Usage: dart run get_gmail_token.dart

void main() async {
  print('🔐 Gmail OAuth Token Generator\n');
  print('This will help you get a refresh token for Gmail API.\n');
  
  // Step 1: Get client credentials
  print('📋 Step 1: Enter your OAuth credentials from Google Cloud Console');
  print('   (Download the client_secret.json file from credentials page)\n');
  
  stdout.write('Enter Client ID: ');
  final clientId = stdin.readLineSync()?.trim() ?? '';
  
  stdout.write('Enter Client Secret: ');
  final clientSecret = stdin.readLineSync()?.trim() ?? '';
  
  if (clientId.isEmpty || clientSecret.isEmpty) {
    print('❌ Client ID and Secret are required!');
    exit(1);
  }
  
  // Step 2: Generate authorization URL
  final redirectUri = 'urn:ietf:wg:oauth:2.0:oob';  // For desktop apps
  final scopes = Uri.encodeComponent('https://www.googleapis.com/auth/gmail.send');
  
  final authUrl = 'https://accounts.google.com/o/oauth2/v2/auth?'
      'client_id=$clientId&'
      'redirect_uri=$redirectUri&'
      'response_type=code&'
      'scope=$scopes&'
      'access_type=offline&'
      'prompt=consent';
  
  print('\n📱 Step 2: Authorize the application');
  print('   Open this URL in your browser:\n');
  print('   $authUrl\n');
  print('   Login with: rayapureddyvardhan2004@gmail.com');
  print('   Click "Allow" to grant permissions\n');
  
  stdout.write('Enter the authorization code you received: ');
  final authCode = stdin.readLineSync()?.trim() ?? '';
  
  if (authCode.isEmpty) {
    print('❌ Authorization code is required!');
    exit(1);
  }
  
  // Step 3: Exchange auth code for refresh token
  print('\n🔄 Step 3: Exchanging authorization code for tokens...');
  
  try {
    final tokenResponse = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': authCode,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );
    
    if (tokenResponse.statusCode != 200) {
      print('❌ Token exchange failed: ${tokenResponse.body}');
      exit(1);
    }
    
    final tokens = jsonDecode(tokenResponse.body);
    final refreshToken = tokens['refresh_token'];
    
    if (refreshToken == null) {
      print('❌ No refresh token received. Make sure you used prompt=consent');
      exit(1);
    }
    
    print('\n✅ SUCCESS! Tokens received:\n');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📋 Add these to Render environment variables:\n');
    print('GMAIL_CLIENT_ID=$clientId');
    print('GMAIL_CLIENT_SECRET=$clientSecret');
    print('GMAIL_REFRESH_TOKEN=$refreshToken');
    print('GMAIL_USER_EMAIL=rayapureddyvardhan2004@gmail.com');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    print('🎉 Setup complete! Now update your Render environment variables.');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
