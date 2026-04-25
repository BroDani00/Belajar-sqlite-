import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ListUserDataPage());
  }
}

class UserModel {
  int? id;
  String nama;
  int umur;

  // Nama konstruktor harus sama dengan nama Class
  UserModel({this.id, required this.nama, required this.umur});
}

class ListUserDataPage extends StatefulWidget {
  const ListUserDataPage({super.key});

  @override
  State<ListUserDataPage> createState() => _ListUserDataPageState();
}

class _ListUserDataPageState extends State<ListUserDataPage> {
  // Menggunakan UserModel secara konsisten
  List<UserModel> userList = [
    UserModel(id: 1, nama: "1", umur: 10),
    UserModel(id: 2, nama: "2", umur: 20),
    UserModel(id: 3, nama: "3", umur: 30),
    UserModel(id: 4, nama: "4", umur: 40),
  ];

  TextEditingController nameController = TextEditingController();
  TextEditingController umurController = TextEditingController();

  void _form(int? id) {
    if (id != null) {
      final data = userList.firstWhere((element) => element.id == id);
      nameController.text = data.nama;
      umurController.text = data.umur.toString();
    } else {
      nameController.clear();
      umurController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 50,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "nama"),
              ),
              TextField(
                controller: umurController,
                decoration: const InputDecoration(hintText: "umur"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _save(id);
                },
                child: Text(id == null ? "tambah" : "perbaharui"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _save(int? id) {
    if (id != null) {
      var user = userList.firstWhere((data) => data.id == id);
      setState(() {
        user.nama = nameController.text;
        user.umur = int.parse(umurController.text);
      });
    } else {
      var nextId = userList.isEmpty ? 1 : userList.last.id! + 1;
      var newUser = UserModel(
        id: nextId,
        nama: nameController.text,
        umur: int.parse(umurController.text),
      );
      setState(() {
        userList.add(newUser);
      });
    }
    Navigator.pop(context);
  }

  void _delete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("konfirmasi hapus"),
        content: const Text("apakah Anda yakin ingin menghapus data ini"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("batal"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                userList.removeWhere((data) => data.id == id);
              });
              Navigator.pop(context);
            },
            child: const Text("hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User list')),
      body: ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(userList[index].nama),
            subtitle: Text("umur ${userList[index].umur} tahun"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _form(userList[index].id),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () => _delete(userList[index].id!),
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
