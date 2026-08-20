import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/charts/domain/glycemia_chart_data.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/hba1c/controllers/hba1c_controller.dart';
import 'package:doce_equilibrio/features/home/controllers/home_controller.dart';
import 'package:doce_equilibrio/features/home/models/weekly_glycemia_summary.dart';
import 'package:doce_equilibrio/features/home/widgets/home_dashboard_section.dart';
import 'package:doce_equilibrio/features/home/widgets/home_header.dart';
import 'package:doce_equilibrio/features/reports/screens/report_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavegarParaInsulina;

  const HomeScreen({super.key, required this.onNavegarParaInsulina});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;
  late final GlycemiaController _glycemiaController;
  late final HbA1cController _hba1cController;

  String _saudacao = 'Olá,';
  String _nomeUsuario = 'Carregando...';
  UserModel? _loggedInUser;
  GlycemiaRecordModel? _ultimaLeitura;
  WeeklyGlycemiaSummary? _weeklySummary;
  late HistoryDateRange _weeklyRange;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = getIt<HomeController>();
    _glycemiaController = getIt<GlycemiaController>();
    _hba1cController = getIt<HbA1cController>();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final saudacaoCalculada = _controller.getGreeting();
    final weeklyRange = HistoryDateRange.forPeriod(HistoryPeriod.last7Days);
    final results = await Future.wait([
      _controller.findLoggedInUser(),
      _glycemiaController.findLatestReading(),
      _glycemiaController.listHistoryByPeriod(
        weeklyRange.start,
        weeklyRange.end,
      ),
      _hba1cController.load(),
    ]);

    final loggedInUser = results[0] as UserModel?;
    final latestReading = results[1] as GlycemiaRecordModel?;
    final weeklyRecords = results[2] as List<GlycemiaRecordModel>;
    final chartData = GlycemiaChartData.fromRecords(
      weeklyRecords,
      lowAlertThreshold: loggedInUser?.normalMinimumThreshold ?? 70,
      highDangerThreshold: loggedInUser?.highDangerThreshold ?? 180,
    );
    final formattedName = loggedInUser != null
        ? _controller.nameFormatted(loggedInUser.name)
        : '';

    if (!mounted) return;
    setState(() {
      _saudacao = saudacaoCalculada;
      _nomeUsuario = formattedName.isNotEmpty ? formattedName : 'Usuário';
      _loggedInUser = loggedInUser;
      _ultimaLeitura = latestReading;
      _weeklyRange = weeklyRange;
      _weeklySummary = WeeklyGlycemiaSummary.fromChartData(chartData);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _hba1cController.dispose();
    super.dispose();
  }

  void _openReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            HomeHeader(
              saudacao: _saudacao,
              userName: _nomeUsuario,
              latestReading: _ultimaLeitura,
              user: _loggedInUser,
              onAtualizarDados: _loadInitialData,
              onNavegarParaInsulina: widget.onNavegarParaInsulina,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: HomeDashboardSection(
                hba1cEstimate: _hba1cController.estimate,
                weeklySummary: _weeklySummary!,
                weekStart: _weeklyRange.start,
                onExportReport: _openReport,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
