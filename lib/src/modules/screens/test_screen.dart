import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dashboard/src/config/enums/ticket_status.dart';

import '../../service/data_service.dart';
import '../models/ticket.dart';
import '../models/user.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text("Test Screen"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: StreamBuilder<Ticket>(
        // stream: DataService.getUserTickets(
        //   userId: userUid,
        //   publisher: 'asdasd',
        // ),
        stream: DataService.getTicketWithFiles(
          Ticket(
            ticketId: "H4nlFmFIdXqBsJEbhq4A",
            title: 'title',
            description: "description",
            status: TicketStatus.unknown,
            publisher: 'publisher',
            createdDate: DateTime.now(),
          ),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          // } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          } else if (!snapshot.hasData) {
            return Text('No users found');
          }

          final ticket = snapshot.data!;

          return ListView.builder(
            itemCount: ticket.files.length,
            itemBuilder: (context, index) {
              final currTicket = ticket.files[index];
              return Card(
                child: ListTile(
                  title: Text(currTicket.fileName),
                  subtitle: Text(currTicket.url),
                  // onTap: () {
                  //   showDialog(
                  //     context: context,
                  //     builder: (context) {
                  //       return AlertDialog(
                  //         content: StreamBuilder(
                  //           stream: DataService.getTicketWithFiles(ticket),
                  //           builder: (_, snapshot) {
                  //             if (snapshot.connectionState ==
                  //                 ConnectionState.waiting) {
                  //               return CircularProgressIndicator();
                  //             } else if (snapshot.hasError) {
                  //               return Text('Error: ${snapshot.error}');
                  //             } else if (!snapshot.hasData) {
                  //               return Text('No users found');
                  //             }
                  //
                  //             final ticket = snapshot.data!;
                  //
                  //             return ListView.builder(
                  //               itemCount: ticket.files.length,
                  //               itemBuilder: (_, idx) => Text(
                  //                 ticket.files[idx].fileName,
                  //               ),
                  //             );
                  //           },
                  //         ),
                  //       );
                  //     },
                  //   );
                  // },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
