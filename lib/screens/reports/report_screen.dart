import 'package:flutter/material.dart';
import '../../widgets/common/app_drawer.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('Halaman Laporan (Segera Hadir)'),
      ),
    );
  }
}
