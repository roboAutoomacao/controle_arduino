import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:file_picker/file_picker.dart';

import 'arduino_comando.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Arduino',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> portasDisponiveis = [];
  String? portaSelecionada;
  String? caminhoArquivo;
  ArduinoComando? arduino;

  @override
  void initState() {
    super.initState();
    _carregarPortas();
  }

  void _carregarPortas() {
    setState(() {
      portasDisponiveis = SerialPort.availablePorts;
    });
  }

  void _conectar() {
    if (portaSelecionada != null) {
      arduino = ArduinoComando(portaSelecionada!);
      if (arduino!.conectar()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conectado ao Arduino!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao conectar!')),
        );
      }
    }
  }

  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        caminhoArquivo = result.files.single.path;
      });
    }
  }

  Future<void> _executar() async {
    if (arduino != null && caminhoArquivo != null) {
      await arduino!.executarComandos(caminhoArquivo!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a porta e o arquivo JSON primeiro.')),
      );
    }
  }

  @override
  void dispose() {
    arduino?.fecharPorta();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle Arduino')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: portaSelecionada,
              hint: const Text('Selecione a porta COM'),
              items: portasDisponiveis.map((String porta) {
                return DropdownMenuItem(value: porta, child: Text(porta));
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  portaSelecionada = value;
                });
              },
            ),
            ElevatedButton.icon(
              onPressed: _conectar,
              icon: const Icon(Icons.usb),
              label: const Text('Conectar'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _selecionarArquivo,
              icon: const Icon(Icons.folder_open),
              label: const Text('Selecionar arquivo JSON'),
            ),
            if (caminhoArquivo != null)
              Text(
                'Arquivo: ${caminhoArquivo!.split('/').last}',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _executar,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Executar comandos'),
            ),
          ],
        ),
      ),
    );
  }
}
