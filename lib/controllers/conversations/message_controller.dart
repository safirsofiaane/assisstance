import '../../models/message.dart';
import '../../services/firestore_service.dart';

class MessageController {
  final FirestoreService _firestoreService = FirestoreService();
  final String collectionName = 'conversations';

  Future<void> addMessage(String conversationId, Message message) async {
    try {
      // Add the message to the 'messages' subcollection of the conversation
      await _firestoreService.firestore
          .collection(collectionName)
          .doc(conversationId)
          .collection('messages')
          .add(message.toJson());

      // Update the lastMessage and lastMessageTimestamp fields in the conversation document
      await _firestoreService.firestore
          .collection(collectionName)
          .doc(conversationId)
          .update({
        'lastMessage': message.content,
      });
    } catch (e) {
      print('Error adding message: $e');
    }
  }

  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _firestoreService.firestore
        .collection(collectionName)
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
      print('Error fetching messages: $error');
      // You can emit an error event here if needed (optional)
      // return Stream.error(error);
    }).map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList();
    });
  }
}
