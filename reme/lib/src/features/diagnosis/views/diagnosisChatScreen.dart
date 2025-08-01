import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reme/src/features/chat/views/chatView.dart';
import 'package:reme/src/features/diagnosis/views/analysisResultsScreen.dart';
import 'package:reme/src/features/diagnosis/services/face_analysis_service.dart';
import 'package:reme/src/features/profile/services/profileServices.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class DiagnosisChatScreen extends StatefulWidget {
  final File faceImage;
  
  const DiagnosisChatScreen({
    super.key,
    required this.faceImage,
  });
  
  @override
  State<DiagnosisChatScreen> createState() => _DiagnosisChatScreenState();
}

class _DiagnosisChatScreenState extends State<DiagnosisChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _questions = [
    {
      'question': '写真と追加情報に基づいてお肌を分析します。まず、あなたの年齢層を教えてください。',
      'options': ['20代', '30代', '40代', '50代', '60代以上'],
      'answer': null,
    },
    {
      'question': '毎日メイクをしていますか？',
      'options': ['毎日', '週に数回', 'ほとんどしない', '全くしない'],
      'answer': null,
    },
    {
      'question': 'どのくらいUV対策をしていますか？',
      'options': ['毎日SPF30以上を使用', '外出時のみ', 'ほとんどしない', '全くしない'],
      'answer': null,
    },
    {
      'question': 'お肌の悩みを選択してください（複数選択可）：',
      'options': ['毛穴', 'シミ', '赤み', '乾燥', 'たるみ', 'ニキビ', '小じわ', '脂性肌'],
      'answer': null,
      'multiSelect': true,
    },
    {
      'question': '現在使用しているスキンケア製品を選択してください（複数選択可）：',
      'options': ['洗顔料', '化粧水', '美容液', '保湿クリーム', '日焼け止め', '角質ケア', 'フェイスマスク', 'アイクリーム', 'なし'],
      'answer': null,
      'multiSelect': true,
    },
    {
      'question': '理想のお肌の状態は？（複数選択可）',
      'options': ['透明感のある肌', '毛穴レス', '潤いのある肌', '均一な肌トーン', 'ハリと弾力のある肌', '肌トラブルのない肌'],
      'answer': null,
      'multiSelect': true,
    },
    {
      'question': 'お肌の状態は季節によって変化しますか？',
      'options': ['はい、大きく変化します', 'はい、少し変化します', 'いいえ、ほとんど変わりません'],
      'answer': null,
    },
  ];
  
  int _currentQuestionIndex = 0;
  bool _analysisComplete = false;
  bool _isAnalyzing = false;
  String? _geminiAnalysisResult; // Store the actual Gemini result
  File? _croppedFaceImage;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FaceAnalysisService _analysisService = FaceAnalysisService();
  
  @override
  void initState() {
    super.initState();
    // Add welcome message
    _addAiMessage('こんにちは！お肌の画像を分析しています...');
    
    // Start the actual Gemini analysis in the background
    _performGeminiAnalysis();
    
    // Add first question after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      _addAiMessage(_questions[_currentQuestionIndex]['question']);
    });
    
    // Save the diagnosis image as profile image automatically
    _saveDiagnosisImageAsProfile();
  }

  // Perform the actual Gemini analysis
  Future<void> _performGeminiAnalysis() async {
    try {
      // Detect face and crop
      final face = await _analysisService.detectFace(widget.faceImage);
      
      if (face != null) {
        _croppedFaceImage = await _analysisService.cropFaceRegion(widget.faceImage, face);
      }
      
      // Encode image to base64
      final base64Image = _analysisService.encodeImageToBase64(_croppedFaceImage ?? widget.faceImage);
      
      // Get Gemini analysis
      final result = await _analysisService.analyzeSkinWithGemini(base64Image);
      
      setState(() {
        _geminiAnalysisResult = result;
      });
      
      print('Gemini analysis completed: $_geminiAnalysisResult');
    } catch (e) {
      print('Error during Gemini analysis: $e');
      setState(() {
        _geminiAnalysisResult = 'Error analyzing skin: $e';
      });
    }
  }
  
  void _addAiMessage(String message) {
    setState(() {
      _messages.add({
        'message': message,
        'isSender': false,
        'hasLink': false,
      });
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add({
        'message': message,
        'isSender': true,
        'hasLink': false,
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _handleOptionSelected(String option) {
    final currentQuestion = _questions[_currentQuestionIndex];
    
    if (currentQuestion['multiSelect'] == true) {
      // For multi-select questions
      List<String> currentAnswers = currentQuestion['answer'] ?? [];
      
      if (currentAnswers.contains(option)) {
        currentAnswers.remove(option);
      } else {
        currentAnswers.add(option);
      }
      
      setState(() {
        currentQuestion['answer'] = currentAnswers;
      });
    } else {
      // For single-select questions
      _addUserMessage(option);
      
      setState(() {
        currentQuestion['answer'] = option;
        _currentQuestionIndex++;
      });
      
      if (_currentQuestionIndex < _questions.length) {
        Future.delayed(const Duration(milliseconds: 800), () {
          _addAiMessage(_questions[_currentQuestionIndex]['question']);
        });
      } else {
        _completeAnalysis();
      }
    }
  }

  void _submitMultiSelectAnswers() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final List<String> answers = currentQuestion['answer'] ?? [];
    
    if (answers.isEmpty) {
      // Show a reminder to select at least one option
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('少なくとも1つのオプションを選択してください'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    _addUserMessage(answers.join(', '));
    
    setState(() {
      _currentQuestionIndex++;
    });
    
    if (_currentQuestionIndex < _questions.length) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _addAiMessage(_questions[_currentQuestionIndex]['question']);
      });
    } else {
      _completeAnalysis();
    }
  }
  
  void _completeAnalysis() {
    setState(() {
      _analysisComplete = true;
      _isAnalyzing = true;
    });
    
    _addAiMessage("情報をご提供いただきありがとうございます。お肌の分析を完了しています...");
    
    // Wait for Gemini analysis to complete if it's still running
    _waitForAnalysisAndNavigate();
  }
  
  Future<void> _waitForAnalysisAndNavigate() async {
    // Wait for Gemini analysis to complete
    while (_geminiAnalysisResult == null) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Small delay for better UX
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultsScreen(
            faceImage: _croppedFaceImage ?? widget.faceImage,
            analysisResult: _generateEnhancedAnalysisResult(),
          ),
        ),
      );
    }
  }
  
  String _generateEnhancedAnalysisResult() {
    // Combine the user's questionnaire responses with the Gemini analysis
    Map<String, dynamic> userData = {};
    
    for (var question in _questions) {
      userData[question['question']] = question['answer'];
    }
    
    // Use the actual Gemini result instead of mock data
    String baseAnalysis = _geminiAnalysisResult ?? 'お肌の画像を分析できませんでした。';
    
    // You can enhance this by incorporating the questionnaire data
    String enhancedAnalysis = '''
$baseAnalysis

あなたの追加情報に基づいて:
- 年齢層: ${userData['写真と追加情報に基づいてお肌を分析します。まず、あなたの年齢層を教えてください。'] ?? '未指定'}
- メイクの頻度: ${userData['毎日メイクをしていますか？'] ?? '未指定'}
- UV対策: ${userData['どのくらいUV対策をしていますか？'] ?? '未指定'}

この総合分析は、AIによる画像分析とあなたの個人的なスキンケアプロフィールを組み合わせて、より正確な推奨事項を提供します。
''';
    
    return enhancedAnalysis;
  }

  Future<void> _saveDiagnosisImageAsProfile() async {
    try {
      await ProfileImageService.useDiagnosisImageAsProfile(widget.faceImage);
    } catch (e) {
      print('Error saving diagnosis image as profile: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 60, left: 8, right: 8, bottom: 16),
        child: Column(
          children: [
            // AI assistant header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.close, color: Colors.black87, size: 24),
                ),
              ],
            ),
            ),
            
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  // Display the message
                  Widget messageWidget = ChatBubble(
                    message: _messages[index]['message'],
                    isSender: _messages[index]['isSender'],
                    hasLink: _messages[index]['hasLink'] ?? false,
                  );

                  // If this is the current question from the AI, also show its options
                  bool isCurrentQuestion = !_analysisComplete && 
                      index == _messages.length - 1 && 
                      !_messages[index]['isSender'] &&
                      _currentQuestionIndex < _questions.length &&
                      _messages[index]['message'] == _questions[_currentQuestionIndex]['question'];

                  if (isCurrentQuestion) {
                    final options = _questions[_currentQuestionIndex]['options'] as List;
                    final isMultiSelect = _questions[_currentQuestionIndex]['multiSelect'] == true;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        messageWidget,
                        const SizedBox(height: 12),
                        ...options.map((option) {
                          final isSelected = isMultiSelect && 
                            (_questions[_currentQuestionIndex]['answer'] ?? []).contains(option);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, left: 12.0),
                            child: GestureDetector(
                              onTap: () {
                                if (!isMultiSelect) {
                                  _handleOptionSelected(option);
                                } else {
                                  // For multi-select, just toggle selection
                                  _handleOptionSelected(option);
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    isMultiSelect 
                                      ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
                                      : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                                    size: 20,
                                    color: isSelected ? Colors.pinkAccent : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    option, 
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected ? Colors.pinkAccent : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }
                  
                  return messageWidget;
                },
              ),
            ),
            
            // Multi-select submit button or normal chat input
            if (_currentQuestionIndex < _questions.length && 
                _questions[_currentQuestionIndex]['multiSelect'] == true && 
                !_analysisComplete) 
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                    child: ElevatedButton(
                    onPressed: _submitMultiSelectAnswers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('続ける'),
                  ),
                ),
              )
            else if (_analysisComplete)
              const SizedBox() // No input when analysis is complete
            else 
              ChatInputField(
                controller: _textController,
                onSend: (text) {
                  // Not used for option-based questions
                },
              ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}