import 'package:flutter/material.dart';
import '../tema/estilos_calculadora.dart';

class TarjetaEsperaCalculadora extends StatelessWidget {
  const TarjetaEsperaCalculadora({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: EstilosCalculadora.decoracionTarjeta(context),
      padding: const EdgeInsets.all(16),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: EstilosCalculadora.textoSecundario(context),
        ),
      ),
    );
  }
}
