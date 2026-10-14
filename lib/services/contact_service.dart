import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact_model.dart';

class ContactService {
  static const String apiUrl = 'https://jsonplaceholder.typicode.com/users';

  // GET: جلب جهات الاتصال
  Future<List<Contact>> fetchContacts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Contact.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load contacts');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // POST: إضافة جهة اتصال جديدة
  Future<Contact> addContact(Contact contact) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(contact.toJson()),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Contact.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to add contact');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // PUT: تعديل جهة اتصال
  Future<void> updateContact(int id, Contact contact) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/$id'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(contact.toJson()),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update contact');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // DELETE: حذف جهة اتصال
  Future<void> deleteContact(int id) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete contact');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}