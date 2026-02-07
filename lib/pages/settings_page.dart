import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:to_do_app/data/constants.dart';
import 'package:to_do_app/data/notification_service.dart';
import 'package:to_do_app/data/notifiers.dart';
import 'package:to_do_app/pages/socials.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    usernameController.text = usernameNotifier.value;
    final box = Hive.box('settings');
    final savedPath = box.get('imagePath');

    if (savedPath != null) {
      final file = File(savedPath);
      if (file.existsSync()) {
        _image = file;
      }
    }
  }

  File? _image; // To store the selected image
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (selected == null) return;

    final box = Hive.box('settings');

    // Delete old image FIRST
    final oldPath = box.get('imagePath');
    if (oldPath != null) {
      final oldFile = File(oldPath);
      if (oldFile.existsSync()) {
        oldFile.delete();
      }
    }

    final directory = await getApplicationDocumentsDirectory();

    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.png';
    final newPath = p.join(directory.path, fileName);

    final newImage = await File(selected.path).copy(newPath);

    box.put('imagePath', newImage.path);

    setState(() {
      _image = newImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  border: themeMode.value == ThemeMode.dark
                      ? Border.all(width: 1, color: Colors.grey)
                      : Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: themeMode.value == ThemeMode.dark
                                ? Colors.grey
                                : Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : null,
                              backgroundColor: themeMode.value == ThemeMode.dark
                                  ? Colors.black
                                  : fillColorOne,
                              radius: 40,
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: themeMode.value == ThemeMode.dark
                                    ? fillColorOne
                                    : Colors.black45,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Name :",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: usernameController,
                                  cursorHeight: 15,
                                  cursorColor: Colors.blue,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: themeMode.value == ThemeMode.dark
                                        ? Theme.of(context).primaryColor
                                        : fillColorOne,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        width: 1,
                                        color: themeMode.value == ThemeMode.dark
                                            ? Colors.grey
                                            : Colors.transparent,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        width: 2,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            final box = Hive.box('settings');
                            box.put('username', usernameController.text);
                            usernameNotifier.value = usernameController.text;
                          });
                        },

                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                        ),
                        child: Text(
                          "Update",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  border: themeMode.value == ThemeMode.dark
                      ? Border.all(width: 1, color: Colors.grey)
                      : Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Appearance :",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Theme Mode :",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(30),
                          child: Container(
                            decoration: BoxDecoration(color: fillColorOne),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      themeMode.value = ThemeMode.light;
                                      final box = Hive.box('settings');
                                      box.put('themeMode', 'light');
                                    });
                                  },
                                  child: Container(
                                    width: 70,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    color: themeMode.value != ThemeMode.light
                                        ? fillColorOne
                                        : Colors.blue,
                                    child: Center(
                                      child: Text(
                                        "Light",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              themeMode.value != ThemeMode.light
                                              ? Colors.black87
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      themeMode.value = ThemeMode.dark;
                                      final box = Hive.box('settings');
                                      box.put('themeMode', 'dark');
                                    });
                                  },
                                  child: Container(
                                    width: 70,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    color: themeMode.value != ThemeMode.dark
                                        ? fillColorOne
                                        : Colors.blue,
                                    child: Center(
                                      child: Text(
                                        "Dark",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              themeMode.value != ThemeMode.dark
                                              ? Colors.black87
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      themeMode.value = ThemeMode.system;
                                      final box = Hive.box('settings');
                                      box.put('themeMode', 'system');
                                    });
                                  },
                                  child: Container(
                                    width: 70,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    color: themeMode.value != ThemeMode.system
                                        ? fillColorOne
                                        : Colors.blue,
                                    child: Center(
                                      child: Text(
                                        "System",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              themeMode.value !=
                                                  ThemeMode.system
                                              ? Colors.black87
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await NotificationService.requestPermission();

                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Notification permission requested',
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Enable Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  border: themeMode.value == ThemeMode.dark
                      ? Border.all(width: 1, color: Colors.grey)
                      : Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      "Developed by : ",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Uthman Adesiyan Adeolu (Brillo Digitals)",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 15,
                      children: [
                        Icon(Icons.phone, size: 20),
                        Text(
                          "+234 8146269699",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 15,
                      children: [
                        Icon(Icons.email, size: 20),
                        Text(
                          "uthmanadesiyan112@gmail.com",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SocialButtons(
                      isOneColor: true,
                      color: themeMode.value == ThemeMode.dark
                          ? Colors.white
                          : Colors.black,
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
}
