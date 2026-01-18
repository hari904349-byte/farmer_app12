import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesRevenue extends StatefulWidget {
  const SalesRevenue({super.key});

  @override
  State<SalesRevenue> createState() => _SalesRevenueState();
}

class _SalesRevenueState extends State<SalesRevenue> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  // Overall
  int totalSales = 0;
  double totalRevenue = 0;

  // Status-based
  double deliveredRevenue = 0;
  double pendingRevenue = 0;

  // Monthly
  double monthlyRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadRevenueData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);

      final orders = await supabase
          .from('orders')
          .select('total_amount, status, created_at')
          .eq('farmer_id', user.id);

      totalSales = orders.length;
      totalRevenue = 0;
      deliveredRevenue = 0;
      pendingRevenue = 0;
      monthlyRevenue = 0;

      for (final o in orders) {
        final amount = (o['total_amount'] as num).toDouble();
        final status = o['status'] as String;
        final createdAt = DateTime.parse(o['created_at']);

        totalRevenue += amount;

        if (status == 'delivered') {
          deliveredRevenue += amount;
        } else {
          pendingRevenue += amount;
        }

        if (createdAt.isAfter(monthStart) &&
            createdAt.isBefore(monthEnd) &&
            status == 'delivered') {
          monthlyRevenue += amount;
        }
      }
    } catch (e) {
      debugPrint("Revenue load error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales & Revenue"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.green),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionTitle("Overall"),
            _infoCard("Total Sales", totalSales.toString()),
            _infoCard(
                "Total Revenue", "₹${totalRevenue.toStringAsFixed(2)}"),

            const SizedBox(height: 20),

            _sectionTitle("Order Status"),
            _infoCard("Delivered Revenue",
                "₹${deliveredRevenue.toStringAsFixed(2)}"),
            _infoCard("Pending Revenue",
                "₹${pendingRevenue.toStringAsFixed(2)}"),

            const SizedBox(height: 30),

            _sectionTitle("Revenue Chart"),
            SizedBox(
              height: 220,
              child: BarChart(_barChartData()),
            ),
          ],
        ),
      ),
    );
  }

  // ================= BAR CHART =================
  BarChartData _barChartData() {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: [
        deliveredRevenue,
        pendingRevenue,
        monthlyRevenue,
      ].reduce((a, b) => a > b ? a : b) +
          1000,
      barGroups: [
        _barGroup(0, deliveredRevenue, Colors.green),
        _barGroup(1, pendingRevenue, Colors.orange),
        _barGroup(2, monthlyRevenue, Colors.blue),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              switch (value.toInt()) {
                case 0:
                  return const Text("Delivered");
                case 1:
                  return const Text("Pending");
                case 2:
                  return const Text("This Month");
                default:
                  return const Text("");
              }
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
    );
  }

  BarChartGroupData _barGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 22,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  // ================= UI HELPERS =================
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
