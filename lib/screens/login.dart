import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repos/user.dart';
import '../utils/api_client.dart';
import '../utils/dialogs.dart';
import '../utils/validators.dart';
import '../utils/widgets.dart';


class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}


class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _restoreAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill manager'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _settings,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(50),
          children: [
            const Text(
              'Вход',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _loginController,
              validator: requiredString,
              decoration: const InputDecoration(labelText: 'Логин'),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),
            TextFormField(
              controller: _passwordController,
              validator: requiredString,
              enabled: !_isLoading,
              decoration: const InputDecoration(labelText: 'Пароль'),
            ),
            const SizedBox(height: 30),
            _isLoading ? const BodyLoading()
                : ElevatedButton(
                  child: const Text('Вход'),
                  onPressed: _login,
                ),
          ],
        ),
      ),
    );
  }

  _login() async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    final userRepo = context.read<UserRepo>();
    setState(() => _isLoading = true);

    try {
      await userRepo.authenticate(_loginController.text,
          _passwordController.text);
      await _storeAuth();
      await Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } on Exception catch (e) {
      await showSimpleDialog(context, 'Авторизация не удалась (', e.toString());
      setState(() => _isLoading = false);
    }
  }

  _settings() {
    Navigator.of(context).pushNamed('/settings');
  }

  _restoreAuth() async {
    final client = context.read<HttpApiClient>();
    await client.restoreSettings();

    final sharedPreferences = await SharedPreferences.getInstance();
    _loginController.text = sharedPreferences.getString('auth:login');
    _passwordController.text = sharedPreferences.getString('auth:password');
    final autoLogin = sharedPreferences.getBool('auth:autoLogin') ?? false;

    if (autoLogin && _loginController.text != null &&
        _passwordController.text != null) {
      await _login();
    }
  }

  _storeAuth() async {
    await SharedPreferences.getInstance()
      ..setString('auth:login', _loginController.text)
      ..setString('auth:password', _passwordController.text)
      ..setBool('auth:autoLogin', true);
  }
}
