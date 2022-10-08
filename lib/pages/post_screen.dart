import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/post.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';

class PostScreen extends StatelessWidget {

  final String userId;
  final String postId;
  PostScreen({required this.userId,required this.postId});

  final CollectionReference postRef = FirebaseFirestore.instance.collection("posts");

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postRef.doc(userId).collection('userPosts').doc(postId).get(),
      builder: (context,AsyncSnapshot snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        Post post = Post.fromDocument(snapshot.data);
        return Center(
          child: Scaffold(
            appBar: header(context,titleText:post.description),
            body: ListView(
              children: <Widget>[
                Container(
                  child:Text(post.username),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
