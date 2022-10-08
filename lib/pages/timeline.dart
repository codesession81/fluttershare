import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';

final CollectionReference usersRef = FirebaseFirestore.instance.collection("users");

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {

  @override
  void initState(){
    super.initState();
    //getUserById();
    //createUser();
    //updateUser();
    //deleteUser();
  }

 /* createUser(){
    usersRef.doc("12345").set({
      "username": "Tanja",
      "postsCount": 8,
      "isAdmin": false
    });
  }

  updateUser()async{
    final doc = await usersRef.doc("12345").get();
    if(doc.exists){
      doc.reference.update({
        "postsCount": 1,
      });
    }
  }

  deleteUser()async{
    final DocumentSnapshot doc = await usersRef.doc("12345").get();
    if(doc.exists){
      doc.reference.delete();
    }
  }*/

  /*getUserById()async{
   DocumentSnapshot documentSnapshot=await usersRef.doc("9oOLAqcDdCbTJy0XqDL5").get();
   print(documentSnapshot.data());
  }*/
/*
  getUsers()async{
    //final QuerySnapshot querySnapshot = await usersRef.get();

   final QuerySnapshot collectionReference = await usersRef
        .where("postsCount", isLessThan: 10)
        .get();
    collectionReference.docs.forEach((element) {
      print(element.data());
    });

    usersRef.get().then((QuerySnapshot collectionSnapshot){
      collectionSnapshot.docs.forEach((DocumentSnapshot doc) {
        print(doc.data());
        print(doc.id);
      });
    });
  }
*/
 /* Future<void>getUserById()async{
    DocumentSnapshot documentSnapshot = await usersRef.doc("9oOLAqcDdCbTJy0XqDL5").get();
    print(documentSnapshot.data());
  }*/

  /*getAllUsers()async{
    QuerySnapshot querySnapshot = await usersRef.get();
    querySnapshot.docs.forEach((DocumentSnapshot documentSnapshot) {
      print(documentSnapshot.data());
    });
  }*/



  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context,isAppTitle: true, titleText: ''),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder:(context,snapshot){
         if(!snapshot.hasData){
           return circularProgress();
         }else{
          List<Text> children= snapshot.data!.docs.map((doc) => Text(doc['postsCount'].toString())).toList();
          return Container(
             child: ListView(
              children: children
             ),
           );
         }
        } ,
      )
    );
  }

}
