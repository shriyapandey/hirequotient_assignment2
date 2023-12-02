import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  bool isSelected;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isSelected = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue[900],
        hintColor: Colors.black,
      ),
      home: UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late List<User> users = [];
  late List<User> displayedUsers = [];
  late TextEditingController searchController = TextEditingController();
  int currentPage = 0;
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.get(
      Uri.parse(
          'https://geektrust.s3-ap-southeast-1.amazonaws.com/adminui-problem/members.json'),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      users = jsonData.map((json) => User.fromJson(json)).toList();
      applyPaginationAndFiltering();
    } else {
      throw Exception('Failed to load users');
    }
  }

  void applyPaginationAndFiltering() {
    final searchQuery = searchController.text.toLowerCase();
    final filteredUsers = users
        .where((user) =>
            user.name.toLowerCase().contains(searchQuery) ||
            user.email.toLowerCase().contains(searchQuery) ||
            user.role.toLowerCase().contains(searchQuery))
        .toList();

    final int maxPages = (filteredUsers.length / 10).ceil();
    currentPage = currentPage.clamp(0, maxPages - 1);

    setState(() {
      displayedUsers = filteredUsers.skip(currentPage * 10).take(10).toList();
    });
  }

  void toggleSelectAll(bool isSelected) {
    setState(() {
      selectAll = isSelected;
      for (var user in displayedUsers) {
        if (user != null) {
          user.isSelected = isSelected;
        }
      }
    });
  }

  void deleteSelected() {
    setState(() {
      displayedUsers.removeWhere((user) => user.isSelected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Admin Dashboard'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            color: Colors.white,
            onPressed: deleteSelected,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4.0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) => applyPaginationAndFiltering(),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: InputBorder.none,
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            toggleSelectAll(!selectAll);
                          },
                          icon: Icon(
                            selectAll
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: displayedUsers.length,
                itemBuilder: (context, index) {
                  final user = displayedUsers[index];
                  if (user != null) {
                    return Card(
                      color: user.isSelected ? Colors.grey[300] : null,
                      elevation: 2.0,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        // Add ListTile content here
                        leading: Checkbox(
                          value: user.isSelected,
                          onChanged: (selected) {
                            setState(() {
                              user.isSelected = selected!;
                            });
                          },
                        ),
                        title: Text(user.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Text('Role: ${user.role}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.green),
                              onPressed: () {
                                // Handle edit action
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Handle delete action
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink(); // or return an empty widget
                },
              ),
            ),
            SizedBox(height: 16.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      currentPage = 0;
                      applyPaginationAndFiltering();
                    },
                    child: Text('First Page'),
                  ),
                  IconButton(
                    onPressed: () {
                      if (currentPage > 0) {
                        currentPage--;
                        applyPaginationAndFiltering();
                      }
                    },
                    icon: Icon(Icons.arrow_back),
                  ),
                  Text('Page ${currentPage + 1}'),
                  IconButton(
                    onPressed: () {
                      if (currentPage < (users.length / 10).ceil() - 1) {
                        currentPage++;
                        applyPaginationAndFiltering();
                      }
                    },
                    icon: Icon(Icons.arrow_forward),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      currentPage = (users.length / 10).ceil() - 1;
                      applyPaginationAndFiltering();
                    },
                    child: Text('Last Page'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
