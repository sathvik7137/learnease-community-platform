import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔐 Gmail API - Get Refresh Token\n');
  
  // Your OAuth credentials
  final clientId = '324250610279-550tlirq6b5gt6t4na5d3s0f3rii5nmc.apps.googleusercontent.com';
  final clientSecret = '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';
  final redirectUri = 'http://localhost:8080';
  
  // Gmail API scope
  final scope = 'https://www.googleapis.com/auth/gmail.send';
  
  // Step 1: Generate authorization URL
  final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
    'client_id': clientId,
    'redirect_uri': redirectUri,
    'response_type': 'code',
    'scope': scope,
    'access_type': 'offline',
    'prompt': 'consent',
  });
  
  print('📋 Step 1: Open this URL in your browser:');
  print('');
  print(authUrl.toString());
  print('');
  print('👉 After authorizing, you\'ll be redirected to localhost:8080?code=...');
  print('👉 Copy the "code" value from the URL');
  print('');
  
  // Step 2: Start local server to receive the code
  print('🌐 Starting local server on http://localhost:8080...');
  print('   Waiting for authorization code...\n');
  
  String? authCode;
  
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  
  await for (HttpRequest request in server) {
    final code = request.uri.queryParameters['code'];
    
    if (code != null) {
      authCode = code;
      
      // Send success response to browser
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write('''
          <!DOCTYPE html>
          <html>
          <head><title>Success</title></head>
          <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1 style="color: green;">✅ Authorization Successful!</h1>
            <p>You can close this window now.</p>
            <p>Check your terminal for the refresh token.</p>
          </body>
          </html>
        ''');
      await request.response.close();
      
      break;
    } else {
      request.response
        ..statusCode = 400
        ..write('No authorization code found');
      await request.response.close();
    }
  }
  
  await server.close();
  
  if (authCode == null) {
    print('❌ No authorization code received');
    exit(1);
  }
  
  print('✅ Authorization code received!\n');
  
  // Step 3: Exchange code for refresh token
  print('🔄 Exchanging authorization code for refresh token...');
  
  final tokenResponse = await http.post(
    Uri.parse('https://oauth2.googleapis.com/token'),
    body: {
      'code': authCode,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri,
      'grant_type': 'authorization_code',
    },
  );
  
  if (tokenResponse.statusCode != 200) {
    print('❌ Failed to get tokens: ${tokenResponse.body}');
    exit(1);
  }
  
  final tokens = jsonDecode(tokenResponse.body);
  final refreshToken = tokens['refresh_token'];
  
  if (refreshToken == null) {
    print('❌ No refresh token in response. You might need to revoke access and try again.');
    print('   Go to: https://myaccount.google.com/permissions');
    exit(1);
  }
  
  print('\n✅ SUCCESS! Here are your credentials:\n');
  print('=' * 70);
  print('Add these to your Render environment variables:');
  print('=' * 70);
  print('');
  print('GMAIL_CLIENT_ID=$clientId');
  print('GMAIL_CLIENT_SECRET=$clientSecret');
  print('GMAIL_REFRESH_TOKEN=$refreshToken');
  print('GMAIL_USER_EMAIL=rayapureddyvardhan2004@gmail.com');
  print('');
  print('=' * 70);
  print('');
  print('📝 Next steps:');
  print('1. Go to Render dashboard: https://dashboard.render.com');
  print('2. Select your service: learnease-community-platform');
  print('3. Go to Environment tab');
  print('4. Add the above 4 environment variables');
  print('5. Save changes (Render will auto-deploy)');
  print('');
  print('🎉 After deployment, emails will be sent via Gmail API!');
}
