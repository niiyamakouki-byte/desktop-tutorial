import 'dart:html' as html;

class PrintService {
  const PrintService();

  Future<bool> printCurrentPage() async {
    html.window.print();
    return true;
  }
}
