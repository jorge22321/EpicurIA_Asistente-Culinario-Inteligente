///lib/test_ai_page.dart

import 'package:flutter/material.dart';
import 'services/clarifai_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TestAIPage extends StatefulWidget {
  const TestAIPage({super.key});

  @override
  State<TestAIPage> createState() => _TestAIPageState();
}

class _TestAIPageState extends State<TestAIPage> {
  final TextEditingController _controller = TextEditingController();

  String respuesta = "";
  bool cargando = false;

  File? _imagen;
  final ImagePicker _picker = ImagePicker();

  Future<void> enviar() async {
    if (_controller.text.isEmpty && _imagen == null) return;

    setState(() {
      cargando = true;
      respuesta = "";
    });

    String res;

    if (_imagen != null) {
      res = await ClarifaiService.enviarImagen(_imagen!);
    } else {
      res = await ClarifaiService.enviarMensaje(_controller.text);
    }

    setState(() {
      respuesta = res;
      cargando = false;
    });
  }

  Future<void> tomarFoto() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);

    if (foto != null) {
      setState(() {
        _imagen = File(foto.path);
        _controller.text = "Analiza esta imagen";
      });
    }
  }

  Future<void> seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() {
        _imagen = File(imagen.path);
        _controller.text = "Analiza esta imagen";
      });
    }
  }

  void limpiar() {
    setState(() {
      _imagen = null;
      _controller.clear();
      respuesta = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test IA "),
        actions: [
          IconButton(
            onPressed: limpiar,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Ej: receta con pollo",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: enviar,
                    child: const Text("Enviar"),
                  ),
                ),
                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: tomarFoto,
                  child: const Icon(Icons.camera_alt),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: seleccionarImagen,
                  child: const Icon(Icons.image),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_imagen != null)
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                child: Image.file(_imagen!),
              ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: cargando
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  child: Text(
                    respuesta.isEmpty
                        ? " IA CHAMBEANDO..."
                        : respuesta,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}