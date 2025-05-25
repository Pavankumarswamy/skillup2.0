import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../Mentor Pages/Create Course Page.dart';
import '../Mentor Pages/Manage Courses Page.dart';
import '/Mentor Pages/activecourses.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;
  final Map<int, bool> _isPressed = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _colorAnimation1 = ColorTween(
      begin: Colors.lightBlue.shade100,
      end: Colors.purple.shade100,
    ).animate(_controller);

    _colorAnimation2 = ColorTween(
      begin: Colors.teal.shade100,
      end: Colors.pink.shade100,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
            width: screenSize.width,
            height: screenSize.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_colorAnimation1.value!, _colorAnimation2.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Lottie Animation
                            SizedBox(
                              height: 200,
                              child: Lottie.asset('assets/men.json'),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Welcome, Mentor!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 50),
                            _buildAnimatedButton(
                              context,
                              0,
                              'Create Courses',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateCoursePage(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildAnimatedButton(
                              context,
                              1,
                              'Manage Courses',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ManageCoursesPage(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildAnimatedButton(
                              context,
                              2,
                              'Active Courses',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ActiveCoursesPage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: kToolbarHeight + 12,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(), // Keeps layout balanced
        ],
      ),
    );
  }

  Widget _buildAnimatedButton(
    BuildContext context,
    int index,
    String title,
    VoidCallback onPressed,
  ) {
    final bool isPressed = _isPressed[index] ?? false;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed[index] = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed[index] = false;
        });
        onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed[index] = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0, isPressed ? 4 : 0, 0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isPressed)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 25),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
