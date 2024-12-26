import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchAllSchools() async {
  const String apiUrl = 'https://open.neis.go.kr/hub/schoolInfo';
  String apiKey = dotenv.get("NEIS_API_KEY");
  const int pageSize = 1000;

  List<Map<String, dynamic>> allSchools = [];
  int currentPage = 1;
  bool hasMoreData = true;

  while (hasMoreData) {
    final response = await http.get(
      Uri.parse('$apiUrl?KEY=$apiKey&Type=json&pSize=$pageSize&pIndex=$currentPage'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['schoolInfo'] != null && data['schoolInfo'].isNotEmpty) {
        final schools = data['schoolInfo'][1]['row'] as List;
        allSchools.addAll(schools.map((e) => e as Map<String, dynamic>));

        if (schools.length < pageSize) {
          hasMoreData = false;
        } else {
          currentPage++;
        }
      } else {
        hasMoreData = false;
      }
    } else {
      print('Error: ${response.statusCode}');
      hasMoreData = false;
    }
  }

  return allSchools;
}
