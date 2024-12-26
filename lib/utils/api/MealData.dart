import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:bapkok/utils/controller/SchoolController.dart';

Future<Map<String, dynamic>> fetchSchoolMeal(String schoolName, String date) async {
  const String apiUrl = 'https://open.neis.go.kr/hub/mealServiceDietInfo';
  String apiKey = dotenv.get("NEIS_API_KEY");
  final SchoolController schoolController = Get.find<SchoolController>();

  final school = schoolController.allSchools.firstWhere(
    (school) => school['SCHUL_NM'] == schoolName,
    orElse: () => null,
  );

  if (school == null) {
    print('Error: School not found');
    return {};
  }

  final response = await http.get(
    Uri.parse(
      '$apiUrl?KEY=$apiKey&Type=json&ATPT_OFCDC_SC_CODE=${school['ATPT_OFCDC_SC_CODE']}&SD_SCHUL_CODE=${school['SD_SCHUL_CODE']}&MLSV_YMD=$date',
    ),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    if (data['mealServiceDietInfo'] == null) {
      return {"dishName": '급식 정보가 없습니다.'};
    }
    final mealData = data['mealServiceDietInfo'][1]['row'];
    List<String> dishNames = mealData.map<String>((meal) => meal['DDISH_NM'] as String).toList();
    List<String> orplcs = mealData.map<String>((meal) => meal['ORPLC_INFO'] as String).toList();
    List<String> cal = mealData.map<String>((meal) => meal['CAL_INFO'] as String).toList();
    List<String> nutrition = mealData.map<String>((meal) => meal['NTR_INFO'] as String).toList();

    dishNames = dishNames.map((dish) {
      return dish.replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\([^)]*\)'), '')
          .replaceAll(RegExp(r'\*|\.'), '');
    }).toList();

    final mealTypes = ["조식", "중식", "석식"];
    Map<String, dynamic> meals = {};

    if (dishNames.length == 1) {
      meals["중식"] = {
      "dishName": dishNames[0].split(" "),
      "orplc": orplcs[0].split('<br/>'),
      "cal": cal[0],
      "nutrition": nutrition[0].split('<br/>'),
      };
    } else {
      for (int i = 0; i < dishNames.length; i++) {
      meals[mealTypes[i]] = {
        "dishName": i < dishNames.length ? dishNames[i].split(" ") : [],
        "orplc": orplcs[i].split('<br/>'),
        "cal": cal[i],
        "nutrition": nutrition[i].split('<br/>'),
      };
      }
    }

    return meals;
  } else {
    print('Error: ${response.statusCode}');
    return {};
  }
}
