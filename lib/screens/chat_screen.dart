import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import 'dart:async';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isComposing = false;
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }
  
  @override
  void dispose() {
    _reconnectTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });
    
    try {
      print('Initializing chat and testing connection...');
      final isConnected = await GeminiService.testConnection();
      
      if (!isConnected) {
        print("Connection test returned false - server might be unreachable");
        setState(() {
          _isError = true;
          _errorMessage = 'Unable to connect to the server. Please check if the backend is running.';
        });
        
        // Schedule periodic reconnection attempts
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer.periodic(Duration(seconds: 30), (timer) {
          print("Attempting automatic reconnection...");
          _retryConnection();
        });
      } else {
        print("Connection test successful");
        setState(() {
          _isError = false;
          _errorMessage = '';
        });
        
        // Cancel reconnect timer if it exists
        _reconnectTimer?.cancel();
        
        if (_messages.isEmpty) {
          // Add a welcome message when successfully connected
          setState(() {
            _messages.insert(0, Message(
              text: 'Hello! I\'m your Plant Care Assistant. How can I help you today?',
              isUser: false,
            ));
          });
        }
      }
    } catch (e) {
      print('Error during initialization: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _retryConnection() async {
    try {
      final isConnected = await GeminiService.testConnection();
      if (isConnected && mounted) {
        setState(() {
          _isError = false;
          _errorMessage = '';
        });
        
        _reconnectTimer?.cancel();
        
        // Add a reconnected message
        if (_messages.isEmpty) {
          setState(() {
            _messages.insert(0, Message(
              text: 'Hello! I\'m your Plant Care Assistant. How can I help you today?',
              isUser: false,
            ));
          });
        } else {
          setState(() {
            _messages.insert(0, Message(
              text: 'I\'m back online and ready to help!',
              isUser: false,
            ));
          });
        }
      }
    } catch (e) {
      print('Auto-reconnect attempt failed: $e');
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _isComposing = false;
      _messages.insert(0, Message(
        text: text,
        isUser: true,
      ));
      _isLoading = true;
    });

    try {
      final response = await GeminiService.generateResponse(text);
      if (mounted) {
        setState(() {
          _messages.insert(0, Message(
            text: response,
            isUser: false,
          ));
          _isError = false;
        });
      }
    } catch (e) {
      print('Error generating response: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to get response: ${e.toString()}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _initializeChat(),
              ),
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Care Assistant'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeChat,
            tooltip: 'Reconnect to server',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isError)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connection error: $_errorMessage',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trying to connect to: ${GeminiService.baseUrl}',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _initializeChat,
                        child: const Text('Retry Connection'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _buildMessage(_messages[index]),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/icons/chatbot.png'),
                    radius: 12,
                  ),
                  SizedBox(width: 8),
                  Text('Typing...'),
                ],
              ),
            ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.trim().isNotEmpty;
                  });
                },
                onSubmitted: _isComposing ? _handleSubmitted : null,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Ask about plant care...',
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isComposing
                    ? () => _handleSubmitted(_textController.text)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Image.asset(
                  'assets/icons/chatbot.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: message.isUser
                    ? null
                    : Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 16),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
