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
  List<String> comandosGravados = [];

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
        comandosGravados.add(comando);
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

    for (var comando in comandosGravados) {
      _enviarParaTodos(comando, gravar: false);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _mostrarMensagem('Rotina executada com sucesso!');
  }

  void _executarRotinaViaJson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      try {
        final Map<String, dynamic> jsonData = json.decode(content);

        _mostrarMensagem('Executando comandos do arquivo JSON...');

        // Aqui vamos processar cada comando com um intervalo de tempo.
        for (int i = 0; i < jsonData["1"]!.length; i++) {
          // Envia o comando para o Arduino 1
          String comando1 = jsonData["1"]![i];
          arduino1?.enviarComando(comando1);
          await Future.delayed(const Duration(milliseconds: 500));

          // Envia o comando para o Arduino 2
          String comando2 = jsonData["2"]![i];
          arduino2?.enviarComando(comando2);
          await Future.delayed(const Duration(milliseconds: 500));

          // Envia o comando para o Arduino 3
          String comando3 = jsonData["3"]![i];
          arduino3?.enviarComando(comando3);
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Após todos os comandos, enviar o comando de parada (s) para cada Arduino
        arduino1?.enviarComando('s'); // Parar o Arduino 1
        arduino2?.enviarComando('s'); // Parar o Arduino 2
        arduino3?.enviarComando('s'); // Parar o Arduino 3

        _mostrarMensagem('Execução via JSON concluída! Todos os comandos foram executados.');

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
        ElevatedButton(
          onPressed: () => _enviarParaTodos('s', gravar: true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('S (Parar)'),
        ),
      ],
    );
  }

  Widget _botoesRotinas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Executar Rotina Gravada'),
          onPressed: _executarRotina,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete),
          label: const Text('Excluir Rotina'),
          onPressed: _excluirRotina,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle de Robô')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _seletorPorta(1, porta1, (value) => setState(() => porta1 = value)),
            _seletorPorta(2, porta2, (value) => setState(() => porta2 = value)),
            _seletorPorta(3, porta3, (value) => setState(() => porta3 = value)),
            _botoesComando(),
            const SizedBox(height: 20),
            _botoesRotinas(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text('Executar Rotina Via JSON'),
              onPressed: _executarRotinaViaJson,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        ),
      ),
    );
  }
}
