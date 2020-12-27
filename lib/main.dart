import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repos/imported_resources.dart';
import 'repos/user.dart';
import 'screens/home.dart';
import 'screens/imported_resource_edit.dart';
import 'screens/imported_resource_view.dart';
import 'screens/login.dart';
import 'screens/settings.dart';
import 'utils/api_client.dart';


class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill manager',
      theme: ThemeData.light(),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        primaryColor: Colors.green,
        accentColor: Colors.greenAccent[700],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.dark,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/settings': (context) => SettingsPage(),
        '/home': (context) => HomePageWrapper(),
        '/imported_resource/view': (context) => ImportedResourceViewPage(),
        '/imported_resource/edit': (context) => ImportedResourceEditPage(),
      },
    );
  }
}


void main() {
  runApp(MultiProvider(
    providers: [
      Provider(create: (context) => HttpApiClient()),
      ChangeNotifierProxyProvider<HttpApiClient, UserRepo>(
        create: (context) => UserRepo(),
        update: (context, client, repo) => repo..client = client,
      ),
      ProxyProvider<HttpApiClient, ImportedResourceRepo>(
        create: (context) => ImportedResourceRepo(),
        update: (context, client, repo) => repo..client = client,
      ),
    ],
    child: App(),
  ));
}
