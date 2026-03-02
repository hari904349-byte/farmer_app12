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

  int totalSales = 0;
  double totalRevenue = 0;
  double deliveredRevenue = 0;
  double pendingRevenue = 0;

  double todayRevenue = 0;
  double yesterdayRevenue = 0;
  double weekRevenue = 0;
  double monthRevenue = 0;
  double yearRevenue = 0;

  String selectedFilter = "Today";

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();

      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final weekStart =
      todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final yearStart = DateTime(now.year, 1, 1);

      final orders = await supabase
          .from('orders')
          .select('total_amount, status, created_at')
          .eq('farmer_id', user.id);

      totalSales = 0;
      totalRevenue = 0;
      deliveredRevenue = 0;
      pendingRevenue = 0;

      todayRevenue = 0;
      yesterdayRevenue = 0;
      weekRevenue = 0;
      monthRevenue = 0;
      yearRevenue = 0;

      for (final o in orders) {
        final amount = (o['total_amount'] as num).toDouble();
        final status = (o['status'] as String).toLowerCase();
        final createdAt = DateTime.parse(o['created_at']);

        totalSales++;

        if (status == 'delivered') {
          deliveredRevenue += amount;
        } else {
          pendingRevenue += amount;
        }

// Business revenue includes both
        totalRevenue += amount;

        if (status != 'delivered') continue;

        if (!createdAt.isBefore(todayStart) &&
            createdAt.isBefore(tomorrowStart)) {
          todayRevenue += amount;
        }

        if (!createdAt.isBefore(yesterdayStart) &&
            createdAt.isBefore(todayStart)) {
          yesterdayRevenue += amount;
        }

        if (!createdAt.isBefore(weekStart)) {
          weekRevenue += amount;
        }

        if (!createdAt.isBefore(monthStart)) {
          monthRevenue += amount;
        }

        if (!createdAt.isBefore(yearStart)) {
          yearRevenue += amount;
        }
      }
    } catch (e) {
      debugPrint("Revenue load error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  double get selectedRevenue {
    switch (selectedFilter) {
      case "Today":
        return todayRevenue;
      case "Yesterday":
        return yesterdayRevenue;
      case "This Week":
        return weekRevenue;
      case "This Month":
        return monthRevenue;
      case "This Year":
        return yearRevenue;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Sales & Revenue"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(
          child:
          CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _card("Total Sales", totalSales.toString()),
            _card("Total Revenue",
                "₹${totalRevenue.toStringAsFixed(2)}"),
            _card("Delivered Revenue",
                "₹${deliveredRevenue.toStringAsFixed(2)}"),
            _card("Pending Revenue",
                "₹${pendingRevenue.toStringAsFixed(2)}"),

            const SizedBox(height: 25),

            DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(
                    value: "Today", child: Text("Today")),
                DropdownMenuItem(
                    value: "Yesterday",
                    child: Text("Yesterday")),
                DropdownMenuItem(
                    value: "This Week",
                    child: Text("This Week")),
                DropdownMenuItem(
                    value: "This Month",
                    child: Text("This Month")),
                DropdownMenuItem(
                    value: "This Year",
                    child: Text("This Year")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 280,
              child: BarChart(_buildChart()),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _buildChart() {
    final maxY = selectedRevenue == 0
        ? 100.0
        : selectedRevenue + (selectedRevenue * 0.3);

    return BarChartData(
      alignment: BarChartAlignment.center,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 5,
            getTitlesWidget: (value, meta) {
              return Text(
                "₹${value.toInt()}",
                style: const TextStyle(
                    fontSize: 10, color: Colors.grey),
              );
            },
          ),
        ),
        rightTitles:
        AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
        AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  selectedFilter,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: selectedRevenue,
              width: 45,
              borderRadius:
              BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [
                  Colors.green,
                  Colors.lightGreen
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6)
        ],
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }
}