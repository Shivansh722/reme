import 'package:flutter/material.dart';
import 'package:reme/src/features/home/widgets/recommendedCard.dart';

class HomeviewMain extends StatelessWidget {
  const HomeviewMain({super.key});

  @override
  Widget build(BuildContext context) {
    return DiagnosisScreen();
  }
}

class DiagnosisScreen extends StatelessWidget {
  Widget checklistItem(bool checked, String text) => CheckboxListTile(
        value: checked,
        onChanged: (_) {},
        title: Text(text,
            style: TextStyle(
              color: Colors.black87,
            )),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero, // Remove default padding
            dense: true, // Makes the tile more compact
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add padding at the top to compensate for status bar
            SizedBox(height: MediaQuery.of(context).padding.top),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('最新の診断結果',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),

                  

                    Text('もっと見る',
                        style: TextStyle(color: Colors.blue)),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('肌スコア'),
                          RichText(
                            text: TextSpan(
                            children: [
                              TextSpan(
                              text: '86',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              ),
                              TextSpan(
                              text: '/100',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              ),
                            ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Container(
                      height: 60,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('肌年齢'),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '42',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: '歳',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF9F9F9),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Point"),
                      SizedBox(height: 8),
                      Text(
                        '入浴時は、お湯の温度を40度以下に設定し、10〜15分程度を目安にしましょう。長時間の入浴や熱すぎるお湯は、皮膚への負担となる可能性があります。',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('前回の診断日\n2025/05/12'),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    Text('次回の診断目安\n2025/08/16'),
                  ],
                ),
                SizedBox(height: 24),
                Center(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(300, 48),
                        
                        foregroundColor: Colors.pink,
                        side: BorderSide(color: Colors.pink)),
                    child: Text('再診断する'),
                  ),
                )
              ],
            ),

            SizedBox(height: 24),


              Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink[50]?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text('理想の肌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),

                  SizedBox(height: 8),

                  Text('乾燥肌を改善したい', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                  SizedBox(height: 2),

                  Text(
                    '洗顔・入浴後すぐに保湿（3分以内が理想）\nセラミド、ヒアルロン酸、グリセリン配合の保湿剤を選ぶ\nオイルやバームで蓋をして水分を逃がさない',
                  ),

                  SizedBox(height: 2),
                  Divider(height: 24, color: Colors.grey[300]),

                  SizedBox(height: 2),

                  Text('やることリスト', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),

                  checklistItem(false, '目標に対するタスクが入ります。目標に対するタスクがあります。'),
                  checklistItem(true, '目標に対するタスクが入ります。目標に対するタスクがあります。'),
                  checklistItem(false, '目標に対するタスクが入ります。目標に対するタスクがあります。'),
                ],
              ),
            ),

            SizedBox(height: 24),

            Text('おすすめ商品',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 16),
             Row(
               children: [
                 ProductCard(
                             title: '母袋有機農場シリーズ...',
                             description: '栄養豊富なヘチマ水がすっと浸透、繊細な肌を包み込み',
                             price: '¥1,234(税込)',
                           ),
                SizedBox(width: 8),

                           ProductCard(
                             title: '母袋有機農場シリーズ...',
                             description: '栄養豊富なヘチマ水がすっと浸透、繊細な肌を包み込み',
                             price: '¥1,234(税込)',
                           ),
               ],
             ),

        ],
      ),
    ),
    );
  }
}