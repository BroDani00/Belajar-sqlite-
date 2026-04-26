import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // Perbaikan: Cukup sqflite.dart
import 'package:path/path.dart' as p; // Perbaikan: hapus titik koma di tengah

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

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    // Perbaikan: async (bukan asaync)
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = p.join(await getDatabasesPath(), 'user_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        return db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL,
            umur INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  //create
  static Future<void> insertData(UserModel userModel) async {
    final db = await database;
    Map<String, dynamic> user = userModel.toJson();
    // Perbaikan: Urutan parameter insert adalah (table, values)
    await db.insert(
      "users",
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //read
  static Future<List<UserModel>> getData() async {
    // Perbaikan: List<UserModel>
    final db = await database;
    // Perbaikan: Query mengembalikan List Map
    List<Map<String, dynamic>> result = await db.query("users");
    // Perbaikan: Mapping data dari Map ke Model
    return result.map((data) => UserModel.fromJson(data)).toList();
  }

  //update
  static Future<int> updateData(int id, UserModel userModel) async {
    final db = await database;
    var user = userModel.toJson();
    user.remove("id"); // Pastikan ID tidak ikut diupdate di body

    return await db.update("users", user, where: "id = ?", whereArgs: [id]);
  } // Perbaikan: Tambah kurung tutup fungsi

  //delete
  static Future<int> deleteData(int id) async {
    final db = await database;
    return await db.delete("users", where: "id = ?", whereArgs: [id]);
  }
}

class UserModel {
  int? id;
  String nama;
  int umur;

  UserModel({this.id, required this.nama, required this.umur});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'], nama: json['nama'], umur: json['umur']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama': nama, 'umur': umur};
  }
}

class ListUserDataPage extends StatefulWidget {
  const ListUserDataPage({super.key});

  @override
  State<ListUserDataPage> createState() => _ListUserDataPageState();
}

class _ListUserDataPageState extends State<ListUserDataPage> {
  List<UserModel> userList = [];

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  void _reloadData() async {
    var users = await DatabaseHelper.getData();
    setState(() {
      userList = users;
    });
  }

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
                  // Perbaikan: Kirim data dari controller ke fungsi save
                  _save(
                    id,
                    nameController.text,
                    int.parse(umurController.text),
                  );
                },
                child: Text(id == null ? "tambah" : "perbaharui"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _save(int? id, String nama, int umur) async {
    // Perbaikan: Definisi newUser yang benar
    var newUser = UserModel(id: id, nama: nama, umur: umur);

    if (id != null) {
      await DatabaseHelper.updateData(id, newUser);
    } else {
      await DatabaseHelper.insertData(newUser);
    }

    _reloadData();
    Navigator.pop(context); // Perbaikan: Navigator (N besar)
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
            onPressed: () async {
              await DatabaseHelper.deleteData(id);
              _reloadData();
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
