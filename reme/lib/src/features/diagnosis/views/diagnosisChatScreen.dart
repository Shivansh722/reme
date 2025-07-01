import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reme/src/features/chat/views/chatView.dart';
import 'package:reme/src/features/diagnosis/views/analysisResultsScreen.dart';

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
      'question': 'I\'ll analyze your skin based on the photo and some additional information. First, what is your age range?',
      'options': ['20s', '30s', '40s', '50s', '60s or above'],
      'answer': null,
    },
    {
      'question': 'Do you wear makeup on a daily basis?',
      'options': ['Every day', 'Several times a week', 'Rarely', 'Never'],
      'answer': null,
    },
    {
      'question': 'How much do you protect your skin from UV rays?',
      'options': ['Daily with SPF 30+', 'Only when going out', 'Rarely', 'Never'],
      'answer': null,
    },
    {
      'question': 'Please select your skin concerns (select all that apply):',
      'options': ['Pores', 'Dark spots', 'Redness', 'Dryness', 'Sagging', 'Acne', 'Fine lines', 'Oiliness'],
      'answer': null,
      'multiSelect': true,
    },
    {
      'question': 'Which skincare products are you currently using? (select all that apply)',
      'options': ['Cleanser', 'Toner', 'Serum', 'Moisturizer', 'Sunscreen', 'Exfoliator', 'Face mask', 'Eye cream', 'None'],
      'answer': null,
      'multiSelect': true,
    },
    {
      'question': 'What is your ideal skin condition? (select all that apply)',
      'options': ['Translucent skin', 'Pore-free', 'Moisturized', 'Even tone', 'Firm and elastic', 'Blemish-free'],
      'answer': null,
      'multiSelect': true,
    },
    {
      'question': 'Does your skin condition change with the seasons?',
      'options': ['Yes, significantly', 'Yes, somewhat', 'No, stays mostly the same'],
      'answer': null,
    },
  ];
  
  int _currentQuestionIndex = 0;
  bool _analysisComplete = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Add welcome message
    _addAiMessage('Hi there! I\'m analyzing the image of your skin...');
    
    // Add first question after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      _addAiMessage(_questions[_currentQuestionIndex]['question']);
    });
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
          content: Text('Please select at least one option'),
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
    });
    
    _addAiMessage("Thank you for providing this information. I'm analyzing your skin now based on your photo and responses...");
    
    // Simulate analysis delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultsScreen(
            faceImage: widget.faceImage,
            analysisResult: _generateAnalysisResult(),
          ),
        ),
      );
    });
  }
  
  String _generateAnalysisResult() {
    // In a real app, this would be where you'd process the data 
    // and potentially send it to a backend for AI analysis
    Map<String, dynamic> userData = {};
    
    for (var question in _questions) {
      userData[question['question']] = question['answer'];
    }
    
    return """Based on your skin image and responses, we've identified:

1. Your skin is showing signs of mild dehydration
2. There are early indications of sun damage around the cheeks
3. Pore size is moderate, with some congestion in the T-zone
4. Your skin would benefit from increased hydration and UV protection

Recommended routine:
- Gentle cleanser morning and night
- Hydrating toner with hyaluronic acid
- Vitamin C serum in the morning
- Daily sunscreen (SPF 50)
- Retinol product 2-3 times weekly (evening only)
- Regular exfoliation (1-2 times per week)

We recommend consulting with a dermatologist for personalized advice.
""";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Analysis'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 12, left: 8, right: 8, bottom: 16),
        child: Column(
          children: [
            // AI assistant header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.spa, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Skin AI Assistant',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length + 
                  (_currentQuestionIndex < _questions.length && !_analysisComplete 
                    ? (_questions[_currentQuestionIndex]['options'] as List).length 
                    : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return ChatBubble(
                      message: _messages[index]['message'],
                      isSender: _messages[index]['isSender'],
                      hasLink: _messages[index]['hasLink'] ?? false,
                    );
                  } else if (!_analysisComplete) {
                    // Display options for current question
                    final optionIndex = index - _messages.length;
                    final options = _questions[_currentQuestionIndex]['options'];
                    final option = options[optionIndex];
                    final isMultiSelect = _questions[_currentQuestionIndex]['multiSelect'] == true;
                    final isSelected = isMultiSelect && 
                      (_questions[_currentQuestionIndex]['answer'] ?? []).contains(option);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
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
                            const SizedBox(width: 12),
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
                  }
                  return null;
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
                    child: const Text('Continue'),
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