import 'package:flutter/material.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Uncomment when generating native files

class MediaPolicyParser extends StatelessWidget {
  final String text;
  final bool isAdmin;
  
  const MediaPolicyParser({super.key, required this.text, this.isAdmin = false});

  bool _hasLinks(String input) {
    final RegExp linkRegExp = RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    return linkRegExp.hasMatch(input);
  }

  bool _isYouTubeLink(String input) {
    return input.contains('youtube.com') || input.contains('youtu.be');
  }

  @override
  Widget build(BuildContext context) {
    if (_hasLinks(text) && !isAdmin) {
       // Strict Link Policy Enforced
       return Container(
         padding: const EdgeInsets.all(8),
         color: Colors.red.shade100,
         child: const Row(
           children: [
             Icon(Icons.warning, color: Colors.red),
             SizedBox(width: 8),
             Expanded(child: Text("Links are not permitted. Only administrators are allowed to post links.", style: TextStyle(color: Colors.red))),
           ],
         ),
       );
    }

    if (_isYouTubeLink(text)) {
      // Embedded video player logic would go here using youtube_player_flutter
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60)),
      );
    }

    // Default Text Render
    return Text(text);
  }
}
