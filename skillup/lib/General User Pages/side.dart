import '/General%20User%20Pages/Membership%20Page.dart';
import '/General%20User%20Pages/certificates.dart';
import '/General%20User%20Pages/mycourses.dart';
import '/General%20User%20Pages/dashwidget.dart';
import '/General%20User%20Pages/search.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class MenuWidget extends StatelessWidget {
  final Function(Widget) onItemSelected;
  const MenuWidget({required this.onItemSelected, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dynamic Neural Network Background
        Positioned.fill(child: NeuralNetworkBackground()),

        // Sidebar Menu
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 450,
          child: Container(
            color: Colors.black.withOpacity(0.3), // Semi-transparent black
            padding: const EdgeInsets.only(top: 80, left: 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedTile(
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => onItemSelected(const UserDashboardWidget()),
                ),
                const SizedBox(height: 20),
                _buildAnimatedTile(
                  icon: Icons.search,
                  title: 'Courses',
                  onTap: () => onItemSelected(SearchCoursesPage()),
                ),
                const SizedBox(height: 20),
                _buildAnimatedTile(
                  icon: Icons.card_membership,
                  title: 'Membership',
                  onTap: () => onItemSelected(MembershipPage()),
                ),
                const SizedBox(height: 20),
                _buildAnimatedTile(
                  icon: Icons.my_library_books_outlined,
                  title: 'My course',
                  onTap: () => onItemSelected(MyCoursesPage()),
                ),
                const SizedBox(height: 20),
                _buildAnimatedTile(
                  icon: Icons.card_giftcard,
                  title: 'certificates',
                  onTap: () => onItemSelected(CertificatesPage()),
                ),
              ],
            ),
          ),
        ),

        // Logout Button at Bottom
        Positioned(
          left: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () async {
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseDatabase.instance
                    .ref("users/${user.uid}/session")
                    .remove();
              }

              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/",
                  (route) => false,
                );
              }
            },
            backgroundColor: Colors.red,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: const Icon(Icons.logout, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.blue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NeuralNetworkBackground extends StatefulWidget {
  const NeuralNetworkBackground({super.key});

  @override
  _NeuralNetworkBackgroundState createState() =>
      _NeuralNetworkBackgroundState();
}

class _NeuralNetworkBackgroundState extends State<NeuralNetworkBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  List<Node> blueNodes = [];
  final int nodeCount = 15; // Reduced for professional look
  Set<Offset> touchPositions = {};

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 8,
      ), // Slower for smooth, professional feel
    )..repeat();

    // Initialize blue nodes
    final random = math.Random();
    for (int i = 0; i < nodeCount; i++) {
      blueNodes.add(
        Node(
          position: Offset(random.nextDouble(), random.nextDouble()),
          velocity: Offset(
            (random.nextDouble() - 0.5) * 3,
            (random.nextDouble() - 0.5) * 3,
          ),
          touchAttraction: 0.2, // Subtle gesture response
          size: 5 + random.nextDouble() * 2, // Smaller, consistent nodes
          weight: random.nextDouble() * 0.4 + 0.6, // Higher weights for clarity
        ),
      );
    }

    // Update node positions
    _controller.addListener(() {
      setState(() {
        for (var node in blueNodes) {
          node.update(touchPositions, MediaQuery.of(context).size);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        setState(() {
          touchPositions.add(event.localPosition);
        });
      },
      onPointerMove: (event) {
        setState(() {
          touchPositions.add(event.localPosition);
          if (touchPositions.length > 3) {
            // Reduced for subtlety
            touchPositions.remove(touchPositions.first);
          }
        });
      },
      onPointerUp: (event) {
        setState(() {
          touchPositions.clear();
        });
      },
      child: Container(
        color: Colors.black, // Black background
        child: CustomPaint(
          painter: NeuralNetworkPainter(
            blueNodes: blueNodes,
            animationValue: _controller.value,
            touchPositions: touchPositions,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class Node {
  Offset position; // Normalized (0 to 1)
  Offset velocity;
  double touchAttraction;
  double size;
  double weight;

  Node({
    required this.position,
    required this.velocity,
    required this.touchAttraction,
    required this.size,
    required this.weight,
  });

  void update(Set<Offset> touchPositions, Size screenSize) {
    // Scale position to screen
    var scaledPosition = Offset(
      position.dx * screenSize.width,
      position.dy * screenSize.height,
    );
    scaledPosition += velocity;
    final random = math.Random();

    // Bounce off edges
    if (scaledPosition.dx < 0 || scaledPosition.dx > screenSize.width) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (scaledPosition.dy < 0 || scaledPosition.dy > screenSize.height) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }

    // Update normalized position
    position = Offset(
      scaledPosition.dx / screenSize.width,
      scaledPosition.dy / screenSize.height,
    );

    // Move toward nearest touch
    for (var touch in touchPositions) {
      final scaledTouch = touch;
      final direction = scaledTouch - scaledPosition;
      final distance = direction.distance;
      if (distance > 10) {
        velocity += direction / distance * touchAttraction * weight;
      }
    }

    // Random velocity
    velocity += Offset(
      (random.nextDouble() - 0.5) * 0.2,
      (random.nextDouble() - 0.5) * 0.2,
    ); // Smoother randomness

    // Limit velocity
    if (velocity.distance > 3) {
      // Reduced for calmer movement
      velocity = velocity / velocity.distance * 3;
    }
  }
}

class NeuralNetworkPainter extends CustomPainter {
  final List<Node> blueNodes;
  final double animationValue;
  final Set<Offset> touchPositions;

  NeuralNetworkPainter({
    required this.blueNodes,
    required this.animationValue,
    required this.touchPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random();

    // Draw nodes with refined glow
    for (var node in blueNodes) {
      final paint =
          Paint()
            ..color = Colors.blue.shade700.withOpacity(
              0.95,
            ) // Professional deep blue
            ..style = PaintingStyle.fill;
      final glowPaint =
          Paint()
            ..color = Colors.blue.shade700.withOpacity(0.25)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(
              BlurStyle.normal,
              6,
            ); // Softer glow
      canvas.drawCircle(
        Offset(node.position.dx * size.width, node.position.dy * size.height),
        node.size * 1.4,
        glowPaint,
      );
      canvas.drawCircle(
        Offset(node.position.dx * size.width, node.position.dy * size.height),
        node.size,
        paint,
      );
    }

    // Draw touch sparks (subtle)
    for (var touch in touchPositions) {
      final sparkPaint =
          Paint()
            ..color = Colors.white.withOpacity(
              0.5 + (math.sin(animationValue * 3 * math.pi) * 0.15),
            )
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(
              BlurStyle.normal,
              8,
            ); // Smaller spark
      canvas.drawCircle(touch, 10, sparkPaint);
    }

    // Draw blue connections
    final blueLinePaint =
        Paint()
          ..color = Colors.white.withOpacity(
            0.5 + (math.sin(animationValue * 2 * math.pi) * 0.2),
          ) // Subtle pulse
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8; // Thinner, crisp lines
    for (int i = 0; i < blueNodes.length; i++) {
      for (int j = i + 1; j < blueNodes.length; j++) {
        final p1 = Offset(
          blueNodes[i].position.dx * size.width,
          blueNodes[i].position.dy * size.height,
        );
        final p2 = Offset(
          blueNodes[j].position.dx * size.width,
          blueNodes[j].position.dy * size.height,
        );
        final distance = (p1 - p2).distance;
        if (distance < 250 && random.nextDouble() > 0.5) {
          // Longer range, sparser connections
          final weight = (blueNodes[i].weight + blueNodes[j].weight) / 2;
          final weightedPaint =
              Paint()
                ..color = blueLinePaint.color.withOpacity(
                  blueLinePaint.color.opacity * weight,
                )
                ..style = PaintingStyle.stroke
                ..strokeWidth = blueLinePaint.strokeWidth * weight;
          canvas.drawLine(p1, p2, weightedPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension OffsetExtension on Offset {
  double distanceTo(Offset other) {
    final dx = this.dx - other.dx;
    final dy = this.dy - other.dy;
    return math.sqrt(dx * dx + dy * dy);
  }
}
