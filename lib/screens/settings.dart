import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../utils/api_client.dart';
import '../utils/validators.dart';


class SettingsPage extends StatefulWidget {
  @override
  SettingsPageState createState() => SettingsPageState();
}


class SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _netDelayController = TextEditingController();
  String _scheme;
  bool _fake;
  bool _offline;

  @override
  void initState() {
    super.initState();

    final client = context.read<HttpApiClient>();
    _scheme = client.scheme;
    _hostController.text = client.host;
    _portController.text = client.port != null ? client.port.toString() : null;
    _netDelayController.text = client.netDelay.toString();
    _fake = client.fake;
    _offline = client.offline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
          children: [
            const Text(
              'API',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Фейковые данные'),
                Switch(
                  value: _fake,
                  onChanged: (newVal) => setState(() => _fake = newVal),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Оффлайн'),
                Switch(
                  value: _offline,
                  onChanged: (newVal) => setState(() => _offline = newVal),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Протокол'),
              value: _scheme,
              onChanged: (newVal) => setState(() => _scheme = newVal),
              items: [
                DropdownMenuItem(
                  value: 'http',
                  child: const Text('HTTP'),
                ),
                DropdownMenuItem(
                  value: 'https',
                  child: const Text('HTTPS'),
                ),
              ],
            ),
            TextFormField(
              enabled: !_fake,
              controller: _hostController,
              validator: requiredString,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(labelText: 'Хост'),
            ),
            TextFormField(
              enabled: !_fake,
              controller: _portController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Порт',
                hintText: 'авто',
                helperText: 'пусто - автоопределение',
              ),
            ),
            TextFormField(
              controller: _netDelayController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Задержка сети (сек)',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              child: const Text('Сохранить'),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  _save() async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    final client = context.read<HttpApiClient>();
    client.configure(
      scheme: _scheme,
      host: _hostController.text,
      port: _portController.text != '' ? int.parse(_portController.text) : null,
      fake: _fake,
      offline: _offline,
      netDelay: _netDelayController.text != '' ? int.parse(_netDelayController.text) : 0,
    );
    await client.storeSettings();
    Navigator.of(context).pop();
  }
}
