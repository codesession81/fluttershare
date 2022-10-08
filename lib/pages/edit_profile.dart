import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:google_sign_in/google_sign_in.dart';

class EditProfile extends StatefulWidget {

  final String currentUserId;
  EditProfile({required this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  bool isLoading = false;
  User? user;
  bool _displayNameValid = true;
  bool _bioValid = true;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser()async{
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.doc(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user!.displayName!;
    bioController.text = user!.bio!;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField(){
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text("Display Name"
          ,style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "Update Display Name",
            errorText: _displayNameValid ? null:"Display Name too short",
          ),
        )
      ],
    );
  }

  Column buildBioField(){
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text("Bio"
            ,style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update Bio",
            errorText: _bioValid ? null:"Bio too long or empty",
          ),
        )
      ],
    );
  }

  updateProfilData(){
    setState(() {
      displayNameController.text.trim().length<3 ||
      displayNameController.text.isEmpty? _displayNameValid = false : _displayNameValid = true;
      bioController.text.trim().length>100 || bioController.text.isEmpty ? _bioValid = false: _bioValid = true;
    });
    if(_displayNameValid && _bioValid){
      usersRef.doc(widget.currentUserId).update({
        "displayName": displayNameController.text,
        "bio": bioController.text
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: ()=> Navigator.pop(context),
            icon: Icon(
              Icons.done,
              size: 30,
              color: Colors.green,
            ),
          )
        ],
      ),
      body: isLoading? circularProgress():ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 16,bottom: 8),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: CachedNetworkImageProvider(user!.photoUrl!),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      buildDisplayNameField(),
                      buildBioField()
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: updateProfilData,
                  child: Text(
                    "Update Profile",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextButton.icon(
                      onPressed: logout,
                      icon: Icon(Icons.cancel,color: Colors.red),
                      label: Text(
                        "Logout",
                        style: TextStyle(color: Colors.red,fontSize: 20),
                      )
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  logout()async{
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
  }

}
