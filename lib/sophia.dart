//Essas importações são necessárias para usar as bibliotecas Dart e Flutter necessárias para o funcionamento do aplicativo, incluindo a conversão de JSON, o envio de solicitações HTTP e o uso de widgets do Flutter.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

//Função principal:
//A função main() é o ponto de entrada do aplicativo Flutter. Ela chama a função runApp() para iniciar a execução do aplicativo com o widget MyApp.
void main() {
  runApp(const MyApp());
}

//Classe MyApp
//A classe MyApp é um widget de aplicativo Flutter que configura a aparência e a estrutura do aplicativo. No método build(), ele retorna um widget MaterialApp com um tema e define a tela inicial como WhatsAppChatScreen.
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

//A classe WhatsAppChatScreen é um widget de tela do Flutter que representa a tela de bate-papo do WhatsApp. Ela estende StatefulWidget para que possa ter um estado mutável. O método createState() retorna uma instância da classe _WhatsAppChatScreenState, que é responsável por gerenciar o estado da tela.
class WhatsAppChatScreen extends StatefulWidget {
  const WhatsAppChatScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _WhatsAppChatScreenState createState() => _WhatsAppChatScreenState();
}

//A classe _WhatsAppChatScreenState é o estado da tela de bate-papo do WhatsApp. Ela mantém o controle do estado dos campos de texto, mensagens enviadas e lidas, e também possui uma variável _isSendingMessage que indica se uma mensagem está sendo enviada ou não. Ele usa um controlador TextEditingController para rastrear o texto digitado pelo usuário
class _WhatsAppChatScreenState extends State<WhatsAppChatScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final List<Message> _messages = [];
  final Set<int> _readMessageIds = {};
  bool _isSendingMessage = false;

  //Função getAIResponse():
  //A função getAIResponse() é uma função assíncrona que faz uma solicitação HTTP POST para a API do OpenAI para obter uma resposta do chatbot. Ela recebe uma mensagem como entrada e retorna uma Future<String> contendo a resposta.
  //Nesta função, um URL da API é definido com base na URL fornecida. Os cabeçalhos são definidos com o tipo de conteúdo como JSON e um token de autorização. O corpo da solicitação é definido usando jsonEncode() para criar uma sequência JSON contendo a mensagem do usuário.
  //Em seguida, a solicitação HTTP POST é enviada usando http.post(), passando o URL, cabeçalhos e corpo da solicitação. Se a resposta tiver um código de status 200 (sucesso), os dados da resposta são decodificados usando jsonDecode() e podem ser processados de acordo.
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
      "max_tokens": 60,
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

  //O método _sendMessage() é chamado quando o botão de envio é pressionado. Ele primeiro obtém o texto da mensagem do controlador _textEditingController, removendo quaisquer espaços em branco no início e no final.
  //Em seguida, é verificado se o texto da mensagem não está vazio. Se não estiver vazio, uma nova mensagem é criada usando o texto e um ID único com base no comprimento atual da lista _messages.
  //O estado do aplicativo é atualizado usando setState() para adicionar a nova mensagem à lista _messages e definir _isSendingMessage como true. O controlador _textEditingController é limpo para que o campo de texto seja esvaziado.
  //Em seguida, a função getAIResponse() é chamada para obter a resposta do chatbot. Assim que a resposta for recebida, o estado é atualizado novamente usando setState() para adicionar a resposta à lista _messages e marcar a mensagem enviada como lida adicionando o ID à lista _readMessageIds.
  //Dessa forma, a interface do usuário é atualizada automaticamente com as mensagens enviadas e recebidas.
  void _sendMessage() async {
    String text = _textEditingController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(Message(sender: 'Eu', text: text, isRead: true));
        _textEditingController.clear();
        _isSendingMessage = true;
      });

      String aiResponse = await getAIResponse(text);

      setState(() {
        _messages.add(Message(
            sender: 'Sophia Bennett',
            text: aiResponse
                .replaceAll(RegExp(r'Sophia:'), '')
                .replaceAll("\n", "")));
        _isSendingMessage = false;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sophia Bennett',
              style: TextStyle(fontSize: 16),
            ),
            if (_isSendingMessage)
              const Text(
                'Escrevendo...',
                style: TextStyle(
                    fontSize: 12, color: Color.fromARGB(255, 0, 0, 0)),
              )
            else
              const Text(
                'Online',
                style: TextStyle(
                    fontSize: 12, color: Color.fromARGB(255, 0, 0, 0)),
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
