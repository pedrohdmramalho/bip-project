import 'package:flutter/material.dart'; // <--- CETTE LIGNE MANQUAIT

class MeditationPage extends StatelessWidget {
  const MeditationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meditation"),
        automaticallyImplyLeading:
            false, // Cache la flèche car on est dans un onglet
        centerTitle: true,
      ),
      body: const Center(child: Text("Meditation Content")),
    );
  }
}
