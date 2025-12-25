import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PostApiDemo extends StatefulWidget {
  const PostApiDemo({super.key});

  @override
  State<PostApiDemo> createState() => _PostApiDemoState();
}

class _PostApiDemoState extends State<PostApiDemo> {
  final TextEditingController _controller = TextEditingController();
  String _response = "";

  Future<void> sendPostRequest(String text) async {
    final url = Uri.parse("https://jsonplaceholder.typicode.com/posts");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": text,
        "body": "This Dummy Body",
        "userId": 5,
      }),
    );

    setState(() {
      if (response.statusCode == 201) {
        _response = "Success: ${response.body}";
      } else {
        _response = "Error: ${response.statusCode}";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("POST API Example")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Enter Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                sendPostRequest(_controller.text);
              },
              child: const Text("Send POST Request"),
            ),
            const SizedBox(height: 16),
            Text(_response),
          ],
        ),
      ),
    );
  }
}
