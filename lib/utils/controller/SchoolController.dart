import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SchoolController extends GetxController {
  final box = GetStorage();
  var allSchools = [].obs;
  var allSchoolNames = [].obs;
  var selectedMealType = ''.obs;
  var selectedSchool = ''.obs;
  var isLoading = false.obs;
  var mealData = {}.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() {
    selectedSchool.value = box.read('selectedSchool') ?? '학교 선택되지 않음';
    allSchools.value = box.read('allSchools') ?? [];
    allSchoolNames.value = box.read('allSchoolNames') ?? [];
    selectedMealType.value = box.read('selectedMealType') ?? '조식';
    mealData.value = box.read('mealData') ?? {};
  }

  void setMealData(Map<String, dynamic> data) {
    mealData.value = data;
    box.write('mealData', data);
  }

  void selectMealType(String mealType) {
    selectedMealType.value = mealType;
    box.write('selectedMealType', mealType);
  }

  void setAllSchools(List<Map<String, dynamic>> schools) {
    allSchools.value = schools;
    box.write('allSchools', schools);
  }

  void setAllSchoolNames(List<String> schools) {
    allSchoolNames.value = schools;
    box.write('allSchoolNames', schools);
  }

  void selectSchool(String schoolName) {
    selectedSchool.value = schoolName;
    box.write('selectedSchool', schoolName);
  }

  void setLoading(bool value) {
    isLoading.value = value;
  }

  @override
  void onClose() {
    super.onClose();
    box.write('selectedSchool', selectedSchool.value);
    box.write('allSchools', allSchools.toList());
    box.write('allSchoolNames', allSchoolNames.toList());
    box.write('selectedMealType', selectedMealType.value);
    box.write('mealData', mealData.toJson());
  }
}
