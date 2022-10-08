import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:flutter/material.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes
  });

  factory Post.fromDocument(DocumentSnapshot doc){
    return Post(
        postId: doc['postId'],
        ownerId: doc['ownerId'],
        username: doc['username'],
        location: doc['location'],
        description: doc['description'],
        mediaUrl: doc['mediaUrl'],
        likes: doc['likes']
    );
  }

  int getLikeCount(likes){
    if(likes==null){
      return 0;
    }
    int count = 0;
    likes.values.forEach((val){
      if(val==true){
        count+=1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    username: this.username,
    location: this.location,
    description: this.description,
    mediaUrl: this.mediaUrl,
    likes: this.likes,
    likeCount: getLikeCount(this.likes),
  );
}

class _PostState extends State<Post> {
  final CollectionReference activityFeedRef = FirebaseFirestore.instance.collection("feed");
  User? user;
  final DateTime timestamp = DateTime.now();
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked = false;
  bool showHeart = false;

  _PostState({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes,
    required this.likeCount,
  });

  showProfile(BuildContext context,{String? profileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Profile(profileId: profileId)));
  }

  buildPostHeader(){
    return FutureBuilder(
      future: usersRef.doc(ownerId).get(),
      builder: (context,AsyncSnapshot snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        user = User.fromDocument(snapshot.data);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user!.photoUrl!),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: ()=> showProfile(context,profileId: user!.id),
            child: Text(
              user!.username!,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: IconButton(
            onPressed: ()=> print("deleting Post"),
            icon: Icon(Icons.more_vert),
          ),
        );
      },
    );
  }

  handleLikePost(){
    bool _isLiked = likes[ownerId]==true;
    if(_isLiked){
      postRef
      .doc(ownerId)
      .collection('userPosts')
      .doc(postId)
      .update({'likes.$ownerId':false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -=1;
        isLiked = false;
        likes[ownerId]=false;
      });
    }else if(!_isLiked){
      postRef
      .doc(ownerId)
      .collection('userPosts')
      .doc(postId)
      .update({'likes.$ownerId':true});
      addLikeToActivityFeed();
      setState(() {
        likeCount +=1;
        isLiked = true;
        likes[ownerId]=true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500),(){
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed(){
    bool isNotPostOwner = user!.id != widget.ownerId;
    if(isNotPostOwner){
      activityFeedRef
          .doc(ownerId)
          .collection('feedItems')
          .doc(postId)
          .set({
        "type":"like",
        "username": user!.username,
        "userId": user!.id,
        "userProfilImg": user!.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timestamp": timestamp,
      });
    }
  }

  removeLikeFromActivityFeed(){
    bool isNotPostOwner = user!.id != widget.ownerId;
    if(isNotPostOwner){
      activityFeedRef
          .doc(ownerId)
          .collection('feedItems')
          .doc(postId)
          .get().then((doc){
        if(doc.exists){
          doc.reference.delete();
        }
      });
    }
  }

  buildPostImage(){
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart?Icon(Icons.favorite,size:80,color: Colors.red):Text(""),
        ],
      ),
    );
  }

  buildPostFooter(){
    return Column(
      children: <Widget>[
        Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.only(top: 40,left: 20)),
          GestureDetector(
            onTap: handleLikePost,
            child: Icon(
              isLiked?Icons.favorite:Icons.favorite_border,
              size: 28,
              color: Colors.pink,
            ),
          ),
          Padding(padding: EdgeInsets.only(right: 20)),
          GestureDetector(
            onTap: ()=>showComments(
              context,
              postId: postId,
              ownerId: ownerId,
              mediaUrl: mediaUrl,
              username: widget.username,
            ),
            child: Icon(
              Icons.chat,
              size: 28,
              color: Colors.blue[900],
            ),
          ),
      ],
    ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "$username",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(description))
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[ownerId]==true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter()
      ],
    );
  }
}

showComments(BuildContext context,{String? postId,String? ownerId,String? mediaUrl,String? username}){
  Navigator.push(context, MaterialPageRoute(builder: (context){
    return Comments(
      postId:postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl
    );
  }));
}
