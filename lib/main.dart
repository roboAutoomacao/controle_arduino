import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'arduino_comando.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Arduino Múltiplo',
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
  String? porta1, porta2, porta3;
  ArduinoComando? arduino1, arduino2, arduino3;
  List<Map<String, dynamic>> comandosGravados = []; // Agora gravando o tempo também

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

  void _conectar(int numero) {
    String? porta;
    if (numero == 1) porta = porta1;
    if (numero == 2) porta = porta2;
    if (numero == 3) porta = porta3;

    if (porta != null) {
      final arduino = ArduinoComando(porta);
      if (arduino.conectar()) {
        setState(() {
          if (numero == 1) arduino1 = arduino;
          if (numero == 2) arduino2 = arduino;
          if (numero == 3) arduino3 = arduino;
        });
        _mostrarMensagem('Arduino $numero conectado com sucesso!');
      } else {
        _mostrarMensagem('Erro ao conectar Arduino $numero!');
      }
    }
  }

  void _enviarParaTodos(String comando, {bool gravar = false}) async {
    if (arduino1 == null && arduino2 == null && arduino3 == null) {
      _mostrarMensagem('Nenhum Arduino conectado!');
      return;
    }

    if (arduino1 != null) {
      arduino1!.enviarComando(comando);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (arduino2 != null) {
      arduino2!.enviarComando(comando);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (arduino3 != null) {
      arduino3!.enviarComando(comando);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (gravar) {
      setState(() {
        comandosGravados.add({'comando': comando, 'tempo': 500}); // Aqui estamos gravando o tempo
      });
    }

    _mostrarMensagem('Comando "$comando" enviado para todos os Arduinos conectados.');
  }

  void _mostrarMensagem(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    }
  }

  void _executarRotina() async {
    if (comandosGravados.isEmpty) {
      _mostrarMensagem('Nenhuma rotina gravada!');
      return;
    }

    _mostrarMensagem('Executando rotina...');

    for (var item in comandosGravados) {
      final String comando = item['comando'];
      final int tempo = item['tempo'];

      _enviarParaTodos(comando, gravar: false);
      await Future.delayed(Duration(milliseconds: tempo));
    }

    _mostrarMensagem('Rotina executada com sucesso!');
  }

  void _executarRotinaViaJson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      try {
        final List<dynamic> jsonData = json.decode(content);

        _mostrarMensagem('Executando comandos do arquivo JSON...');

        for (var item in jsonData) {
          String comando = item['comando'];
          int tempo = item['tempo'];

          _enviarParaTodos(comando, gravar: false);
          await Future.delayed(Duration(milliseconds: tempo));
        }

        _mostrarMensagem('Execução via JSON concluída!');
      } catch (e) {
        _mostrarMensagem('Erro ao ler o JSON: $e');
      }
    } else {
      _mostrarMensagem('Nenhum arquivo selecionado.');
    }
  }

  // Função para excluir rotina
  void _excluirRotina() {
    setState(() {
      comandosGravados.clear(); // Limpa a lista de comandos gravados
    });

    _mostrarMensagem('Rotina excluída com sucesso!');
  }

  @override
  void dispose() {
    arduino1?.fecharPorta();
    arduino2?.fecharPorta();
    arduino3?.fecharPorta();
    super.dispose();
  }

  Widget _seletorPorta(int numero, String? portaSelecionada, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Arduino $numero', style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: portaSelecionada,
          hint: const Text('Selecione a porta COM'),
          items: portasDisponiveis.map((String porta) {
            return DropdownMenuItem(value: porta, child: Text(porta));
          }).toList(),
          onChanged: onChanged,
        ),
        ElevatedButton.icon(
          onPressed: () => _conectar(numero),
          icon: const Icon(Icons.usb),
          label: const Text('Conectar'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _botoesComando() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(onPressed: () => _enviarParaTodos('w', gravar: true), child: const Text('W (Frente)')),
        ElevatedButton(onPressed: () => _enviarParaTodos('x', gravar: true), child: const Text('X (Trás)')),
        ElevatedButton(onPressed: () => _enviarParaTodos('a', gravar: true), child: const Text('A (Esquerda)')),
        ElevatedButton(onPressed: () => _enviarParaTodos('d', gravar: true), child: const Text('D (Direita)')),
        ElevatedButton(onPressed: () => _enviarParaTodos('c', gravar: true), child: const Text('C (Cima)')),
        ElevatedButton(onPressed: () => _enviarParaTodos('b', gravar: true), child: const Text('B (Baixo)')),
        ElevatedButton(onPressed: _executarRotina, child: const Text('Executar Rotina')),
        ElevatedButton(onPressed: _excluirRotina, child: const Text('Excluir Rotina')),
        ElevatedButton(onPressed: _executarRotinaViaJson, child: const Text('Executar Rotina Via JSON')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle Arduino Múltiplo')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _seletorPorta(1, porta1, (porta) => setState(() => porta1 = porta)),
            _seletorPorta(2, porta2, (porta) => setState(() => porta2 = porta)),
            _seletorPorta(3, porta3, (porta) => setState(() => porta3 = porta)),
            const SizedBox(height: 20),
            _botoesComando(),
          ],
        ),
      ),
    );
  }
}
