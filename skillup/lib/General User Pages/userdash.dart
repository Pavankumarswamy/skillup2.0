// import '/General%20User%20Pages/certificateupload.dart';
// import '/General%20User%20Pages/delete.dart';
// import '/General%20User%20Pages/uploadimage.dart';
// import '/admin%20screens/dashboard%20admin.dart';

// import '../General%20User%20Pages/side.dart';
// import '../admin%20screens/admin.dart';
// import 'package:flutter/material.dart';
// import '../General%20User%20Pages/dashwidget.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class UserDashboardPage extends StatefulWidget {
//   const UserDashboardPage({super.key});

//   @override
//   State<UserDashboardPage> createState() => _UserDashboardPageState();
// }

// class _UserDashboardPageState extends State<UserDashboardPage>
//     with SingleTickerProviderStateMixin {
//   bool isMenuOpen = false;
//   late AnimationController _animationController;
//   late Animation<double> _rotateAnimation;
//   late Animation<double> _borderRadiusAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _translateAnimation;
//   Widget _selectedWidget = const UserDashboardWidget();

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
//       CurvedAnimation(
//           parent: _animationController, curve: Curves.easeInOutQuad),
//     );

//     _borderRadiusAnimation = Tween<double>(begin: 0, end: 40).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );

//     _scaleAnimation = Tween<double>(begin: 1, end: 0.70).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );

//     _translateAnimation = Tween<double>(begin: 0, end: 190).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//   }

//   void _toggleMenu() {
//     if (isMenuOpen) {
//       _animationController.reverse().then((_) {
//         setState(() => isMenuOpen = false);
//       });
//     } else {
//       setState(() => isMenuOpen = true);
//       _animationController.forward();
//     }
//   }

//   void _selectMenuItem(Widget widget) {
//     setState(() {
//       _selectedWidget = widget;
//       _toggleMenu();
//     });
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         MenuWidget(onItemSelected: _selectMenuItem),
//         AnimatedBuilder(
//           animation: _animationController,
//           builder: (context, child) {
//             return Transform(
//               alignment: Alignment.centerLeft,
//               transform: Matrix4.identity()
//                 ..setEntry(3, 2, 0.002)
//                 ..rotateY(_rotateAnimation.value)
//                 ..translate(_translateAnimation.value)
//                 ..scale(_scaleAnimation.value),
//               child: ClipRRect(
//                 borderRadius:
//                     BorderRadius.circular(_borderRadiusAnimation.value),
//                 child: Scaffold(
//                   appBar: AppBar(
//                     leading: IconButton(
//                       icon: const Icon(Icons.menu),
//                       onPressed: _toggleMenu,
//                     ),
//                     title: const Text('Skill UP'),
//                     backgroundColor: Colors.blue,
//                     shape: const RoundedRectangleBorder(
//                       borderRadius:
//                           BorderRadius.vertical(bottom: Radius.circular(25)),
//                     ),
//                     flexibleSpace: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: const BorderRadius.vertical(
//                           bottom: Radius.circular(25),
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.blue.shade900,
//                             offset: const Offset(0, 5),
//                             blurRadius: 5,
//                             spreadRadius: 1.5,
//                           ),
//                         ],
//                         gradient: LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           colors: [
//                             Colors.blue.shade400,
//                             Colors.blue.shade800,
//                           ],
//                         ),
//                       ),
//                     ),
//                     actions: [
//                       if (FirebaseAuth.instance.currentUser?.email ==
//                           "shesettipavankumarswamy@gmail.com") ...[
//                         IconButton(
//                           icon: const Icon(Icons.admin_panel_settings,
//                               color: Colors.black),
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AdminDashboard(),
//                               ),
//                             );
//                           },
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.add_to_home_screen_outlined,
//                               color: Colors.black),
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AdminCoursesPage(),
//                               ),
//                             );
//                           },
//                         ), //DeleteSessionsPage
//                         IconButton(
//                           icon: const Icon(Icons.image, color: Colors.black),
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => UploadImagePage(),
//                               ),
//                             );
//                           },
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.celebration,
//                               color: Colors.black),
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => SearchAndUploadPage(),
//                               ),
//                             );
//                           },
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete_outline,
//                               color: Colors.black),
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => DeleteSessionsPage(),
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ],
//                   ),
//                   body: _selectedWidget,
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:skillup/Mentor%20Pages/dashboard.dart';

