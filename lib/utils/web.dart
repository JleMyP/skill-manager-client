import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';


// https://pub.dev/packages/flutter_inappwebview/example
// или launch(url, forceWebView: true)

openWeb(BuildContext context, String url) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(
        title: Text(url),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_new),
            onPressed: () => launch(url),
          ),
        ],
      ),
      body: SafeArea(
        child: WebView(
          initialUrl: url,
          javascriptMode: JavascriptMode.unrestricted,
        ),
      ),
    ))
  );
}
