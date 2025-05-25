import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class HtmlExample extends StatelessWidget {
  const HtmlExample({super.key});

  @override
  Widget build(BuildContext context) {
    String htmlData = """
      <h2>Welcome!</h2>
      <p>This is a <b>Flutter</b> app rendering HTML.</p>
    """;

    return Scaffold(
      appBar: AppBar(title: Text("HTML Example")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Html(data: htmlData),
      ),
    );
  }
}
