import 'package:flutter/material.dart';
import 'package:spin_app/api/route_api.dart';
import 'package:spin_app/core/components/app_snackbar.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/components/select_button.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/pages/route/route_detail_page.dart';

const _districts = ['유성구', '대덕구', '서구', '중구', '동구'];

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _purposeController = TextEditingController();
  String? _selectedDistrict;
  bool _isLoading = false;

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  bool get _hasInput =>
      _selectedDistrict != null || _purposeController.text.trim().isNotEmpty;

  /// 골라둔 지역과 적어둔 목적을 비운다.
  void _clearInput() {
    setState(() {
      _selectedDistrict = null;
      _purposeController.clear();
    });
    AppSnackBar.info(context, '적어둔 내용을 지웠어요');
  }

  Future<void> _createRoute() async {
    if (_selectedDistrict == null) {
      AppSnackBar.warning(context, '어디로 놀러갈지 지역을 선택해주세요');
      return;
    }
    if (_purposeController.text.trim().isEmpty) {
      AppSnackBar.warning(context, '가서 무엇을 할건지 적어주세요');
      return;
    }

    setState(() => _isLoading = true);
    final result = await generateRoute(
      region: _selectedDistrict!,
      purpose: _purposeController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      AppSnackBar.error(context, '루트 생성에 실패했어요. 잠시 후 다시 시도해주세요.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailPage(
          result: result,
          region: _selectedDistrict!,
          purpose: _purposeController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          // 키보드가 올라와 화면이 줄어들면 스크롤로 흡수되도록
          // 로그인 화면과 같은 패턴을 쓴다. (Column+Spacer는 오버플로우 발생)
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 30),
                          const Text(
                            '오늘,\n어느 곳을 놀러갈까요?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            '어디로 놀러갈까요?',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _districts.map((district) {
                              // SelectButton은 alignment가 있는 Container라 Wrap 안에서
                              // 부모 폭만큼 늘어나므로 IntrinsicWidth로 내용 크기에 맞춘다.
                              return IntrinsicWidth(
                                child: SelectButton(
                                  text: district,
                                  isOn: _selectedDistrict == district,
                                  onTap: () {
                                    setState(() {
                                      _selectedDistrict =
                                          _selectedDistrict == district
                                          ? null
                                          : district;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            '가서 무엇을 할건가요?',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onTapOutside: (event) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            controller: _purposeController,
                            // 임시저장/삭제 버튼을 쓸 수 있는지가 입력 여부에 달려 있다.
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: '혼자 커피 한 잔',
                              hintStyle: TextStyle(
                                color: Colors.black.withAlpha(90),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF6F6F6),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '한 줄이면 충분해요. AI가 목적에 맞춰 골목 가게를 골라 루트를 짭니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withAlpha(120),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ClearButton(
                            onTap: _hasInput ? _clearInput : null,
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 24),
                          _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : BottomButton(text: '루트 생성', onTap: _createRoute),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 적어둔 내용을 지우는 작은 버튼.
/// [onTap]이 null이면(=적은 게 없으면) 흐리게 비활성 상태로 보인다.
class _ClearButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ClearButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled
        ? AppColors.button
        : AppColors.greenKelp.withValues(alpha: 0.3);

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: enabled ? AppColors.greenWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                '삭제',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
