import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceService {
  static final supabase = Supabase.instance.client;

  static Future<void> generateInvoice({
    required Map<String, dynamic> order,
  }) async {
    final pdf = pw.Document();

    // ✅ LOAD UNICODE FONT (FIX ₹ SYMBOL)
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    // ================= FETCH DATA =================
    final farmer = await _getProfile(order['farmer_id']);
    final deliveryPartner =
    await _getProfile(order['delivery_partner_id']);

    final items = (order['order_items'] ?? []) as List;
    final date =
    DateFormat('dd-MM-yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        build: (context) => [
          _header(order, date),
          pw.SizedBox(height: 16),
          _shippingDetails(order),
          pw.SizedBox(height: 16),
          _partyDetails(farmer, deliveryPartner),
          pw.SizedBox(height: 16),
          _itemsTable(items),
          pw.Divider(),
          _total(order),
          pw.SizedBox(height: 24),
          _footer(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // ================= FETCH PROFILE =================
  static Future<Map<String, dynamic>?> _getProfile(String? id) async {
    if (id == null) return null;
    final data = await supabase
        .from('profiles')
        .select('name, mobile')
        .eq('id', id)
        .maybeSingle();
    return data;
  }

  // ================= HEADER =================
  static pw.Widget _header(Map<String, dynamic> order, String date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Farm Fresh Connect",
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold)),
            pw.Text("TAX INVOICE"),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text("Order ID: ${order['id']}"),
            pw.Text("Invoice Date: $date"),
          ],
        ),
      ],
    );
  }

  // ================= SHIPPING =================
  static pw.Widget _shippingDetails(Map<String, dynamic> order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Shipping Details",
              style:
              pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text("Address: ${order['delivery_address']}"),
          pw.Text("Payment: ${order['payment_method'] ?? 'COD'}"),
          pw.Text("Order Status: ${order['status']}"),
        ],
      ),
    );
  }

  // ================= FARMER & DELIVERY =================
  static pw.Widget _partyDetails(
      Map<String, dynamic>? farmer,
      Map<String, dynamic>? delivery,
      ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Farmer Details",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text("Name: ${farmer?['name'] ?? '—'}"),
                pw.Text("Mobile: ${farmer?['mobile'] ?? '—'}"),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Delivery Partner",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(
                    "Name: ${delivery?['name'] ?? 'Not Assigned'}"),
                pw.Text(
                    "Mobile: ${delivery?['mobile'] ?? '—'}"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= ITEMS =================
  static pw.Widget _itemsTable(List items) {
    return pw.Table.fromTextArray(
      headers: ["Product", "Qty", "Price", "Total"],
      headerStyle:
      pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration:
      const pw.BoxDecoration(color: PdfColors.grey300),
      border: pw.TableBorder.all(color: PdfColors.grey),
      data: items.map((item) {
        final qty = item['quantity'];
        final price = item['price'];
        return [
          item['products']['name'],
          qty.toString(),
          "₹ $price",
          "₹ ${qty * price}",
        ];
      }).toList(),
    );
  }

  // ================= TOTAL =================
  static pw.Widget _total(Map<String, dynamic> order) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        "Grand Total: ₹ ${order['total_amount']}",
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ================= FOOTER =================
  static pw.Widget _footer() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(
          "This is a system generated invoice.",
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          "Thank you for shopping with Farm Fresh Connect",
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
