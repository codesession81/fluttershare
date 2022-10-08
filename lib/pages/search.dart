import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController = TextEditingController();
  final CollectionReference usersRef = FirebaseFirestore.instance.collection("users");
  Future<QuerySnapshot>? searchResultsFuture;


  handleSearch(String query)async{
   Future<QuerySnapshot> users =usersRef
        .where("displayName",isGreaterThanOrEqualTo: query).get();

   setState(() {
     searchResultsFuture = users;
   });
  }

  clearSearch(){
    searchController.clear();
    setState(() {
      searchResultsFuture =null;
    });
  }

  AppBar buildSearchField(){
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
      decoration: InputDecoration(
        hintText: "Search for user...",
        filled: true,
        prefixIcon: Icon(
          Icons.account_box,
          size: 28,
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear),
          onPressed: clearSearch,
        )
      ),
        onChanged: handleSearch,
      ),
    );
  }

  Container buildNoContent(){
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset('assets/images/search.svg',height: 300,),
            Text("Find Users",textAlign: TextAlign.center,style:
            TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              fontSize: 60
            ),)
          ],
        ),
      ),
    );
  }

  buildSearchResults(){
   return FutureBuilder<QuerySnapshot>(
     future: searchResultsFuture,
     builder: (context, snapshot){
       if(!snapshot.hasData){
         return circularProgress();
       }
       List<UserResult> searchResults = [];
       snapshot.data!.docs.forEach((doc) {
         User user = User.fromDocument(doc); 
         UserResult searchResult = UserResult(user);
         searchResults.add(searchResult);
       });
       return ListView(
         children: searchResults,
       );
     },
   );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      appBar: buildSearchField(),
      body: searchResultsFuture == null? buildNoContent(): buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);

  showProfile(BuildContext context,{String? profileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Profile(profileId: profileId)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: ()=> showProfile(context,profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl!),
              ),
              title: Text(user.displayName!,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              subtitle: Text(user.username!,style: TextStyle(color:Colors.white),),
            ),
          ),
          Divider(
            height: 2,
            color: Colors.white54,
          )
        ],
      ),
    );
  }
}
