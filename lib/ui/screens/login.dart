import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repos/user.dart';
import '../../utils/validators.dart';
import '../dialogs.dart';
import '../widgets.dart';


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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userRepo = context.read<UserRepo>();
    setState(() => _isLoading = true);

    try {
      await userRepo.authenticate(
        _loginController.text,
        _passwordController.text,
      );
      await _success(context);
    } on Exception catch (e) {
      await showSimpleDialog(context, 'Авторизация не удалась (', e.toString());
      setState(() => _isLoading = false);
    }
  }

  _settings() {
    Navigator.of(context).pushNamed('/settings');
  }

  _restoreAuth() async {
    setState(() => _isLoading = true);

    final userRepo = context.read<UserRepo>();
    try {
      await userRepo.reload();
      _success(context);
    } on Exception {
      setState(() => _isLoading = false);
    }
  }

  Future _success(BuildContext context) {
    return Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }
}
