import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:starteu/data/widgets/animated_cart.dart';
import 'package:starteu/pages/create_ad_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
    // int _counter = 0;

  void _incrementCounter() {
    /**
     * 
    setState(() {
      _counter++;
    });
     */
    Navigator.of(
      context
    ).push(MaterialPageRoute(builder: (_)=> const CreateAdPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('project_ads')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }

      final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Brak ogłoszeń'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return AnimatedAdCard(
                index: index,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(data['title'] ?? ''),
                    subtitle: Text(data['description'] ?? ''),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
