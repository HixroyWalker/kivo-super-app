import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/social_feed_provider.dart';
import '../../widgets/sandboxed_video_player.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  XFile? _selectedImage;
  String? _detectedYouTubeId;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _captionController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _captionController.text;
    final ytId = SocialFeedProvider.extractYouTubeId(text);
    if (ytId != _detectedYouTubeId) {
      setState(() {
        _detectedYouTubeId = ytId;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
          _detectedYouTubeId = null; // Prioritize selected image or allow both
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _publishPost() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty && _selectedImage == null && _detectedYouTubeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption, photo, or YouTube link.')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      // In production, upload _selectedImage to Firebase Storage. Here we pass the path or simulated URL.
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = _selectedImage!.path.startsWith('http') 
            ? _selectedImage!.path 
            : 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800';
      }

      await context.read<SocialFeedProvider>().createPost(
        caption: caption,
        imageUrl: imageUrl,
        youtubeVideoId: _detectedYouTubeId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00C853),
            content: Text('Post published to Kivo Feed! 🇯🇲'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  void dispose() {
    _captionController.removeListener(_onTextChanged);
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101726),
        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _publishPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption Input
            TextField(
              controller: _captionController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: "What's happening in Jamaica? Paste a YouTube link or share a photo...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),

            // Live YouTube Embed Preview
            if (_detectedYouTubeId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141E33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.ondemand_video, color: Color(0xFFFFD700), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Embedded Video Preview (Sandboxed)',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SandboxedVideoPlayer(videoId: _detectedYouTubeId!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Selected Image Preview
            if (_selectedImage != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_selectedImage!.path),
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.white10,
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.white54, size: 48),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Action Toolbar (Camera / Gallery / YouTube Info)
            const Divider(color: Colors.white12),
            Row(
              children: [
                IconButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, color: Color(0xFFFFD700)),
                  tooltip: 'Add Photo from Gallery',
                ),
                IconButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, color: Color(0xFFFFD700)),
                  tooltip: 'Take Photo with Camera',
                ),
                const Spacer(),
                const Text(
                  'Auto-detects YouTube Links',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
