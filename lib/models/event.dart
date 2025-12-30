import 'dart:convert';

class Event {
  final int? id;
  final String title;
  final String? description;
  final DateTime eventDate; // Ánh xạ từ StartTime của C#
  final DateTime? endTime;
  final String status;
  final String? userId;
  final String? userName;
  // Bổ sung 2 thuộc tính này để nhận dữ liệu từ API
  final String? categoryName; 
  final String? colorCode; 

  Event({
    this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.endTime,
    required this.status,
    this.userId,
    this.userName,
    this.categoryName, // Thêm vào constructor
    this.colorCode,    // Thêm vào constructor
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final rawEventDate = json['eventDate'] ?? json['startTime'];
    if (rawEventDate == null) {
      throw const FormatException('Missing event date value.');
    }

    return Event(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      eventDate: DateTime.parse(rawEventDate.toString()),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'].toString())
          : null,
      status: json['status'] ?? 'Active',
      userId: json['userId']?.toString(),
      userName: json['userName'],
      // Lấy dữ liệu category từ JSON trả về của Backend
      categoryName: json['categoryName'], 
      colorCode: json['colorCode'],       
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': eventDate.toIso8601String(), // Gửi lên Backend dùng key startTime
      'endTime': endTime?.toIso8601String(),
      'status': status,
      'userId': userId,
      'userName': userName,
      'categoryId': jsonEncode(id), // Khi gửi lên cần categoryId, bạn có thể bổ sung nếu cần
    };
  }
}