import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/config.dart';
import 'data/repos/imported_resources.dart';
import 'data/repos/tag.dart';
import 'data/repos/user.dart';
import 'ui/screens/home.dart';
import 'ui/screens/imported_resource_edit.dart';
import 'ui/screens/imported_resource_view.dart';
import 'ui/screens/login.dart';
import 'ui/screens/settings.dart';
import 'ui/screens/tag_view.dart';


class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill manager',
      darkTheme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green,
        ),
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        primaryColor: Colors.green,
        primaryColorDark: Colors.green,
        colorScheme: ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.greenAccent[700]!,
        ),
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
        '/tag/view': (context) => TagViewPage(),
      },
    );
  }
}


void main() {
  Provider.debugCheckInvalidValueType = null;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Config()..restore()),
        ChangeNotifierProxyProvider<Config, HttpApiClient?>(
          create: (context) => null,
          update: (context, config, client) => HttpApiClient(config: config)..restoreSettings(),
        ),
        ChangeNotifierProxyProvider2<HttpApiClient, Config, UserRepo?>(
          create: (context) => null,
          update: (context, client, config, repo) {
            if (repo is UserHttpRepo && repo.client == client) return repo;
            return createUserRepo(config, client);
          },
        ),
        ProxyProvider2<HttpApiClient, Config, ImportedResourceRepo>(
          update: (context, client, config, repo) {
            if (repo is ImportedResourceHttpRepo && repo.client == client) return repo;
            return createImportedResourceRepo(config, client);
          },
        ),
        ProxyProvider2<HttpApiClient, Config, TagRepo>(
          update: (context, client, config, repo) {
            if (repo is TagHttpRepo && repo.client == client) return repo;
            return createTagRepo(config, client);
          },
        ),
      ],
      child: App(),
    )
  );
}
