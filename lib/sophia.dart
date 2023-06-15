import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Tutor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WhatsAppChatScreen(),
    );
  }
}

class WhatsAppChatScreen extends StatefulWidget {
  const WhatsAppChatScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _WhatsAppChatScreenState createState() => _WhatsAppChatScreenState();
}

class _WhatsAppChatScreenState extends State<WhatsAppChatScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final List<Message> _messages = [];
  final Set<int> _readMessageIds = {};

  Future<String> getAIResponse(String message) async {
    var url = Uri.parse(
        "https://api.openai.com/v1/engines/text-davinci-003/completions");
    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer token",
    };
    var body = jsonEncode({
      "prompt":
          "Sophia is a chatbot that only understand english and that reluctantly answers questions with sarcastic responses You: $message",
      "temperature": 0.5,
      "max_tokens": 30,
      "top_p": 1.0,
      "frequency_penalty": 0.5,
      "presence_penalty": 0.0,
      "stop": ["You:"]
    });

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var choices = data["choices"];
      if (choices.isNotEmpty) {
        return choices[0]["text"];
      }
    }

    return "Error: Failed to get AI response";
  }

  void _sendMessage() async {
    String text = _textEditingController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(Message(sender: 'Eu', text: text, isRead: true));
        _textEditingController.clear();
      });

      String aiResponse = await getAIResponse(text);

      setState(() {
        _messages.add(Message(
            sender: 'Sophia Bennett',
            text: aiResponse
                .replaceAll(RegExp(r'Sophia:'), '')
                .replaceAll("\n", "")));
      });
    }
  }

  void _markMessageAsRead(int messageId) {
    setState(() {
      _readMessageIds.add(messageId);
    });
  }

  bool _isMessageRead(int messageId) {
    return _readMessageIds.contains(messageId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CircleAvatar(
          backgroundImage: AssetImage("assets/contact_photo.jpg"),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sophia Bennett',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Online',
              style:
                  TextStyle(fontSize: 12, color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/wallpaper.jpg"), // Substitua pelo caminho da sua imagem de fundo
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  Message message = _messages[index];
                  return MessageBubble(
                    messageId: index,
                    sender: message.sender,
                    text: message.text,
                    isMe: message.sender == 'Eu',
                    isRead: _isMessageRead(index),
                    onMessageRead: _markMessageAsRead,
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textEditingController,
                      decoration: const InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Message {
  final String sender;
  final String text;
  final bool isRead;

  Message({required this.sender, required this.text, this.isRead = false});
}

class MessageBubble extends StatelessWidget {
  final int messageId;
  final String sender;
  final String text;
  final bool isMe;
  final bool isRead;
  final Function(int) onMessageRead;

  const MessageBubble({
    Key? key,
    required this.messageId,
    required this.sender,
    required this.text,
    required this.isMe,
    required this.isRead,
    required this.onMessageRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isMe && !isRead) {
      // Marcar a mensagem como lida
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onMessageRead(messageId);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(
              fontSize: 12.0,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          Material(
            borderRadius: isMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 30.0, 10.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15.0,
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                if (isMe && isRead)
                  const Positioned(
                    bottom: 0,
                    right: 10,
                    child: Icon(
                      Icons.done_all,
                      color: Color.fromARGB(255, 4, 84, 150),
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
