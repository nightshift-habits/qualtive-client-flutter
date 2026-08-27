import 'package:flutter/material.dart';
import 'package:qualtive/qualtive.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const FetchEnquiryPage(),
    );
  }
}

class FetchEnquiryPage extends StatefulWidget {
  const FetchEnquiryPage({super.key});

  @override
  State<FetchEnquiryPage> createState() => _FetchEnquiryPageState();
}

class _FetchEnquiryPageState extends State<FetchEnquiryPage> {
  final _containerIdController = TextEditingController(text: 'ci-test');
  final _enquiryIdController = TextEditingController(text: 'flutter');
  String _status = 'Enter a container and enquiry id, then fetch.';
  bool _loading = false;

  @override
  void dispose() {
    _containerIdController.dispose();
    _enquiryIdController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _status = 'Fetching…';
    });

    try {
      final client = Qualtive(containerId: _containerIdController.text.trim());
      final enquiry = await client.fetchEnquiry(
        _enquiryIdController.text.trim(),
      );
      setState(() {
        _status =
            'Fetched "${enquiry.name}" (${enquiry.slug})\n'
            'pages: ${enquiry.pages.length}, '
            'submittedPages: ${enquiry.submittedPages.length}';
      });
    } on QualtiveException catch (error) {
      setState(() {
        _status = 'Error: $error';
      });
    } on Object catch (error) {
      setState(() {
        _status = 'Unexpected: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qualtive demo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _containerIdController,
              decoration: const InputDecoration(
                labelText: 'Container id',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _enquiryIdController,
              decoration: const InputDecoration(
                labelText: 'Enquiry id / slug',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _fetch,
              child: Text(_loading ? 'Fetching…' : 'Fetch enquiry'),
            ),
            const SizedBox(height: 24),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
