import 'package:go_router/go_router.dart';
import 'presentation/screens/disease_screen.dart';
import 'presentation/screens/disease_detail_screen.dart';
import 'data/models/disease_report_model.dart';

class DiseaseRoutes {
  static const String disease = '/disease';
  static const String diseaseDetail = '/disease/detail';

  static List<GoRoute> get routes => [
        GoRoute(
          path: disease,
          builder: (context, state) => const DiseaseScreen(),
        ),
        GoRoute(
          path: diseaseDetail,
          builder: (context, state) {
            final report = state.extra as DiseaseReportModel;
            return DiseaseDetailScreen(report: report, isHindi: true);
          },
        ),
      ];
}
