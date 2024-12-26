import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:bapkok/utils/controller/SchoolController.dart';
import 'package:bapkok/utils/api/Schools.dart';
import 'package:shimmer/shimmer.dart';

class MyAppBar extends StatefulWidget {
  const MyAppBar({super.key});

  @override
  State<MyAppBar> createState() => _MyAppBarState();
}

class _MyAppBarState extends State<MyAppBar> {
  final _searchController = TextEditingController();
  final _schoolController = Get.find<SchoolController>();
  TextEditingController? _autocompleteController;

  List<String> get _schoolNames =>
      List<String>.from(_schoolController.allSchoolNames);

  @override
  void initState() {
    super.initState();
    _initializeSchools();
  }

  Future<void> _initializeSchools() async {
    if (_schoolController.allSchools.isEmpty) {
      await _fetchAndSetSchools();
    }
  }

  Future<void> _fetchAndSetSchools() async {
    _setLoading(true);

    try {
      final schools = await fetchAllSchools();
      final schoolNames =
          schools.map((school) => school["SCHUL_NM"] as String).toList();

      _schoolController.setAllSchools(schools);
      _schoolController.setAllSchoolNames(schoolNames);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _schoolController.setLoading(value);
      });
    });
  }

  Future<void> _handleSearch(String schoolName) async {
    if (schoolName.isEmpty || !_schoolNames.contains(schoolName)) return;

    _schoolController.selectSchool(schoolName);
    _searchController.clear();
    _autocompleteController?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFFEDEEF1),
      centerTitle: true,
      title: _buildSearchField(),
    );
  }

  Widget _buildSearchField() {
    return Obx(() {
      if (_schoolController.isLoading.value) {
        return _buildShimmerField();
      }
      return _buildAutoCompleteField();
    });
  }

  Widget _buildShimmerField() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildAutoCompleteField() {
    return Container(
      width: MediaQuery.of(context).size.width,
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
      enabled: !_schoolController.isLoading.value,
      cursorColor: Colors.black,
      textAlignVertical: TextAlignVertical.center,
      onSubmitted: (value) {
        _handleSearch(_searchController.text);
      },
      decoration: InputDecoration(
        hintText:
            _schoolController.isLoading.value ? "데이터 로딩중..." : "학교를 입력하세요.",
        hintStyle: const TextStyle(
          color: Color(0xFFCCCCCC),
          fontSize: 16,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: _buildSearchIcon(textEditingController),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildSearchIcon(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => _handleSearch(_searchController.text),
        child: SvgPicture.asset(
          'assets/svgs/search.svg',
          color: _schoolController.isLoading.value ? Colors.grey : null,
        ),
      ),
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
            width: MediaQuery.of(context).size.width - 70,
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
}
