import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactService _contactService = ContactService();
  late Future<List<Contact>> _contactsFuture;

  // تعريف باليت الألوان العصرية
  static const Color primaryColor = Color(0xFF1E293B); // Slate Blue غامق راقي
  static const Color accentColor = Color(0xFF6366F1);  // Indigo عصري للزر والأيقونات
  static const Color backgroundColor = Color(0xFFF8FAFC); // خلفية فاتحة ومريحة
  static const Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    setState(() {
      _contactsFuture = _contactService.fetchContacts();
    });
  }

  void _showContactDialog({Contact? contact}) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final emailController = TextEditingController(text: contact?.email ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final isEditing = contact != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEditing ? 'تعديل جهة الاتصال' : 'إضافة جهة جديدة',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'الاسم الكامل', Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(emailController, 'البريد الإلكتروني', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildTextField(phoneController, 'رقم الهاتف', Icons.phone_outlined, keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              final newContactData = Contact(
                id: contact?.id,
                name: nameController.text,
                email: emailController.text,
                phone: phoneController.text,
              );

              try {
                if (isEditing) {
                  await _contactService.updateContact(contact.id!, newContactData);

                  // تحديث القائمة محلياً بالتعديل
                  final currentContacts = await _contactsFuture;
                  final index = currentContacts.indexWhere((c) => c.id == contact.id);
                  if (index != -1) {
                    currentContacts[index] = newContactData;
                  }
                } else {
                  // إرسال الطلب وإضافة العنصر محلياً فوراً لأجل السيرفر الوهمي
                  final addedContact = await _contactService.addContact(newContactData);
                  final currentContacts = await _contactsFuture;
                  currentContacts.insert(0, addedContact);
                }

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {}); // إعادة بناء الواجهة بالبيانات المحدثة محلياً
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: Text(isEditing ? 'تعديل' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accentColor),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 1.5)),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف جهة الاتصال هذه؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          'دفتر جهات الاتصال',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<Contact>>(
        future: _contactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ في تحميل البيانات',
                style: TextStyle(color: Colors.red.shade400, fontSize: 16),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('لا توجد جهات اتصال مضافة', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          final contacts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: Key(contact.id?.toString() ?? index.toString()),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async => await _showDeleteConfirmation(context),
                  onDismissed: (direction) async {
                    try {
                      if (contact.id != null) {
                        await _contactService.deleteContact(contact.id!);
                      }
                      setState(() {
                        contacts.removeAt(index);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم الحذف بنجاح')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: accentColor.withOpacity(0.12),
                        child: Text(
                          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      title: Text(
                        contact.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: primaryColor),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(child: Text(contact.email, style: const TextStyle(fontSize: 13, color: Colors.black54), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(contact.phone, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      onLongPress: () => _showContactDialog(contact: contact),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentColor,
        elevation: 4,
        onPressed: () => _showContactDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة جهة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}