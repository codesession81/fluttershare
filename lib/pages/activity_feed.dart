import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {

  final CollectionReference activityFeedRef = FirebaseFirestore.instance.collection("feed");
  final CollectionReference usersRef = FirebaseFirestore.instance.collection("users");
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? currentUser;


  @override
  void initState() {
    super.initState();
    initCurrentUser();
  }

  Future initCurrentUser()async{
    GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.doc(googleUser!.id).get();
    currentUser = User.fromDocument(doc);
  }

  getActivityFeed()async{
   QuerySnapshot snapshot= await activityFeedRef
        .doc(currentUser!.id)
        .collection('feedItems')
        .orderBy('timestamp',descending: true)
        .limit(50)
        .get();
   List<ActivityFeedItem> feedItems = [];
   snapshot.docs.forEach((doc) {
     feedItems.add(ActivityFeedItem.fromDocument(doc));
   });
   return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: header(context,titleText:"Activity Feed"),
        body: Container(
          child: FutureBuilder(
            future: getActivityFeed(),
            builder: (context,AsyncSnapshot snapshot){
              if(!snapshot.hasData){
                return circularProgress();
              }
              return ListView(children: snapshot.data);
            },
          ),
        ),
    );
  }
}

Widget? mediaPreview;
String? activityItemText;

class ActivityFeedItem extends StatelessWidget {

  final String username;
  final String userId;
  final String type;
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem({
    required this.postId,
    required this.username,
    required this.timestamp,
    required this.mediaUrl,
    required this.userId,
    required this.commentData,
    required this.type,
    required this.userProfileImg
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc){
    return ActivityFeedItem(
      username : doc['username'],
      userId : doc['userId'],
      type : doc['type'],
      mediaUrl : doc['mediaUrl'],
      postId : doc['postId'],
      userProfileImg : doc['userProfileImg'],
      commentData : doc['commentData'],
      timestamp : doc['timestamp'],
    );
  }

  showPost(context){
    Navigator.push(context, MaterialPageRoute(
        builder: (context)=>PostScreen(
            userId: userId,
            postId: postId
        )));
  }

  configureMediaPreview(context){
    if(type=="like" || type == "comment"){
      mediaPreview = GestureDetector(
        onTap: ()=>showPost(context),
        child: Container(
          height: 50,
          width: 50,
          child: AspectRatio(
            aspectRatio: 16/9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(mediaUrl),
                )
              ),
            ),
          ),
        ),
      );
    }else{
      mediaPreview = Text('');
    }
    if(type == 'like'){
      activityItemText = "liked your post";
    }else if(type == 'follow'){
      activityItemText = "is following you";
    }else if(type== 'comment'){
      activityItemText = 'replied: $commentData';
    }else{
      activityItemText = "Error: Unkown type $type";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: ()=> showProfile(context,profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black
                ),
                children: [
                  TextSpan(
                    text: username,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '$activityItemText',
                  )
                ]
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

showProfile(BuildContext context,{String? profileId}){
  Navigator.push(context, MaterialPageRoute(builder: (context)=>Profile(profileId: profileId)));
}
