import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TicketDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> ticketData;

  const TicketDetailsScreen({Key? key, required this.ticketData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final files = ticketData['files'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${ticketData['title']}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Description: ${ticketData['description']}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Status: ${ticketData['status']}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text('Files:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...files.map((fileUrl) {
              return ListTile(
                title: Text(fileUrl),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    _downloadFile(fileUrl);
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _downloadFile(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
