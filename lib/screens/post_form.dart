import 'dart:io';

import 'package:blogapp/constant.dart';
import 'package:blogapp/models/api_response.dart';
import 'package:blogapp/models/post.dart';
import 'package:blogapp/services/post_service.dart';
import 'package:blogapp/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'login.dart';

class PostForm extends StatefulWidget {
  final Post? post;
  final String? title;

  PostForm({this.post, this.title});

  @override
  _PostFormState createState() => _PostFormState();
}

class _PostFormState extends State<PostForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _txtControllerBody = TextEditingController();
  bool _loading = false;
  File? _imageFile;
  final _picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

void _createPost() async {
  // Mendapatkan representasi string dari gambar jika ada, jika tidak, image akan bernilai null.
  String? image = _imageFile == null ? null : getStringImage(_imageFile);
  
  // Mengirimkan permintaan untuk membuat postingan baru ke server melalui API.
  ApiResponse response = await createPost(_txtControllerBody.text, image);

  // Jika tidak ada kesalahan dalam respons dari server:
  if (response.error == null) {
    // Menutup halaman saat ini setelah berhasil membuat postingan.
    Navigator.of(context).pop();
  }
  // Jika terjadi kesalahan akses tidak sah (unauthorized):
  else if (response.error == unauthorized) {
    // Melakukan logout pengguna dan memindahkan mereka ke halaman login.
    logout().then((value) => {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => Login()),
              (route) => false)
        });
  }
  // Jika terjadi kesalahan lain:
  else {
    // Menampilkan pesan kesalahan menggunakan snackbar.
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${response.error}')));
    // Mengubah status _loading menjadi false.
    setState(() {
      _loading = !_loading;
    });
  }
}

// EDIT & HAPUS POST
  void _editPost(int postId) async {
    // Memanggil fungsi editPost untuk mengirim permintaan edit ke server dengan parameter postId dan isi pesan yang baru.
    ApiResponse response = await editPost(postId, _txtControllerBody.text);
    // Memeriksa apakah tidak terjadi kesalahan selama permintaan.
    if (response.error == null) {
      // Jika tidak ada kesalahan, kembali ke halaman sebelumnya.
      Navigator.of(context).pop();
    }
    // Memeriksa apakah kesalahan yang terjadi adalah 'unauthorized' (tidak diotorisasi).
    else if (response.error == unauthorized) {
      // Jika kesalahan adalah 'unauthorized', maka lakukan logout dan navigasi ke halaman login.
      logout().then((value) => {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => Login()),
                (route) => false)
          });
    }
    // Jika terjadi kesalahan selain 'unauthorized'.
    else {
      // Tampilkan pesan kesalahan dengan Snackbar.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${response.error}')));
      // Setel status _loading menjadi false.
      setState(() {
        _loading = !_loading;
      });
    }
  }

  @override
  void initState() {
    if (widget.post != null) {
      _txtControllerBody.text = widget.post!.body ?? '';
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title}'),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              children: [
                widget.post != null
                    ? SizedBox()
                    : Container(
                        width: MediaQuery.of(context).size.width,
                        height: 200,
                        decoration: BoxDecoration(
                            image: _imageFile == null
                                ? null
                                : DecorationImage(
                                    image: FileImage(_imageFile ?? File('')),
                                    fit: BoxFit.cover)),
                        child: Center(
                          child: IconButton(
                            icon: Icon(Icons.image,
                                size: 50, color: Colors.black38),
                            onPressed: () {
                              getImage();
                            },
                          ),
                        ),
                      ),
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: TextFormField(
                      controller: _txtControllerBody,
                      keyboardType: TextInputType.multiline,
                      maxLines: 9,
                      validator: (val) =>
                          val!.isEmpty ? 'Post body is required' : null,
                      decoration: InputDecoration(
                          hintText: "Post body...",
                          border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1, color: Colors.black38))),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: kTextButton('Post', () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _loading = !_loading;
                      });
                      if (widget.post == null) {
                        _createPost();
                      } else {
                        _editPost(widget.post!.id ?? 0);
                      }
                    }
                  }),
                )
              ],
            ),
    );
  }
}
