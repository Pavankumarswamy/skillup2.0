import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  _MembershipPageState createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  late Razorpay _razorpay;
  late DatabaseReference _userRef;
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _hasMembership = false;
  String? _selectedDuration; // Store selected duration

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    if (_user != null) {
      _userRef = FirebaseDatabase.instance.ref("users/${_user.uid}");
      _userRef.once().then((snapshot) {
        if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
          var userData = Map<String, dynamic>.from(
            snapshot.snapshot.value as Map,
          );
          setState(() {
            _hasMembership =
                userData['membershipPlan'] == "true"; // Fixed boolean check
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Membership Plans'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.lightBlue.shade300],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_hasMembership)
                Column(
                  children: [
                    const Text(
                      'You have an active premium membership!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.green),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              if (!_hasMembership)
                Expanded(
                  child: ListView(
                    children: [
                      _buildMembershipCard(
                        context,
                        title: 'Monthly Plan',
                        price: 150,
                        duration: '1 Month',
                        benefits: [
                          'All Basic Features',
                          'Priority Support',
                          'Weekly Updates',
                        ],
                      ),
                      _buildMembershipCard(
                        context,
                        title: 'Quarterly Plan',
                        price: 349,
                        duration: '3 Months',
                        benefits: [
                          'Everything in Monthly',
                          '10% Discount',
                          'Exclusive Content',
                        ],
                        isPopular: true,
                      ),
                      _buildMembershipCard(
                        context,
                        title: 'Half-Year Plan',
                        price: 399,
                        duration: '6 Months',
                        benefits: [
                          'Everything in Quarterly',
                          '20% Discount',
                          'VIP Support',
                          'Early Access Features',
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipCard(
    BuildContext context, {
    required String title,
    required int price,
    required String duration,
    required List<String> benefits,
    bool isPopular = false,
  }) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap:
            () =>
                _openCheckout(price, duration), // Pass both price and duration
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              if (isPopular)
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black38,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...benefits.map(
                      (benefit) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              benefit,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 1, 158, 255),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '₹$price',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 228, 228, 228),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("Payment Successful: ${response.paymentId}");

    if (_user != null) {
      _userRef = FirebaseDatabase.instance.ref("users/${_user.uid}");
      await _userRef.update({
        'membershipPlan': true,
        'membershipDuration': _selectedDuration, // Store duration
      });

      setState(() {
        _hasMembership = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membership activated successfully!')),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Error: ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  void _openCheckout(int amount, String duration) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to purchase membership.')),
      );
      return;
    }

    setState(() {
      _selectedDuration = duration;
    });

    var options = {
      'key': 'rzp_live_HJl9NwyBSY9rwV', // Replace with your key
      'amount': amount * 100,
      'name': "Skill UP Premium",
      'description': 'Premium Subscription',
      'prefill': {
        'contact': _user.phoneNumber ?? '',
        'email': _user.email ?? '',
      },
      'external': {
        'wallets': ['paytm', 'phonepe'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Error opening Razorpay: $e");
    }
  }
}
