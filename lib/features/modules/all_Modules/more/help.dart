import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  final List<String> categories = ["General", "Account", "Payment", "Services"];
  int selectedCategory = 0;

  final List<Map<String, String>> faqs = [
    {
      "q": "How do I manage my notifications?",
      "a":
      "To manage notifications, go to \"Settings\", select \"Notification Settings\", and customize your preferences."
    },
    {
      "q": "How do I start a guided meditation session?",
      "a": "Open the Meditations tab and select a session."
    },
    {
      "q": "How do I join a support group?",
      "a": "Check the Community tab and select a group."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Help Center",
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "FAQ"),
              Tab(text: "Contact Us"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            _buildFAQSection(),
            _buildContactSection(),
          ],
        ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Back", style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // FAQ SECTION
  // -----------------------------
  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCategoryChips(),

          const SizedBox(height: 16),
          _buildSearchField(),

          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: faqs
                  .map((item) => _buildExpansionTile(item["q"]!, item["a"]!))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final isSelected = selectedCategory == i;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = i),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? Colors.blue : Colors.transparent),
              ),
              alignment: Alignment.center,
              child: Text(
                categories[i],
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search for help",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildExpansionTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        collapsedIconColor: Colors.black,
        iconColor: Colors.blue,
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          Text(answer, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  // -----------------------------
  // CONTACT SECTION
  // -----------------------------
  Widget _buildContactSection() {
    final List<Map<String, dynamic>> contacts = [
      {"icon": Icons.call, "title": "Customer Services"},
      {"icon": Icons.message, "title": "WhatsApp"},
      {"icon": Icons.language, "title": "Website"},
      {"icon": Icons.facebook, "title": "Facebook"},
      {"icon": Icons.alternate_email, "title": "Twitter"},
      {"icon": Icons.camera_alt, "title": "Instagram"},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(contacts[i]["icon"], size: 28),
                const SizedBox(width: 12),
                Text(
                  contacts[i]["title"],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}