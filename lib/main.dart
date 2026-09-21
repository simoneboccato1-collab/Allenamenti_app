import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Allenamenti',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
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
  Map<String, List<String>> esercizi = {};
  Map<String, String> pesi = {};

  bool invioInCorso = false;

  String settimana = '1';
  String giorno = 'PUSH 1';

  final TextEditingController noteController =
      TextEditingController();

  final String url =
    'https://script.google.com/macros/s/AKfycbx5wxWJC-5kRfgcdi4Bn7Y75dybw4ilppbYg554NaxAZzhqcqJVkSZkL0jFGW5FwCCe6Q/exec';
  @override
  void initState() {
    super.initState();
    caricaEsercizi();
  }

  Future<void> caricaEsercizi() async {
    try {
      final risposta = await http.get(
        Uri.parse('$url?azione=esercizi'),
      );

      print('==============================');
      print('CARICAMENTO ESERCIZI');
      print('------------------------------');
      print('STATUS GOOGLE: ${risposta.statusCode}');
      print('RISPOSTA GOOGLE: ${risposta.body}');
      print('==============================');

      if (risposta.statusCode != 200) {
        print('Errore caricamento esercizi');
        return;
      }

      final dati = jsonDecode(risposta.body);

      if (dati is! List || dati.isEmpty) {
        print('Dati esercizi non validi');
        return;
      }

      final Map<String, List<String>> nuoviEsercizi = {};

      for (int i = 1; i < dati.length; i++) {
        final riga = dati[i];

        if (riga is! List || riga.length < 3) {
          continue;
        }

        final String nomeGiorno =
            riga[0].toString().trim();

        final String nomeEsercizio = riga[1]
            .toString()
            .replaceAll('\n', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        if (nomeGiorno.isEmpty ||
            nomeEsercizio.isEmpty) {
          continue;
        }

        nuoviEsercizi.putIfAbsent(
          nomeGiorno,
          () => [],
        );

        nuoviEsercizi[nomeGiorno]!.add(
          nomeEsercizio,
        );
      }

      if (!mounted) return;

      setState(() {
        esercizi = nuoviEsercizi;

        if (!esercizi.containsKey(giorno) &&
            esercizi.isNotEmpty) {
          giorno = esercizi.keys.first;
        }
      });

      print('ESERCIZI CARICATI:');
      print(nuoviEsercizi);
    } catch (e) {
      print('Errore caricamento esercizi: $e');
    }
  }

  Future<void> inviaAGoogle() async {
    if (invioInCorso) return;

    if (!esercizi.containsKey(giorno)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nessun esercizio disponibile.',
          ),
        ),
      );
      return;
    }

    setState(() {
      invioInCorso = true;
    });

    String nota =
        '$giorno, settimana $settimana\n';

    for (final esercizio in esercizi[giorno]!) {
      final peso = pesi[esercizio] ?? '';

      if (peso.trim().isNotEmpty) {
        nota += '$esercizio ${peso.trim()}kg\n';
      }
    }

    if (noteController.text.trim().isNotEmpty) {
      nota += '\nNOTE:\n';
      nota += noteController.text.trim();
    }

    print('==============================');
    print('INVIO A GOOGLE');
    print('------------------------------');
    print(nota);
    print('==============================');

    try {
      final uri = Uri.parse(url).replace(
        queryParameters: {
          'testo_nota': nota,
        },
      );

      final risposta = await http.get(uri);

      print('RICHIESTA COMPLETATA');
      print('STATUS GOOGLE: ${risposta.statusCode}');
      print('RISPOSTA GOOGLE: ${risposta.body}');

      if (!mounted) return;

      setState(() {
        invioInCorso = false;
      });

      if (risposta.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Allenamento inviato a Google!',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore Google: ${risposta.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      print('ERRORE INVIO: $e');

      if (!mounted) return;

      setState(() {
        invioInCorso = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore invio: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listaEsercizi = esercizi[giorno] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text(
          'Allenamento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    'ALLENAMENTO',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Settimana',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: settimana,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    items: ['1', '2', '3', '4']
                        .map(
                          (numero) =>
                              DropdownMenuItem<String>(
                            value: numero,
                            child: Text(
                              'Settimana $numero',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        settimana = value;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Giorno',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: esercizi.containsKey(giorno)
                        ? giorno
                        : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    items: esercizi.keys
                        .map(
                          (nome) =>
                              DropdownMenuItem<String>(
                            value: nome,
                            child: Text(nome),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        giorno = value;
                        pesi = {};
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Esercizi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Text(
                        '${listaEsercizi.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (esercizi.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  if (listaEsercizi.isNotEmpty)
                    ...List.generate(
                      listaEsercizi.length,
                      (index) {
                        final esercizio =
                            listaEsercizi[index];

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFF5F6FA),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [

                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment:
                                      Alignment.center,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors.blue.shade50,
                                    borderRadius:
                                        BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          Colors.blue.shade700,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Text(
                                    esercizio,
                                    style:
                                        const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                SizedBox(
                                  width: 95,
                                  child: TextField(
                                    keyboardType:
                                        const TextInputType
                                            .numberWithOptions(
                                      decimal: true,
                                    ),
                                    textAlign:
                                        TextAlign.center,
                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                    decoration:
                                        InputDecoration(
                                      suffixText: 'kg',
                                      suffixStyle:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        color:
                                            Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor:
                                          Colors.white,
                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          10,
                                        ),
                                        borderSide:
                                            BorderSide(
                                          color: Colors
                                              .grey.shade300,
                                        ),
                                      ),
                                      enabledBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          10,
                                        ),
                                        borderSide:
                                            BorderSide(
                                          color: Colors
                                              .grey.shade300,
                                        ),
                                      ),
                                      focusedBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          10,
                                        ),
                                        borderSide:
                                            const BorderSide(
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      pesi[esercizio] =
                                          value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    'Note',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: noteController,
                    maxLines: 6,
                    maxLength: 500,
                    textCapitalization:
                        TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          'Esempio: buona esecuzione, aumentare il peso...',
                      filled: true,
                      fillColor:
                          const Color(0xFFF5F6FA),
                      counterStyle: const TextStyle(
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed:
                  invioInCorso
                      ? null
                      : inviaAGoogle,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                invioInCorso
                    ? 'INVIO IN CORSO...'
                    : 'SALVA ALLENAMENTO',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}