import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:to_do_app/data/notifiers.dart';
import 'package:to_do_app/pages/add_task_page.dart';
import 'package:to_do_app/pages/history.dart';
import 'package:to_do_app/pages/homepage.dart';
import 'package:to_do_app/pages/settings_page.dart';

class NavPage extends StatefulWidget {
  const NavPage({super.key});

  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> {
  int currentIndex = 0;
  File? _image;

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final bool active = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentIndex = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          margin: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: active ? 20.0 : 30.0),
                duration: Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                builder: (context, size, child) {
                  return Icon(
                    active ? activeIcon : inactiveIcon,
                    size: size,
                    color: Colors.white,
                  );
                },
              ),
              SizedBox(height: 6),
              AnimatedOpacity(
                opacity: active ? 1.0 : 0.0,
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: active ? 12 : 0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    final savedPath = box.get('imagePath');

    if (savedPath != null) {
      final file = File(savedPath);
      if (file.existsSync()) {
        setState(() {
          _image = file;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              foregroundImage: _image == null
                  ? AssetImage("assets/images/default.jpg") as ImageProvider
                  : FileImage(_image!),
            ),
            SizedBox(width: 10),
            Text(
              "Hi ${usernameNotifier.value}!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    themeMode.value = themeMode.value == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark;
                  });
                },
                icon: themeMode.value == ThemeMode.dark
                    ? Icon(Icons.light_mode, color: Colors.white)
                    : Icon(Icons.dark_mode, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  });
                },
                icon: Icon(Icons.settings),
              ),
            ],
          ),
        ],
      ),
      extendBody: true,
      body: Column(
        children: [
          SizedBox(height: 20),
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: currentIndex == 0
                  ? HomePage(key: ValueKey(0))
                  : HistoryPage(key: ValueKey(1)),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.vertical(
                top: Radius.circular(30),
              ),
            ),
            builder: (context) {
              return AddTaskPage();
            },
          );
        },
        backgroundColor: Colors.blue,
        shape: CircleBorder(side: BorderSide(color: Colors.white, width: 2.0)),
        child: Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.symmetric(horizontal: 20),
        shape: CircularNotchedRectangle(),
        notchMargin: 10.0,
        elevation: 5,
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_filled, Icons.home, 'Home'),
            Expanded(child: SizedBox()),
            _buildNavItem(1, Icons.history_sharp, Icons.history, 'History'),
          ],
        ),
      ),
    );
  }
}
