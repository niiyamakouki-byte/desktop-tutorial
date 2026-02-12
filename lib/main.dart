import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/services/project_provider.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/project_repository.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/project_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize repositories
  final taskRepository = TaskRepository();
  final projectRepository = ProjectRepository();
  await taskRepository.initialize();
  await projectRepository.initialize();
  
  runApp(ConstructionProjectManagerApp(
    taskRepository: taskRepository,
    projectRepository: projectRepository,
  ));
}

/// Main application widget for Construction Project Manager
class ConstructionProjectManagerApp extends StatelessWidget {
  final TaskRepository taskRepository;
  final ProjectRepository projectRepository;

  const ConstructionProjectManagerApp({
    super.key,
    required this.taskRepository,
    required this.projectRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProjectProvider(
            taskRepository: taskRepository,
            projectRepository: projectRepository,
          ),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '建設プロジェクト管理',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(ThemeProvider.lightTheme),
            darkTheme: _buildTheme(ThemeProvider.darkTheme),
            themeMode: themeProvider.themeMode,
            home: const AppNavigator(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(ThemeData base) {
    return base.copyWith(
      textTheme: GoogleFonts.notoSansJpTextTheme(base.textTheme),
    );
  }
}

/// Main Navigator - handles project selection and navigation
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  Project? _selectedProject;

  @override
  Widget build(BuildContext context) {
    if (_selectedProject == null) {
      return ProjectDashboardScreen(
        onProjectSelected: (project) {
          setState(() => _selectedProject = project);
        },
      );
    }

    return WillPopScope(
      onWillPop: () async {
        setState(() => _selectedProject = null);
        return false;
      },
      child: HomeScreen(
        projectId: _selectedProject!.id,
        projectName: _selectedProject!.name,
        onBackToProjects: () {
          setState(() => _selectedProject = null);
        },
      ),
    );
  }
}
