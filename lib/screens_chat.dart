import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';
import 'models.dart';
import 'services.dart';

// Chat temps réel lié à un trajet, entre deux personnes (conducteur/passager).
class ChatScreen extends StatefulWidget {
  final Trip trip;
  final String peerId;
  final String peerName;
  const ChatScreen(
      {super.key, required this.trip, required this.peerId, required this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final msgC = TextEditingController();
  final scrollC = ScrollController();
  StreamSubscription<List<ChatMessage>>? sub;
  List<ChatMessage> messages = [];
  bool sending = false;

  @override
  void initState() {
    super.initState();
    sub = Db.messagesStream(widget.trip.id).listen((all) {
      final me = Db.uid;
      final filtered = all
          .where((m) =>
              (m.senderId == me && m.receiverId == widget.peerId) ||
              (m.senderId == widget.peerId && m.receiverId == me))
          .toList();
      if (mounted) {
        setState(() => messages = filtered);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollC.hasClients) {
            scrollC.jumpTo(scrollC.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  Future<void> send() async {
    final txt = msgC.text.trim();
    if (txt.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await Db.sendMessage(widget.trip.id, widget.peerId, txt);
      msgC.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Message non envoyé — vérifie ta connexion.")));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = Db.uid;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.peerName, style: const TextStyle(fontSize: 16)),
            Text("${widget.trip.fromCity} → ${widget.trip.toCity}",
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text("Écris le premier message 👋",
                        style: TextStyle(color: Colors.black45)))
                : ListView.builder(
                    controller: scrollC,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final m = messages[i];
                      final mine = m.senderId == me;
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: mine ? CvColors.green : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(mine ? 14 : 3),
                              bottomRight: Radius.circular(mine ? 3 : 14),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(m.body,
                                  style: TextStyle(
                                      color:
                                          mine ? Colors.white : Colors.black87)),
                              Text(
                                DateFormat.Hm().format(m.createdAt),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: mine
                                        ? Colors.white70
                                        : Colors.black38),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: msgC,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: const InputDecoration(hintText: "Ton message…"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: CvColors.green,
                    child: IconButton(
                      onPressed: send,
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
