import 'dart:math';

import 'package:bapkok/utils/api/MealData.dart';
import 'package:bapkok/utils/controller/SchoolController.dart';
import 'package:bapkok/widgets/MyAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class MealPage extends StatefulWidget {
  const MealPage({super.key});

  @override
  MealPageState createState() => MealPageState();
}

class MealPageState extends State<MealPage> {
  final SchoolController schoolController = Get.find();
  Map<String, dynamic> mealData = {};
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchSchoolMeal();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupSchoolListener();
  }

  void _setupSchoolListener() {
    schoolController.selectedSchool.listen((_) async {
      final data = await fetchSchoolMeal(schoolController.selectedSchool.value,
          _getFormattedDate(_selectedDay));
      if (mounted) {
        setState(() => mealData = data);
      }
    });
  }

  String _getFormattedDate(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchSchoolMeal() async {
    if (schoolController.selectedSchool.value.isEmpty) return;

    schoolController.setLoading(true);

    if (schoolController.mealData.isNotEmpty) {
      setState(() =>
          mealData = Map<String, dynamic>.from(schoolController.mealData));
      schoolController.setLoading(false);
      return;
    }

    final data = await fetchSchoolMeal(
        schoolController.selectedSchool.value, _getFormattedDate(_selectedDay));
    setState(() => mealData = data);
    schoolController.setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: MyAppBar(),
      ),
      backgroundColor: const Color(0xFFEDEEF1),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: MediaQuery.of(context).size.width * 0.1,
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  SizedBox(
                    width: min(constraints.maxWidth, 600),
                    child: GetX<SchoolController>(
                      builder: (controller) => controller.isLoading.value
                        ? _buildSchoolInfoSkeleton()
                        : _buildSchoolInfo(controller.selectedSchool.value),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: min(constraints.maxWidth, 600),
                    child: GetX<SchoolController>(
                      builder: (controller) => controller.isLoading.value
                        ? _buildMealInfoSkeleton()
                        : _buildMealInfo(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypeDropdown() {
    return GetX<SchoolController>(
      builder: (controller) => DropdownButton<String>(
        value: schoolController.selectedMealType.value,
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
        onChanged: (String? newValue) =>
            schoolController.selectMealType(newValue!),
        items:
            ['조식', '중식', '석식'].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      )
    );
  }

  Widget _buildMealContent() {
    return GetX<SchoolController>(
      builder: (controller) {
        final mealTypeData = mealData[schoolController.selectedMealType.value];
        if (mealTypeData == null || mealTypeData["dishName"] == null) {
          return const _NoMealDataWidget();
        }
        return Column(
          children: [
            ...mealTypeData["dishName"]
                .map<Widget>((dish) => _buildDishItem(dish)),
            if (mealTypeData["cal"] != null)
              _buildCalorieInfo(mealTypeData["cal"]),
          ],
        );
      }
    );
  }

  Widget _buildDishItem(String dish) {
    return Center(
      child: Text(
        dish.trim(),
        style: TextStyle(
          color: const Color(0xFF1E1E1E),
          fontSize: MediaQuery.of(context).size.width * 0.05,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCalorieInfo(String calories) {
    return Center(
      child: Text(
        "칼로리: $calories",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFF8F98A8),
          fontSize: MediaQuery.of(context).size.width * 0.04,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMealInfo() {
    return Container(
      constraints: const BoxConstraints(minHeight: 131),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMealHeader(),
            _buildMealDate(),
            const SizedBox(height: 15),
            _buildDivider(),
            const SizedBox(height: 15),
            _buildMealContent(),
            const SizedBox(height: 15),
            _buildDivider(),
            const SizedBox(height: 15),
            _buildNutritionInfoButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMealDate() {
    return GestureDetector(
      onTap: () => _showDatePicker(),
      child: Text(
        DateFormat('MM월 dd일 (E) 급식', 'ko').format(_selectedDay),
        style: TextStyle(
          color: const Color(0xFF8F98A8),
          fontSize: MediaQuery.of(context).size.width * 0.04,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFF8F98A8),
        ),
      ),
    );
  }

  Widget _buildMealHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '급식',
          style: TextStyle(
            color: const Color(0xFF020202),
            fontSize: MediaQuery.of(context).size.width * 0.06,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        _buildMealTypeDropdown(),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: const Color.fromRGBO(108, 121, 139, 0.50),
    );
  }

  Widget _buildNutritionInfoButton() {
    return GestureDetector(
      onTap: () => _showNutritionBottomSheet(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '영양 정보 더보기',
            style: TextStyle(
              color: const Color(0xFF8F98A8),
              fontSize: MediaQuery.of(context).size.width * 0.04,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          SvgPicture.asset('assets/svgs/arrow_right.svg'),
        ],
      ),
    );
  }

  void _showDatePicker() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFF6F6F6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: min(MediaQuery.of(context).size.width, 600),
        ),
        builder: (BuildContext context) {
          return TableCalendar(
            focusedDay: _selectedDay,
            firstDay: DateTime(DateTime.now().year - 1),
            lastDay: DateTime(DateTime.now().year + 1),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) async {
              setState(() {
                _selectedDay = selectedDay;
              });

              final data = await fetchSchoolMeal(
                  schoolController.selectedSchool.value,
                  _getFormattedDate(selectedDay));
              setState(() => mealData = data);

              Navigator.pop(context);
            },
            locale: 'ko-KR',
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
                fontFamily: 'Pretendard',
                fontSize: MediaQuery.of(context).size.width * 0.035,
              ),
              selectedTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontFamily: 'Pretendard',
                fontSize: MediaQuery.of(context).size.width * 0.035,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF636CFF),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
                fontFamily: 'Pretendard',
                fontSize: MediaQuery.of(context).size.width * 0.035,
              ),
              todayDecoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          );
        });
  }

  void _showNutritionBottomSheet() {
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
      builder: (BuildContext context) => NutritionBottomSheet(
        mealTypeData: mealData[schoolController.selectedMealType.value],
        schoolName: schoolController.selectedSchool.value,
      ),
    );
  }

  Widget _buildSchoolInfoSkeleton() {
    return ShimmerContainer(
      width: min(MediaQuery.of(context).size.width * 0.9, 600),
      height: MediaQuery.of(context).size.height * 0.2,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerBox(width: 40, height: 24),
          ShimmerBox(width: 278, height: 1),
          ShimmerBox(width: 200, height: 16),
        ],
      ),
    );
  }

  Widget _buildMealInfoSkeleton() {
    return ShimmerContainer(
      width: min(MediaQuery.of(context).size.width * 0.9, 600),
      height: MediaQuery.of(context).size.height * 0.3,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 60, height: 24),
              ShimmerBox(width: 40, height: 24),
            ],
          ),
          SizedBox(height: 16),
          ShimmerBox(width: 278, height: 1),
          SizedBox(height: 16),
          ShimmerBox(width: double.infinity, height: 20),
          SizedBox(height: 8),
          ShimmerBox(width: double.infinity, height: 20),
          SizedBox(height: 8),
          ShimmerBox(width: 200, height: 20),
        ],
      ),
    );
  }

  Widget _buildSchoolInfo(String schoolName) {
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
              '학교',
              style: TextStyle(
                color: const Color(0xFF020202),
                fontSize: MediaQuery.of(context).size.width * 0.06,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildDivider(),
            Text(
              schoolName,
              style: const TextStyle(
                color: Color(0xFF555E70),
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
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

class _NoMealDataWidget extends StatelessWidget {
  const _NoMealDataWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '급식 데이터가 없습니다',
        style: TextStyle(
          color: Color(0xFF1E1E1E),
          fontSize: 20,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class NutritionBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? mealTypeData;
  final String schoolName;

  const NutritionBottomSheet({
    required this.mealTypeData,
    required this.schoolName,
    super.key,
  });

  @override
  State<NutritionBottomSheet> createState() => _NutritionBottomSheetState();
}

class _NutritionBottomSheetState extends State<NutritionBottomSheet> {
  bool isNutritionExpanded = false;
  bool isOriginExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.mealTypeData == null ||
        widget.mealTypeData!["nutrition"] == null) {
      return const Center(
        child: Text(
          '영양 정보가 없습니다',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 20,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(),
            const SizedBox(height: 15),
            _buildSchoolName(),
            const SizedBox(height: 15),
            _buildDivider(),
            const SizedBox(height: 15),
            _buildNutritionSection(),
            const SizedBox(height: 15),
            _buildDivider(),
            const SizedBox(height: 15),
            _buildOriginSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      '영양 정보',
      style: TextStyle(
        color: Color(0xFF101012),
        fontSize: 24,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSchoolName() {
    return Text(
      widget.schoolName,
      style: const TextStyle(
        color: Color(0xFF8F98A8),
        fontSize: 14,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
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

  Widget _buildNutritionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '영양 정보',
          style: TextStyle(
            color: Color(0xFF555E70),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        _buildExpandableList(
          items: widget.mealTypeData!["nutrition"],
          isExpanded: isNutritionExpanded,
          onToggle: () =>
              setState(() => isNutritionExpanded = !isNutritionExpanded),
        ),
      ],
    );
  }

  Widget _buildOriginSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '원산지 정보',
          style: TextStyle(
            color: Color(0xFF555E70),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        _buildExpandableList(
          items: widget.mealTypeData!["orplc"],
          isExpanded: isOriginExpanded,
          onToggle: () => setState(() => isOriginExpanded = !isOriginExpanded),
        ),
      ],
    );
  }

  Widget _buildExpandableList({
    required List<dynamic> items,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final displayItems = isExpanded ? items : items.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayItems.map((info) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                info,
                style: const TextStyle(
                  color: Color(0xFF8F98A8),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
            )),
        if (items.length > 5)
          GestureDetector(
            onTap: onToggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  isExpanded ? '접기' : '더보기',
                  style: const TextStyle(
                    color: Color(0xFF8F98A8),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                SvgPicture.asset(
                  isExpanded
                      ? 'assets/svgs/arrow_up.svg'
                      : 'assets/svgs/arrow_down.svg',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
