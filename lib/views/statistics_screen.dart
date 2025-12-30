import 'package:flutter/material.dart';
import '../models/event.dart';

class StatisticsScreen extends StatelessWidget {
  final List<Event> allEvents;
  const StatisticsScreen({super.key, required this.allEvents});

  @override
  Widget build(BuildContext context) {
    int total = allEvents.length;
    int completed = allEvents.where((e) => e.status == "Completed").toList().length;
    double percent = total == 0 ? 0 : (completed / total);

    return Scaffold(
      appBar: AppBar(title: const Text("Thống kê năng suất")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 15,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  "${(percent * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildStatInfo("Tổng số công việc", total, Colors.black),
            _buildStatInfo("Đã hoàn thành", completed, Colors.green),
            _buildStatInfo("Đang chờ", total - completed, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatInfo(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        "$label: $count",
        style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}