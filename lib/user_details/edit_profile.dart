import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:inofa/api/api.dart';
import 'package:inofa/custom/datePicker.dart';
import 'package:inofa/models/loginUser_models.dart';
import 'package:inofa/models/pendidikan_models.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfil extends StatefulWidget {
  @override
  _EditProfilState createState() => _EditProfilState();
}

class _EditProfilState extends State<EditProfil> {
  LoginUser _loginUser = null;
  var loading = false;
  final _key = new GlobalKey<FormState>();
  String display_name, no_telp, website, short_desc, txtTglLahir, pendidikan;
  TextEditingController txtDisplayName, txtNoTelp, txtWebsite, txtShortDesc;
  final FocusNode _nodeNumber = FocusNode();
  List <ListPendidikan> _listPendidikan = [];
  File _profile_picture;
  static String tokenUser ='';
  Map<String, String> headers;

  Future<String> _getListPendidikan() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var response = await http.get(Uri.encodeFull(BaseUrl.listPendidikan), 
    headers: {
      'Authorization': 'Bearer '+ token,
    });
    var data = json.decode(response.body);

    setState(() {
      for(Map i in data){
        _listPendidikan.add(ListPendidikan.fromJson(i));
        loading=false;
      }
    });
  }

  _pilihGallery() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxHeight: 1920.0, maxWidth: 1080.0);
    setState(() {
      _profile_picture = image;
    });
  }

  updateData()async{
    setState(() {
      loading = true;
    });
    _loginUser = await LoginUser.getDataUser();
    if(mounted) setState(() {
      tokenUser = _loginUser.user.token;
      headers = {'Authorization': 'Bearer '+tokenUser};
    });
    setState(() {
      setup();
      loading=false;
    });
  }

  @override
  void initState() {
    super.initState();
    updateData();
    _getListPendidikan();
  }

  setup(){
    setState(() {
      loading = true;
    });
    pendidikan = _loginUser.user.id_pendidikan.toString();
    txtTglLahir = _loginUser.user.tgl_lahir;
    txtDisplayName = TextEditingController(text: _loginUser.user.display_name);
    txtWebsite = TextEditingController(text: _loginUser.user.website);
    txtNoTelp = TextEditingController(text: _loginUser.user.no_telp);
    txtShortDesc = TextEditingController(text: _loginUser.user.short_desc);
    loading = false;
  }

  String pilihTanggal, labelTanggal;
  var formatTgl = new DateFormat('yyy-MM-dd');
  DateTime tgl =  DateTime.now();
  final TextStyle valueStyle = TextStyle(fontSize: 16.0);
  Future<Null> _selectedDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context, 
      initialDate: tgl, 
      firstDate: DateTime(1901), 
      lastDate: DateTime(2199)
    );

    if(picked != null && picked != tgl){
      setState(() {
        tgl = picked;
        txtTglLahir = formatTgl.format(tgl);
      });
    }
  }

  check(){
    final form = _key.currentState;
    if (form.validate()){
      form.save();
      submit();
    } else{
      showToast("Silakan lengkapi profil anda", Colors.red);
    }
  }

  submit() async{
    try {
      var url = Uri.parse(BaseUrl.updateUser + _loginUser.user.email.toString());
      var request = http.MultipartRequest("POST", url);
      request.headers.addAll(headers);
      request.fields['display_name']=display_name;
      request.fields['pendidikan']=pendidikan;
      request.fields['tgl_lahir']="$txtTglLahir";
      request.fields['website']=website;
      request.fields['no_telp']=no_telp;
      request.fields['short_desc']=short_desc;

      var response = await request.send();
      if (response.statusCode > 2) {
        print("profile diperbarui");
        Navigator.pushReplacementNamed(context, '/CurrentTab');
      } else {
        print("gagal memperbaharui profile");
      }
    } catch(e){
      debugPrint("Error $e");
    }
  }

  void showToast(message, Color color) {
    print(message);
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 4,
        title: Text('Edit Profil', style: TextStyle(
          color: Colors.black,
          ),
        ),
      ),
      
      body: _loginUser == null? 
      Center(
        child: CircularProgressIndicator(),
      ):
      Container(
        padding: EdgeInsets.only(left: 24, right: 24, top: 15, bottom: 5),
        child: Form(
          key: _key,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: txtDisplayName,
                onSaved: (e) => display_name = e,
                decoration: InputDecoration(labelText: 'Nama'),
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                autofocus: false,
                focusNode: _nodeNumber,
                controller: txtNoTelp,
                onSaved: (e) => no_telp = e,
                decoration: InputDecoration(labelText: 'No Hp'),
              ),
              TextFormField(
                controller: txtWebsite,
                onSaved: (e) => website = e,
                decoration: InputDecoration(labelText: 'Website'),
              ),
              TextFormField(
                maxLines: 8,
                controller: txtShortDesc,
                onSaved: (e) => short_desc = e,
                decoration: InputDecoration(labelText: 'Short Desc'),
              ),
              SizedBox(height:15),
              Text('Pendidikan', style: TextStyle(fontSize: 15, color: Colors.black),),
              Container(
                child: DropdownButton(
                  isExpanded: true,
                  items: _listPendidikan.map((pendidikans){
                    return new DropdownMenuItem(
                      child: new Text(pendidikans.pendidikan.toString()),
                      value: pendidikans.id_Pendidikan.toString(),
                    );
                  }).toList(),
                  onChanged: (newVal){
                    setState(() {
                      pendidikan = newVal;
                      print(pendidikan);
                    });
                  },
                  hint: Text(_loginUser.user.pendidikan == null? 'Pendidikan': _loginUser.user.pendidikan.toString()),
                  value: pendidikan,
                ),
              ),
              SizedBox(height:15),
              Text('Tanggal Lahir', style: TextStyle(fontSize: 15, color: Colors.black),),
              DateDropDown(
                labelText: labelTanggal,
                valueText: _loginUser.user.tgl_lahir ==null? formatTgl.format(tgl) : txtTglLahir,
                valueStyle: valueStyle,
                onPressed: (){
                  _selectedDate(context);
                },
              ),

              SizedBox(height:25),
              Center(
                child: Container(
                  width: 300,
                  height: 45,
                  child: RaisedButton(
                    shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(8.0),
                      side: BorderSide(color: Color(0xff2968E2))),
                    onPressed: () {
                      check();
                    },
                    color: Color(0xff2968E2),
                    textColor: Colors.black,
                    child: Text("Simpan".toUpperCase(),
                      style: TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ),
              ),
            ],
          )
        )
      )
    );
  }
}