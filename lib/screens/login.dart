import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repos/user.dart';
import '../utils/api_client.dart';
import '../utils/dialogs.dart';
import '../utils/validators.dart';


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
    List<Widget> actions;
    if (_isLoading) {
      actions = [
        Center(child: CircularProgressIndicator()),
      ];
    } else {
      actions = [
        RaisedButton(
          child: Text('Вход'),
          onPressed: _login,
        ),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Skill manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _isLoading ? null : _settings,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(50),
          children: [
            Text(
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
              decoration: InputDecoration(labelText: 'Логин'),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),
            TextFormField(
              controller: _passwordController,
              validator: requiredString,
              enabled: !_isLoading,
              decoration: InputDecoration(labelText: 'Пароль'),
            ),
            const SizedBox(height: 30),
            ...actions,
          ],
        ),
      ),
    );
  }

  _login() async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    var userRepo = context.read<UserRepo>();
    setState(() => _isLoading = true);
    try {
      await userRepo.authenticate(_loginController.text,
          _passwordController.text);
      await _storeAuth();
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } on Exception catch (e) {
      await showSimpleDialog(context, 'Авторизация не удалась (', e.toString());
      setState(() => _isLoading = false);
    }
  }

  _settings() {
    Navigator.of(context).pushNamed('/settings');
  }

  _restoreAuth() async {
    var client = context.read<HttpApiClient>();
    await client.restoreSettings();
    var sharedPreferences = await SharedPreferences.getInstance();
    _loginController.text = sharedPreferences.getString('auth:login');
    _passwordController.text = sharedPreferences.getString('auth:password');
    var autoLogin = sharedPreferences.getBool('auth:autoLogin') ?? false;

    if (autoLogin && _loginController.text != null &&
        _passwordController.text != null) {
      await _login();
    }
  }

  _storeAuth() async {
    var sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString('auth:login', _loginController.text);
    sharedPreferences.setString('auth:password', _passwordController.text);
    sharedPreferences.setBool('auth:autoLogin', true);
  }
}
