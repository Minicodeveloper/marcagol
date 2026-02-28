import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/chat_message_widget.dart';

/// Pantalla de detalle de partido en vivo con chat
/// TODO: Implementar chat en tiempo real con Firestore
class LiveMatchDetailScreen extends StatefulWidget {
  final String league;
  final String team1;
  final String team2;
  final String score1;
  final String score2;
  final String time;

  const LiveMatchDetailScreen({
    super.key,
    required this.league,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    required this.time,
  });

  @override
  State<LiveMatchDetailScreen> createState() => _LiveMatchDetailScreenState();
}

class _LiveMatchDetailScreenState extends State<LiveMatchDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  
  // TODO: Reemplazar con Stream de Firestore
  final List<Map<String, String>> _messages = [
    {'user': 'Carlos M.', 'message': '¡Vamos equipoo! 💪', 'time': '67\''},
    {'user': 'Ana P.', 'message': 'Buen partido', 'time': '65\''},
    {'user': 'Luis G.', 'message': 'Necesitamos otro gol', 'time': '63\''},
    {'user': 'María S.', 'message': 'Defensa sólida 🛡️', 'time': '60\''},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implementar compartir partido
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Marcador
          _buildScoreSection(),
          
          // Chat en Vivo
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _buildChatHeader(),
                  Expanded(
                    child: _buildChatMessages(),
                  ),
                  _buildMessageInput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.liveRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'EN VIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.liveRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.team1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.score1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '-',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.team2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.score2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.people, color: Colors.white70, size: 16),
              SizedBox(width: 4),
              Text(
                '1,234 espectadores',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Color(0xFF3A3A3A)),
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.chat_bubble, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text(
            'Chat en Vivo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    // TODO: Reemplazar con StreamBuilder de Firestore
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        return ChatMessageWidget(
          user: message['user']!,
          message: message['message']!,
          time: message['time']!,
          isMe: false,
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0xFF3A3A3A)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  // TODO: Enviar mensaje a Firestore
                  setState(() {
                    _messages.add({
                      'user': 'Tú',
                      'message': _messageController.text,
                      'time': widget.time,
                    });
                    _messageController.clear();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}