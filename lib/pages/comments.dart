import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String? postId;
  final String? postOwnerId;
  final String? postMediaUrl;

  Comments({required this.postId,required this.postMediaUrl,required this.postOwnerId});

  @override
  CommentsState createState() => CommentsState();
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final CollectionReference commentsRef = FirebaseFirestore.instance.collection("comments");
  final CollectionReference activityFeedRef = FirebaseFirestore.instance.collection("feed");
  User? currentUser;
  final DateTime timestamp = DateTime.now();


  @override
  void initState() {
    super.initState();
    initCurrentUser();
  }

  Future initCurrentUser()async{
    final CollectionReference usersRef = FirebaseFirestore.instance.collection("users");
    DocumentSnapshot doc = await usersRef.doc(widget.postOwnerId).get();
    currentUser = User.fromDocument(doc);
  }

  buildComments(){
    return StreamBuilder(
      stream: commentsRef.doc(widget.postId).collection('comments').orderBy("timestamp",descending: false).snapshots(),
      builder: (context,AsyncSnapshot snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data.docs.forEach((doc){
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(children: comments);
      },
    );
  }

  addComment(){
    commentsRef.doc(widget.postId).collection("comments").add({
     "username": currentUser!.username,
     "comment": commentController.text,
     "timestamp": timestamp,
     "avatarUrl": currentUser!.photoUrl,
     "userId": currentUser!.id
    });
    bool isNotPostOwner = widget.postOwnerId!=currentUser!.id;
    if(isNotPostOwner){
      activityFeedRef
          .doc(widget.postOwnerId)
          .collection('feedItems')
          .add({
        "type":"comment",
        "username": currentUser!.username,
        "userId": currentUser!.id,
        "userProfilImg": currentUser!.photoUrl,
        "postId": widget.postId,
        "mediaUrl": widget.postMediaUrl,
        "timestamp": timestamp,
      });
    }
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: "Write a comment..."),
            ),
            trailing: TextButton(
              onPressed: addComment,
              child: Text("Post"),
            ),
          )
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    required this.timestamp,
    required this.username,
    required this.userId,
    required this.avatarUrl,
    required this.comment
  });

  factory Comment.fromDocument(DocumentSnapshot doc){
    return Comment(timestamp: doc['timestamp'], username: doc['username'], userId: doc['userId'], avatarUrl: doc['avatarUrl'], comment: doc['comment']);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(),
      ],
    );
  }
}
