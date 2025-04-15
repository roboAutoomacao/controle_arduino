import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class ArduinoComando {
  late final SerialPort _porta;

  ArduinoComando(String portaName) {
    _porta = SerialPort(portaName);
    _porta.config = SerialPortConfig()
      ..baudRate = 9600
      ..bits = 8
      ..stopBits = 1
      ..parity = SerialPortParity.none;
  }

  bool conectar() {
    return _porta.open(mode: SerialPortMode.readWrite);
  }

  void fecharPorta() {
    if (_porta.isOpen) {
      _porta.close();
    }
  }

  Future<void> executarComandos(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> comandos = jsonDecode(jsonString);

        for (var comando in comandos) {
          final String acao = comando['comando'];
          final int tempo = comando['tempo'] ?? 500;

          _porta.write(Utf8Encoder().convert(acao));
          if (kDebugMode) print('Comando enviado: $acao');
          await Future.delayed(Duration(milliseconds: tempo));
        }
      } else {
        if (kDebugMode) print('Arquivo não encontrado em: $path');
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao executar comandos: $e');
    }
  }
}
