import 'package:flutter/material.dart';
import 'package:qualtive/qualtive.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const FetchEnquiryPage());
  }
}

class FetchEnquiryPage extends StatefulWidget {
  const FetchEnquiryPage({super.key});

  @override
  State<FetchEnquiryPage> createState() => _FetchEnquiryPageState();
}

class _FetchEnquiryPageState extends State<FetchEnquiryPage> {
  final _containerIdController = TextEditingController(text: 'ci-test');
  final _workspaceIdController = TextEditingController();
  final _enquiryIdController = TextEditingController(text: 'flutter');
  String _status = 'Enter a container and enquiry id, then fetch or post.';
  bool _loading = false;

  @override
  void dispose() {
    _containerIdController.dispose();
    _workspaceIdController.dispose();
    _enquiryIdController.dispose();
    super.dispose();
  }

  Qualtive _client() {
    final workspaceId = _workspaceIdController.text.trim();
    return Qualtive(
      containerId: _containerIdController.text.trim(),
      workspaceId: workspaceId.isEmpty ? null : workspaceId,
    );
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _status = 'Fetching…';
    });

    try {
      final enquiry = await _client().fetchEnquiry(
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

  Future<void> _post() async {
    setState(() {
      _loading = true;
      _status = 'Posting…';
    });

    try {
      final entry = await _client().post(
        _enquiryIdController.text.trim(),
        content: [
          EntryScore(value: 75),
          const EntryText(value: 'Hello from the Flutter demo'),
        ],
        options: const PostOptions(
          metadataCollection: MetadataCollection.none,
          userTrackingConsent: UserTrackingConsent.denied,
        ),
      );
      setState(() {
        _status = 'Posted entry id ${entry.id}';
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
              controller: _workspaceIdController,
              decoration: const InputDecoration(
                labelText: 'Workspace id (optional)',
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
              child: Text(_loading ? 'Working…' : 'Fetch enquiry'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : _post,
              child: const Text('Post sample entry'),
            ),
            const SizedBox(height: 24),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
