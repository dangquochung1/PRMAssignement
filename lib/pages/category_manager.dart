import 'package:flutter/material.dart';
import 'package:prmproject/services/shared_pref.dart';

class CategoryManager extends StatefulWidget {
  const CategoryManager({super.key});

  @override
  State<CategoryManager> createState() => _CategoryManagerState();
}

class _CategoryManagerState extends State<CategoryManager> {
  List<String> categories = [];
  TextEditingController catController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  _loadCategories() async {
    List<String>? savedCats = await SharedPreferenceHelper().getUserCategories();
    if (savedCats == null || savedCats.isEmpty) {
      categories = ['Shopping', 'Grocery', 'Others'];
      await SharedPreferenceHelper().saveUserCategories(categories);
    } else {
      categories = savedCats;
    }
    setState(() {});
  }

  _saveCategories() async {
    await SharedPreferenceHelper().saveUserCategories(categories);
    setState(() {});
  }

  _addOrEditCategory({int? index}) {
    if (index != null) {
      catController.text = categories[index];
    } else {
      catController.clear(); // Xóa text cũ nếu thêm mới
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? "Add Category" : "Edit Category"),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(hintText: "Enter category name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (catController.text.isNotEmpty) {
                if (index == null) {
                  categories.add(catController.text);
                } else {
                  categories[index] = catController.text;
                }
                _saveCategories();
                catController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Categories", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xffee6856),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: ListTile(
              title: Text(categories[index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _addOrEditCategory(index: index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      categories.removeAt(index);
                      _saveCategories();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xffee6856),
        onPressed: () => _addOrEditCategory(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}