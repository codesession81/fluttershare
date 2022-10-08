import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {

  final String? profileId;
  final User? currentUser;
  Profile({required this.profileId,this.currentUser});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  final CollectionReference postRef = FirebaseFirestore.instance.collection("posts");
  final CollectionReference followersRef = FirebaseFirestore.instance.collection("followers");
  final CollectionReference followingRef = FirebaseFirestore.instance.collection("following");
  final CollectionReference activityFeedRef = FirebaseFirestore.instance.collection("feed");
  final DateTime _timestamp = DateTime.now();
  String postOrientation = "grid";
  bool isLoading = false;
  int postCount =0;
  int followerCount=0;
  int followingCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  getFollowing()async{
    QuerySnapshot snapshot = await followingRef
        .doc(widget.profileId)
        .collection('userFollowing')
        .get();
    setState(() {
      followingCount = snapshot.docs.length;
    });
  }

  checkIfFollowing()async{
    DocumentSnapshot doc = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(widget.currentUser!.id)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers()async{
    QuerySnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .get();
    setState(() {
        followerCount = snapshot.docs.length;
    });
  }

  getProfilePosts()async{
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot= await postRef
      .doc(widget.profileId)
      .collection('userPosts')
      .orderBy('timestamp',descending: true)
      .get();
    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  editProfile(){
    Navigator.push(context,MaterialPageRoute(builder: (context)=>
        EditProfile(currentUserId: widget.currentUser!.id!)));
  }

  buildProfileButton(){
   bool isProfilOwner = widget.currentUser?.id == widget.profileId;
   if(isProfilOwner){
     return buildButton(
      text: "Edit Profile",
      function: editProfile
     );
   }else if(isFollowing){
     return buildButton(text: "Unfollow",function: handleUnfollowUser);
   }else if(!isFollowing){
     return buildButton(text: "Follow",function: handleFollowUser);
   }
  }

  handleFollowUser(){
    setState(() {
      isFollowing = true;
    });
    followersRef
    .doc(widget.profileId)
    .collection('userFollowers')
    .doc(widget.currentUser!.id)
    .set({});

    followingRef
    .doc(widget.currentUser!.id)
    .collection('userFollowing')
    .doc(widget.profileId)
    .set({});

    activityFeedRef
    .doc(widget.profileId)
    .collection('feedItems')
    .doc(widget.currentUser!.id)
    .set({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": widget.currentUser!.username,
      "userId": widget.currentUser!.id,
      "userProfileImg": widget.currentUser!.photoUrl,
      "timestamp": _timestamp,
    });
  }

  handleUnfollowUser(){
    setState(() {
      isFollowing = false;
    });
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(widget.currentUser!.id)
        .get().then((doc) {
          if(doc.exists){
            doc.reference.delete();
          }
    });

    followingRef
        .doc(widget.currentUser!.id)
        .collection('userFollowing')
        .doc(widget.profileId)
        .get().then((doc){
          if(doc.exists){
            doc.reference.delete();
          }
    });

    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(widget.currentUser!.id)
        .set({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": widget.currentUser!.username,
      "userId": widget.currentUser!.id,
      "userProfileImg": widget.currentUser!.photoUrl,
      "timestamp": _timestamp,
    });
  }

  Container buildButton({String? text,required Function function}){
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: TextButton(
        onPressed:()=> function(),
        child: Container(
          width: 250,
          height: 27,
          child: Text(
            text!,
            style: TextStyle(
              color:isFollowing ? Colors.black: Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:isFollowing? Colors.white: Colors.blue,
            border: Border.all(
              color: isFollowing? Colors.grey:Colors.blue
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  Widget buildCountColumn(String label,int count){
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w400
            ),
          ),
        ),
      ],
    );
  }

  buildProfilHeader(){
    return FutureBuilder(
      future: usersRef.doc(widget.profileId).get(),
      builder: (context,AsyncSnapshot snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl!),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts",postCount),
                            buildCountColumn("followers",followerCount),
                            buildCountColumn("following",followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton()
                          ],
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                              user.username!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                              ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            user.displayName!,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                         alignment: Alignment.centerLeft,
                         padding: EdgeInsets.only(top: 2),
                         child: Text(
                           user.bio!
                         ),
                        )
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts(){
    if(isLoading){
      return circularProgress();
    }else if(posts.isEmpty){
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset('assets/images/no_content.svg', height: 260),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                  "No Posts",
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 40,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
          ],
        ),
      );
    }else if(postOrientation == "grid"){
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    }else if(postOrientation == "list"){
      return Column(children: posts);
    }
  }

  setPostOrientation(String postOrientation){
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTooglePostOrientation(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: ()=>setPostOrientation("grid"),
            icon: Icon(Icons.grid_on),
            color:postOrientation =='grid'?Theme.of(context).primaryColor:Colors.grey,
        ),
        IconButton(
          onPressed: ()=>setPostOrientation("list"),
          icon: Icon(Icons.list),
          color:postOrientation =='list'?Theme.of(context).primaryColor:Colors.grey,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,titleText: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfilHeader(),
          Divider(),
          buildTooglePostOrientation(),
          Divider(height: 0),
          buildProfilePosts(),
        ],
      )
    );
  }


}