import '/General%20User%20Pages/Membership%20Page.dart';
import '/General%20User%20Pages/certificates.dart';
import '/General%20User%20Pages/mycourses.dart';
import '/General%20User%20Pages/dashwidget.dart';
import '/General%20User%20Pages/search.dart';
import '/General%20User%20Pages/certificateupload.dart';
import '/General%20User%20Pages/delete.dart';
import '/General%20User%20Pages/uploadimage.dart';
import '/General%20User%20Pages/profile.dart';
import '/admin%20screens/dashboard%20admin.dart';
import '/admin%20screens/admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 2; // Home is at index 2
  late PageController _pageController;
  late MotionTabBarController _tabController;
  bool isAdmin = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Navigation items for MotionTabBar
  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.search,
      'label': 'Search',
      'page': const SearchCoursesPage(),
      'tooltip': 'Search Courses',
    },
    {
      'icon': Icons.book,
      'label': 'My Courses',
      'page': const MyCoursesPage(),
      'tooltip': 'My Enrolled Courses',
    },
    {
      'icon': Icons.home,
      'label': 'Home',
      'page': const UserDashboardWidget(),
      'tooltip': 'Go to Dashboard',
    },
    {
      'icon': Icons.celebration,
      'label': 'Certifications',
      'page': const CertificatesPage(),
      'tooltip': 'View Certifications',
    },
    {
      'icon': Icons.person,
      'label': 'Profile',
      'page': const ProfilePage(),
      'tooltip': 'View Profile',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Check if the current user is an admin
    final user = FirebaseAuth.instance.currentUser;
    isAdmin = user?.email == "shesettipavankumarswamy@gmail.com";

    // Initialize controllers
    _pageController = PageController(initialPage: _selectedIndex);
    _tabController = MotionTabBarController(
      initialIndex: _selectedIndex,
      length: _navItems.length,
      vsync: this,
    );
  }

  // Update the selected index and animate to the corresponding page
  void _onItemTapped(int index) {
    if (index < 0 || index >= _navItems.length) {
      debugPrint('Invalid tab index: $index');
      return;
    }
    setState(() {
      _selectedIndex = index;
      _tabController.index = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
    if (Platform.isAndroid || Platform.isIOS) {
      HapticFeedback.lightImpact();
    }
  }

  // Toggle menu open/close
  void _toggleMenu({required bool isRightSide}) {
    if (isRightSide) {
      if (_scaffoldKey.currentState!.isEndDrawerOpen) {
        _scaffoldKey.currentState!.closeEndDrawer();
      } else {
        _scaffoldKey.currentState!.openEndDrawer();
      }
    } else {
      if (_scaffoldKey.currentState!.isDrawerOpen) {
        _scaffoldKey.currentState!.closeDrawer();
      } else {
        _scaffoldKey.currentState!.openDrawer();
      }
    }
  }

  // Handle logout
  Future<void> _handleLogout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseDatabase.instance
            .ref("users/${user.uid}/session")
            .remove();
      }
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Skill UP',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade900,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.2)),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Menu (Left)',
            onPressed: () => _toggleMenu(isRightSide: false),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: 'Menu (Right)',
              onPressed: () => _toggleMenu(isRightSide: true),
            ),
          ),
        ],
      ),
      drawer: MenuWidget(
        isAdmin: isAdmin,
        onLogout: _handleLogout,
        onToggle: () => _toggleMenu(isRightSide: false),
        isRightSide: false,
      ),
      endDrawer: MenuWidget(
        isAdmin: isAdmin,
        onLogout: _handleLogout,
        onToggle: () => _toggleMenu(isRightSide: true),
        isRightSide: true,
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _navItems.map((item) => item['page'] as Widget).toList(),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 80, // Reduced height
                margin: const EdgeInsets.symmetric(horizontal: 8),
                clipBehavior: Clip.none, // Allow bubble to render outside
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade900, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Colors.transparent,
                  ),
                  child: MotionTabBar(
                    controller: _tabController,
                    labels:
                        _navItems
                            .map((item) => item['label'] as String)
                            .toList(),
                    icons:
                        _navItems
                            .map((item) => item['icon'] as IconData)
                            .toList(),
                    initialSelectedTab: _navItems[_selectedIndex]['label'],
                    tabIconColor: Colors.grey.shade300,
                    tabSelectedColor: Colors.blue.shade800,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    tabBarColor: Colors.transparent,
                    tabBarHeight: 70, // Reduced height
                    tabIconSize: 26,
                    tabIconSelectedSize: 34,
                    onTabItemSelected: _onItemTapped,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MenuWidget extends StatefulWidget {
  final bool isAdmin;
  final VoidCallback onLogout;
  final VoidCallback onToggle;
  final bool isRightSide;

  const MenuWidget({
    super.key,
    required this.isAdmin,
    required this.onLogout,
    required this.onToggle,
    required this.isRightSide,
  });

  @override
  _MenuWidgetState createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            hoverColor: Colors.blue.shade200.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: ListTile(
              title: Text(
                title,
                style: const TextStyle(fontSize: 18),
                textAlign:
                    widget.isRightSide ? TextAlign.right : TextAlign.left,
              ),
              trailing: Icon(icon, color: Colors.blue.shade800, size: 28),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade900, Colors.blue.shade400],
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  widget.isRightSide
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                // Drawer Header
                Container(
                  height: 120,
                  color: Colors.blue.shade800,
                  padding: const EdgeInsets.only(top: 48, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment:
                        widget.isRightSide
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                    children: [
                      if (!widget.isRightSide) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: widget.onToggle,
                        ),
                        const SizedBox(width: 16),
                      ],
                      Text(
                        'Menu',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.isRightSide) ...[
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: widget.onToggle,
                        ),
                      ],
                    ],
                  ),
                ),
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      left: widget.isRightSide ? 16 : 16,
                      right: widget.isRightSide ? 16 : 16,
                      top: 16,
                      bottom: 16,
                    ),
                    children: [
                      _buildMenuItem(
                        icon: Icons.table_chart,
                        title: 'Mentor',
                        onTap: () {
                          widget.onToggle();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MentorDashboard(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.star,
                        title: 'Membership',
                        onTap: () {
                          widget.onToggle();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MembershipPage(),
                            ),
                          );
                        },
                      ),
                      if (widget.isAdmin) ...[
                        _buildMenuItem(
                          icon: Icons.school,
                          title: 'Admin Courses',
                          onTap: () {
                            widget.onToggle();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminCoursesPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.admin_panel_settings,
                          title: 'Admin Dashboard',
                          onTap: () {
                            widget.onToggle();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminDashboard(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.image,
                          title: 'Upload Image',
                          onTap: () {
                            widget.onToggle();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UploadImagePage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.celebration,
                          title: 'Upload Certificates',
                          onTap: () {
                            widget.onToggle();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const SearchAndUploadPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.delete_outline,
                          title: 'Delete Sessions',
                          onTap: () {
                            widget.onToggle();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const DeleteSessionsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Floating Action Button for Logout
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FloatingActionButton(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                onPressed: () {
                  widget.onToggle();
                  widget.onLogout();
                },
                tooltip: 'Logout',
                child: const Icon(Icons.logout),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
