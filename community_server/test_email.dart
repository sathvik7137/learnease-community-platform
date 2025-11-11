import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// Simple .env file reader
String? _readLocalEnv(String key, {String path = '.env'}) {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    
    final lines = file.readAsLinesSync();
    for (final line in lines) {
      if (line.trim().startsWith('#')) continue;
      if (line.contains('=')) {
        final parts = line.split('=');
        if (parts[0].trim() == key) {
          return parts.sublist(1).join('=').trim();
        }
      }
    }
  } catch (e) {
    // Ignore errors
  }
  return null;
}

void main() async {
  print('📧 Testing email configuration...\n');
  
  try {
    // Get SMTP credentials
    var smtpUser = Platform.environment['SMTP_USER'];
    smtpUser ??= _readLocalEnv('SMTP_USER', path: '.env');
    
    var smtpPass = Platform.environment['SMTP_PASSWORD'];
    smtpPass ??= _readLocalEnv('SMTP_PASSWORD', path: '.env');
    
    print('📋 Configuration:');
    print('   SMTP_USER: ${smtpUser ?? "NOT SET"}');
    print('   SMTP_PASSWORD: ${smtpPass != null ? "***${smtpPass.substring(smtpPass.length - 4)}" : "NOT SET"}');
    print('');
    
    if (smtpUser == null || smtpPass == null) {
      print('❌ SMTP credentials not found!');
      print('   Set SMTP_USER and SMTP_PASSWORD in .env file');
      exit(1);
    }
    
    // Test email sending
    print('📤 Sending test email to: $smtpUser');
    print('   (Sending to yourself to test configuration)');
    print('');
    
    final smtpServer = gmail(smtpUser, smtpPass);
    final message = Message()
      ..from = Address(smtpUser, 'LearnEase Test')
      ..recipients.add(smtpUser)
      ..subject = 'LearnEase Email Test - ${DateTime.now()}'
      ..text = 'This is a test email from LearnEase server.\n\nIf you received this, email configuration is working!'
      ..html = '<h1>✅ Email Configuration Working!</h1><p>This is a test email from LearnEase server.</p><p><strong>Sent at:</strong> ${DateTime.now()}</p>';
    
    print('⏳ Connecting to Gmail SMTP server...');
    final sendReport = await send(message, smtpServer).timeout(const Duration(seconds: 15));
    
    print('\n✅ Email sent successfully!');
    print('📊 Send report:');
    print('   ${sendReport.toString()}');
    print('\n🎉 Check your inbox at: $smtpUser');
    
  } catch (e, stackTrace) {
    print('\n❌ Email send failed!');
    print('   Error: $e');
    print('');
    
    if (e is MailerException) {
      print('📋 Mailer problems:');
      for (var p in e.problems) {
        print('   • ${p.code}: ${p.msg}');
      }
    }
    
    print('\n🔍 Common issues:');
    print('   1. Wrong SMTP_PASSWORD - regenerate app password in Gmail');
    print('   2. 2-Step Verification not enabled in Google Account');
    print('   3. App password revoked or expired');
    print('   4. Gmail blocking sign-in attempts');
    print('   5. Network/firewall blocking port 465/587');
    print('');
    print('Stack trace:');
    print(stackTrace);
    exit(1);
  }
}
