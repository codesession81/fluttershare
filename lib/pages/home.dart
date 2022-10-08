import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

final CollectionReference usersRef = FirebaseFirestore.instance.collection("users");
final CollectionReference postRef = FirebaseFirestore.instance.collection("posts");
final CollectionReference commentsRef = FirebaseFirestore.instance.collection("comments");

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isAuth = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  late PageController _pageController;
  int pageIndex =0;
  final DateTime _timestamp = DateTime.now();
  User? currentUser;

  createUserInFirestore()async{
    final GoogleSignInAccount? user = _googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.doc(user!.id).get();
    if(!doc.exists){
      final username = await Navigator.push(context, MaterialPageRoute(builder: (context)=>CreateAccount()));
      usersRef.doc(user.id).set({
        "id":user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": _timestamp
      });
      doc = await usersRef.doc(user.id).get();
    }
    currentUser = User.fromDocument(doc);
  }



  Scaffold buildAuthScreen(){
    return Scaffold(
      body: PageView(
        children: <Widget>[
          //Timeline(),
          ElevatedButton(
            child: Text("Logout"),
            onPressed: logout,
          ),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id,currentUser: currentUser,)
        ],
        controller: _pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot),),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active),),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera,size: 35.0,),),
          BottomNavigationBarItem(icon: Icon(Icons.search),),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle),),
        ],
      ),
    );
  }

  onTap(int pageIndex){
    _pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut
    );
  }

  onPageChanged(int pageIndex){
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  login(){
    _googleSignIn.signIn();
  }

  logout(){
    _googleSignIn.signOut();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _googleSignIn.onCurrentUserChanged.listen((account) {
     handleSignIn(account!);
    },onError: (err){
      print("error signing in:$err");
    });
    _googleSignIn.signInSilently(suppressErrors: false)
    .then((account){
      handleSignIn(account!);
    }).catchError((err){
      print("error signing in:$err");
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  handleSignIn(GoogleSignInAccount account){
    if(account!=null){
      createUserInFirestore();
      setState(() {
        _isAuth = true;
      });
    }else{
      setState(() {
        _isAuth = false;
      });
    }
  }

  Scaffold buildUnAuthScreen(){
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor.withOpacity(0.8),
              Theme.of(context).primaryColor
            ]
          )
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text('FlutterShare',
            style: TextStyle(
              fontFamily: "Signatra",
              fontSize: 90.0,
              color: Colors.white
            ),
            ),
            IconButton(
              icon: Image.asset('assets/images/google_signin_button.png'),
              iconSize: 260,
              onPressed: ()=>login()
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
