import 'package:money_tracker/AppAPI/posts.dart';
import 'package:http/http.dart' as http;

class RemoteService {
  Future<List<Post>?> getPosts() async {
    try {
      var uri = Uri.parse('https://jsonplaceholder.typicode.com/posts');

      // Adding headers often helps resolve 403 errors in emulator environments
      var response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      });

      print("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return postFromJson(response.body);
      } else {
        print("Server returned an error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception during API call: $e");
    }

    print("Returning null - API fetch failed");
    return null;
  }
}