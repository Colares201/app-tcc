import 'package:firebase_database/firebase_database.dart';
     
     class DatabaseService {
      // ignore: unused_field
      final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
     
     //create (update)
     Future <void> create({
      required String path,
      required Map<String, dynamic> data,
     }) async {
      final DatabaseReference ref = _firebaseDatabase.ref().child(path);
      await ref.set(data);
}
    // read 
    Future<DataSnapshot?> read ({required String path})async{
      final DatabaseReference ref = _firebaseDatabase.ref().child(path);
      final DataSnapshot snapshot = await  ref.get();
      return snapshot.exists? snapshot: null;
    }
    //update
    //create (update)
     Future <void> update({
      required String path,
      required Map<String, dynamic> data,
     }) async {
      final DatabaseReference ref = _firebaseDatabase.ref().child(path);
      await ref.set(data);
    }
    //delete
    Future<void> delete ({required String path})async{
      final DatabaseReference ref = _firebaseDatabase.ref().child(path);
      await ref.remove();
      }

}