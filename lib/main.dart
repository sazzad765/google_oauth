import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_oauth/web_view.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google OAuth2 Example',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _accessToken = '';
  bool _isLoggedIn = false;

  static const String clientId =
      '';
  static const String clientSecret = '';
  static const String redirectUri = 'https://oauth.pstmn.io/v1/callback';
  static const String scopes = 'https%3A//www.googleapis.com/auth/drive.metadata.readonly';

  @override
  void initState() {
    super.initState();
    checkLoggedIn();
  }

  void checkLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String accessToken = prefs.getString('accessToken') ?? '';
    if (accessToken.isNotEmpty) {
      setState(() {
        _accessToken = accessToken;
        _isLoggedIn = true;
      });
    }
  }

  Future<void> loginWithGoogle() async {
    // Construct the URL for authorization
    final authorizationUrl =
        'https://accounts.google.com/o/oauth2/auth?client_id=$clientId&redirect_uri=$redirectUri&response_type=code&scope=$scopes';

    // Open a webview to let the user login
    // In a real app, you would use a WebView or an external browser
    // to open this URL
    // After successful login, Google redirects with the authorization code
    print('authorizationUrl: ${authorizationUrl}');

    // final data = await Navigator.of(context).push(MaterialPageRoute(
    //   builder: (context) =>
    //       CustomWebView(url: authorizationUrl, redirectUri: redirectUri),
    // ));

    final result = await FlutterWebAuth2.authenticate(url: authorizationUrl, callbackUrlScheme: 'postman');


    // Listen for the redirect URL
    print('authorizationUrl: ${result}');
    if (result != null) {
      handleAuthorizationCode(Uri.parse(result).queryParameters['code']!);
    }

    // Simulated redirect
  }

  void handleAuthorizationCode(String code) async {
    if (code != null && code.isNotEmpty) {
      // Exchange authorization code for access token
      final tokenEndpoint = 'https://oauth2.googleapis.com/token';
      final tokenResponse = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': code,
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      );
      print('tokenResponse: ${tokenResponse.body}');

      if (tokenResponse.statusCode == 200) {
        final tokenJson = jsonDecode(tokenResponse.body);
        final accessToken = tokenJson['access_token'];
        if (accessToken != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('accessToken', accessToken);
          setState(() {
            _accessToken = accessToken;
            _isLoggedIn = true;
          });
        }
      }
    }
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('accessToken');
    setState(() {
      _accessToken = '';
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google OAuth2 Example'),
      ),
      body: Center(
        child: _isLoggedIn
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Logged in with Google!'),
                  SizedBox(height: 20),
                  Text('Access Token:'),
                  Text(_accessToken),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: logout,
                    child: Text('Logout'),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: loginWithGoogle,
                child: Text('Login with Google'),
              ),
      ),
    );
  }
}
