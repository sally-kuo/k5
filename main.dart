import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WebView + 手寫板',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const WebAndDrawingScreen(),
    );
  }
}

class WebAndDrawingScreen extends StatefulWidget {
  const WebAndDrawingScreen({super.key});

  @override
  State<WebAndDrawingScreen> createState() => _WebAndDrawingScreenState();
}

class _WebAndDrawingScreenState extends State<WebAndDrawingScreen> {
  late final WebViewController _webController;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // 啟用 JavaScript
      ..loadRequest(Uri.parse('https://stroke-order.learningweb.moe.edu.tw/dictFrame.jsp?ID=20320')); // 預設載入網址
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView + 手寫板')),
      body: Column(
        children: [
          // **完整呈現 WebView，不裁切內容**
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55, // 設定固定高度，確保完整顯示
            child: WebViewWidget(controller: _webController),
          ),

          // 分隔線
          const Divider(height: 2, color: Colors.black),

          // 手寫板佔據剩餘畫面
          Expanded(
            child: const DrawingBoard(),
          ),
        ],
      ),
    );
  }
}

class DrawingBoard extends StatefulWidget {
  const DrawingBoard({super.key});

  @override
  _DrawingBoardState createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  List<List<Offset?>> _history = [];
  List<Offset?> _points = [];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _points = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _history.add(List.from(_points));
      _points.add(null);
    });
  }

  void _clearCanvas() {
    setState(() {
      _history.clear();
      _points.clear();
    });
  }

  void _undo() {
    if (_history.isNotEmpty) {
      setState(() {
        _history.removeLast();
        _points = _history.isNotEmpty ? List.from(_history.last) : [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Container(
              color: Colors.white,
              child: CustomPaint(
                painter: DrawingPainter([..._history, _points]),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
            IconButton(icon: const Icon(Icons.delete), onPressed: _clearCanvas),
          ],
        ),
      ],
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<Offset?>> points;
  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    // 畫出手寫的筆順，這部分需要置於淺灰色字之前
    for (var path in points) {
      for (int i = 0; i < path.length - 1; i++) {
        if (path[i] != null && path[i + 1] != null) {
          canvas.drawLine(path[i]!, path[i + 1]!, paint);
        }
      }
    }

    // 畫上「你」字，這部分需要放在筆順之後，並保留輪廓不填色
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '你',
        style: TextStyle(
          fontSize: 150,  // 增大字體
          color: Color.fromRGBO(169, 169, 169, 0.5), // 使用50%透明度的灰色
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();


    // 在畫布上畫出「你」字的輪廓，位置設為(0.3, 0.1)
    textPainter.paint(canvas, Offset(size.width * 0.3, size.height * 0.01));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}