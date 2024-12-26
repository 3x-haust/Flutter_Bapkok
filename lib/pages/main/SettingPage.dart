import 'dart:math';

import 'package:bapkok/utils/api/Schools.dart';
import 'package:bapkok/utils/controller/AlarmController.dart';
import 'package:bapkok/utils/controller/SchoolController.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_getx_widget.dart';
import 'package:shimmer/shimmer.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  SettingPageState createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  final AlarmController alarmController = Get.find();
  final SchoolController schoolController = Get.find();
  final _searchController = TextEditingController();
  TextEditingController? _autocompleteController;

  List<String> get _schoolNames =>
      List<String>.from(schoolController.allSchoolNames);
  DateTime selectedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeSchools();
  }

  Future<void> _initializeSchools() async {
    if (schoolController.allSchools.isEmpty) {
      await _fetchAndSetSchools();
    }
  }

  Future<void> _fetchAndSetSchools() async {
    _setLoading(true);

    try {
      final schools = await fetchAllSchools();
      final schoolNames =
          schools.map((school) => school["SCHUL_NM"] as String).toList();

      schoolController.setAllSchools(schools);
      schoolController.setAllSchoolNames(schoolNames);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        alarmController.setLoading(value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEEF1),
      body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: 32.22,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        SizedBox(
                          width: min(constraints.maxWidth, 600),
                          child: GetX<AlarmController>(
                            builder: (controller) => controller.isLoading.value
                                ? _buildAlarmContainerSkeleton()
                                : _buildAlarmContainer(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          )),
    );
  }

  Widget _buildAlarmCard(String id) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('알림 삭제'),
              content: const Text('이 알림을 삭제하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    alarmController.deleteAlarm(id);
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text('삭제'),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD9DBFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    alarmController.alarms[id]!['mealType'],
                    style: const TextStyle(
                      color: Color(0xFF1E1E1E),
                      fontSize: 20,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GetX<AlarmController>(
                    builder: (controller) => Switch(
                      inactiveTrackColor: const Color(0xFF8A96A6),
                      trackOutlineColor:
                          WidgetStateProperty.all(Colors.transparent),
                      inactiveThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF636CFF),
                      thumbIcon: WidgetStateProperty.all(const Icon(
                        Icons.circle,
                        color: Colors.white,
                      )),
                      thumbColor: WidgetStateProperty.all(Colors.white),
                      value: alarmController.alarms[id]!['status'],
                      onChanged: (value) {
                        setState(() {
                          alarmController.toggleAlarm(id);
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    alarmController.alarms[id]!['schoolName'],
                    style: const TextStyle(
                      color: Color(0xFF8F98A8),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${alarmController.alarms[id]!['time']}',
                    style: const TextStyle(
                      color: Color(0xFF555E70),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmContainer() {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '알림 설정',
              style: TextStyle(
                color: const Color(0xFF020202),
                fontSize: MediaQuery.of(context).size.width * 0.06,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
            _buildDivider(),
            const SizedBox(height: 15),
            _buildAlarmSubTitle(),
            const SizedBox(height: 30),
            alarmController.alarms.isEmpty
                ? const Text(
                    '알림이 없습니다.',
                    style: TextStyle(
                      color: Color(0xFF1E1E1E),
                      fontSize: 20,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Column(
                    children: alarmController.alarms.entries
                        .map((entry) => Column(
                              children: [
                                _buildAlarmCard(
                                  entry.key,
                                ),
                                const SizedBox(height: 15),
                              ],
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmSubTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '알림 설정',
          style: TextStyle(
            color: Color(0xFF555E70),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: () {
            _showAlarmBottomSheet();
          },
          icon: const Icon(Icons.add),
          color: const Color(0xFF636CFF),
        ),
      ],
    );
  }

  void _showAlarmBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F6F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        maxWidth: min(MediaQuery.of(context).size.width, 600),
      ),
      builder: (BuildContext context) => _buildAlarmBottomSheet(),
    );
  }

  Widget _buildAlarmBottomSheet() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    color: Color(0xFFD54040),
                    fontSize: 20,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Text(
                '알람 추가',
                style: TextStyle(
                  color: Color(0xFF101012),
                  fontSize: 24,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => {
                  if (_autocompleteController!.text.isNotEmpty &&
                      schoolController.allSchoolNames
                          .contains(_autocompleteController!.text))
                    {
                      Get.back(),
                      alarmController.addAlarm({
                        'time': '${selectedTime.hour}:${selectedTime.minute}',
                        'status': true,
                        'mealType': dropdownValue,
                        'schoolName': _autocompleteController!.text,
                      })
                    }
                },
                child: const Text(
                  '저장',
                  style: TextStyle(
                    color: Color(0xFF636CFF),
                    fontSize: 20,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          _buildDivider(),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAutoCompleteField(),
              _buildMealTypeDropdown(),
            ],
          ),
          const SizedBox(height: 15),
          _buildDivider(),
          const SizedBox(height: 15),
          _buildAlarmTimePicker(),
          const SizedBox(height: 15),
          _buildDivider(),
        ],
      ),
    );
  }

  String? dropdownValue = '중식';

  Widget _buildMealTypeDropdown() {
    dropdownValue = "중식";
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return DropdownButton<String>(
          value: dropdownValue,
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: SvgPicture.asset('assets/svgs/arrow_down.svg'),
          ),
          elevation: 16,
          dropdownColor: Colors.white,
          style: TextStyle(
            color: const Color(0xFF8F98A8),
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
          underline: Container(height: 0),
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue;
            });
          },
          items:
              ['조식', '중식', '석식'].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAlarmTimePicker() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.3,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: DateTime.now(),
        onDateTimeChanged: (DateTime time) {
          selectedTime = time;
        },
      ),
    );
  }

  Widget _buildAutoCompleteField() {
    return Container(
      width: MediaQuery.of(context).size.width - 130,
      height: 50,
      decoration: _searchFieldDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildAutocomplete(),
      ),
    );
  }

  Autocomplete<String> _buildAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: _optionsBuilder,
      onSelected: (String selection) {
        _searchController.text = selection;
      },
      fieldViewBuilder: _buildSearchTextField,
      optionsViewBuilder: _buildOptionsView,
    );
  }

  Widget _buildOptionsView(
    BuildContext context,
    AutocompleteOnSelected<String> onSelected,
    Iterable<String> options,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: MediaQuery.of(context).size.width - 160,
            decoration: _optionsContainerDecoration,
            child: _buildOptionsList(options, onSelected),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsList(
    Iterable<String> options,
    AutocompleteOnSelected<String> onSelected,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: options.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final option = options.elementAt(index);
        return _buildOptionItem(option, onSelected);
      },
    );
  }

  Widget _buildOptionItem(
      String option, AutocompleteOnSelected<String> onSelected) {
    return InkWell(
      onTap: () => onSelected(option),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ),
        child: Text(
          option,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  BoxDecoration get _searchFieldDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C555E70),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          )
        ],
      );

  BoxDecoration get _optionsContainerDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Iterable<String> _optionsBuilder(TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();

    return _schoolNames.where((schoolName) {
      return schoolName
          .toLowerCase()
          .contains(textEditingValue.text.toLowerCase());
    });
  }

  Widget _buildSearchTextField(
    BuildContext context,
    TextEditingController textEditingController,
    FocusNode focusNode,
    VoidCallback onFieldSubmitted,
  ) {
    _searchController.text = textEditingController.text;
    _autocompleteController = textEditingController;

    return TextField(
      controller: textEditingController,
      focusNode: focusNode,
      enabled: !alarmController.isLoading.value,
      cursorColor: Colors.black,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: alarmController.isLoading.value ? "데이터 로딩중..." : "학교를 입력하세요.",
        hintStyle: const TextStyle(
          color: Color(0xFFCCCCCC),
          fontSize: 16,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
        ),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildAlarmContainerSkeleton() {
    return ShimmerContainer(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: MediaQuery.of(context).size.width * 0.3,
            height: 24,
          ),
          const SizedBox(height: 15),
          _buildDivider(),
          const SizedBox(height: 15),
          ShimmerBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 20,
          ),
          const SizedBox(height: 30),
          ShimmerBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.1,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: const Color.fromRGBO(108, 121, 139, 0.50),
    );
  }
}

class ShimmerContainer extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const ShimmerContainer({
    required this.width,
    required this.height,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerBox({
    required this.width,
    required this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.white,
    );
  }
}
