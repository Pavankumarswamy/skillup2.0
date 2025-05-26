import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  _CertificatesPageState createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  late DatabaseReference _certificatesRef;
  Map<String, String> certificates = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _certificatesRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user!.uid)
          .child('certificates');
      _loadCertificates();
    }
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await _certificatesRef.once();
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>,
        );
        setState(() {
          certificates = data.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading certificates: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in to view certificates',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : certificates.isEmpty
              ? Center(
                child: Text(
                  'No certificates found',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.grey),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two certificates per row
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.023, // Adjust for card height/width ratio
                ),
                itemCount: certificates.length,
                itemBuilder: (context, index) {
                  final certificateKey = certificates.keys.elementAt(index);
                  final certificateUrl = certificates[certificateKey]!;

                  return GestureDetector(
                    onTap: () => _openInBrowser(certificateUrl),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade100, Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Certificate Image with rounded corners
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              certificateUrl,
                              fit: BoxFit.cover,
                              height: 140,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  height: 142,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  height: 140,
                                  child: Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Certificate Title
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              certificateKey,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Open in Browser Button
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _openInBrowser(certificateUrl),
                              icon: const Icon(Icons.open_in_browser, size: 18),
                              label: const Text('View'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadCertificates,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
