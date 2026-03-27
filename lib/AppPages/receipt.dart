import 'package:flutter/material.dart';
import 'package:money_tracker/AppAPI/posts.dart';
import 'package:money_tracker/AppAPI/remote_services.dart';

class MyReceiptForm extends StatefulWidget {
  const MyReceiptForm({super.key});

  @override
  State<MyReceiptForm> createState() => _MyReceiptFormState();
}

class _MyReceiptFormState extends State<MyReceiptForm> {
  List<Post>? post;
  bool isLoaded = false;

  @override
  void initState(){
    super.initState();
    getData();
  }

  getData() async{
    post = await RemoteService().getPosts();
    print("Hi");
    if(post != null){
      setState(() {
        isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isLoaded,
      child: ListView.builder(
        itemCount: post?.length ?? 0,
        itemBuilder: (context, index){
          return Container(
            child: Text(post![index].title),
          );
        },
      ),

      replacement: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}