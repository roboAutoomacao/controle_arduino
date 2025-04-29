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

  void enviarComando(String comando) {
    if (_porta.isOpen) {
      final Uint8List dados = Uint8List.fromList(utf8.encode(comando));
      _porta.write(dados);
      if (kDebugMode) {
        print('Comando enviado: $comando');
      }
    } else {
      if (kDebugMode) {
        print('Erro: Porta não está aberta para enviar comando!');
      }
    }
  }

  Future<void> executarComandos(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final dynamic decoded = jsonDecode(jsonString);

        if (decoded is List) {
          for (var item in decoded) {
            final String comando = item['comando'] ?? '';
            final int tempo = item['tempo'] ?? 500;

            if (comando.isNotEmpty) {
              // Envia o comando específico para o Arduino
              enviarComando(comando);
              await Future.delayed(Duration(milliseconds: tempo));
            }
          }
        } else {
          if (kDebugMode) print('JSON inválido: esperado uma lista de comandos.');
        }
      } else {
        if (kDebugMode) print('Arquivo não encontrado em: $path');
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao executar comandos: $e');
    }
  }
}
