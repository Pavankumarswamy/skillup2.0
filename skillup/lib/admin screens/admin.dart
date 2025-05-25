import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('users');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: const Text("Admin Dashboard"),
            centerTitle: true,
            backgroundColor: const Color.fromARGB(255, 0, 166, 255),
          ),
        ),
      ),
      body: FutureBuilder<DatabaseEvent>(
        future: dbRef.once(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error fetching data"));
          } else if (!snapshot.hasData ||
              snapshot.data!.snapshot.children.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!.snapshot.children.toList();
          final filteredUsers = users.where((user) {
            final userData = user.value as Map<dynamic, dynamic>? ?? {};
            return userData.containsKey('role');
          }).toList();

          if (filteredUsers.isEmpty) {
            return const Center(child: Text("No users with roles found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final userData = user.value as Map<dynamic, dynamic>? ?? {};
              final roleController =
                  TextEditingController(text: userData['role'] ?? '');
              final memberController =
                  TextEditingController(text: userData['membershipPlan'] ?? '');

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    // Prevents overflow
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            userData['email'] ?? 'No Email',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: roleController,
                          decoration: InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () {
                                dbRef
                                    .child(user.key!)
                                    .update({'role': roleController.text});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Role updated successfully!')),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: memberController,
                          decoration: InputDecoration(
                            labelText: 'Membership Plan',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () {
                                dbRef.child(user.key!).update(
                                    {'membershipPlan': memberController.text});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Membership Plan updated successfully!')),
                                );
                              },
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
        },
      ),
    );
  }
}
