import 'package:flutter/material.dart';
import 'ccCapocannonieri.dart';
import 'ccCalendario.dart';
import 'ccGironi.dart';
import 'ccProgramma.dart';
import 'package:flutter/services.dart';
import 'ccAggiungiSquadre.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:club/main.dart';
import 'ccIscriviSquadre.dart';
import 'ccCreazioneGironi.dart';
import 'ccCreazioneCase.dart';
import 'ccAlboDOroAnni.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CCHomePage extends StatefulWidget {
  const CCHomePage(
      {super.key,
      this.selectedIndex = 0,
      required this.club,
      this.ccRole,
      required this.email,
      required this.user,
      required this.nome});

  final int selectedIndex;
  final String? club;
  final String? ccRole;
  final bool user;
  final String email;
  final String nome;

  @override
  State<CCHomePage> createState() => _CCHomePageState();
}

class _CCHomePageState extends State<CCHomePage> {
  late List<Widget> _ccWidgetOptions;
  int _selectedIndex = 0;
  late PageController _pageController;

  // Tutor/Staff access fields
  String tutorPassword = '';
  String staffPassword = '';
  List<dynamic> clubs = [''];

  @override
  void initState() {
    super.initState();
    _retrievePw();
    _retrieveClubs();

    print("nome: ${widget.nome}");
    print("email: ${widget.email}");
    print("club: ${widget.club}");

    _ccWidgetOptions = <Widget>[
      PopScope(
        onPopInvokedWithResult: (_, result) {
          SystemNavigator.pop();
        },
        child: CCProgramma(ccRole: widget.ccRole ?? ''),
      ),
      PopScope(
        onPopInvokedWithResult: (_, result) {
          SystemNavigator.pop();
        },
        child: const CCGironi(),
      ),
      PopScope(
        onPopInvokedWithResult: (_, result) {
          SystemNavigator.pop();
        },
        child: CCCalendario(ccRole: widget.ccRole ?? '', nome: widget.nome),
      ),
      PopScope(
        onPopInvokedWithResult: (_, result) {
          SystemNavigator.pop();
        },
        child: const CCCapocannonieri(),
      ),
    ];

    _selectedIndex = widget.selectedIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _retrievePw() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('ccPassword')
        .doc('password')
        .get();
    if (snapshot.exists) {
      setState(() {
        staffPassword = snapshot['staffPw'];
        tutorPassword = snapshot['tutorPw'];
      });
    }
  }

  Future<void> _retrieveClubs() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('ccSquadre').get();
    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        clubs.add(doc['club']);
      }
    }
    setState(() {});
  }

  Future<void> _updateUser(String role) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('email', isEqualTo: widget.email)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(doc.id)
            .update({'ccRole': role});
      }
    }
  }

  void _checkPasswordTutor(String enteredPassword, String? newclub) async {
    if (newclub == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci il tuo club')),
      );
      return;
    }
    if (enteredPassword == tutorPassword) {
      await _updateUser('tutor');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cc', 'yes');
      await prefs.setString('ccRole', 'tutor');
      await prefs.setString('club', newclub ?? '');
      restartApp(
          context,
          newclub != '' ? newclub ?? '' : prefs.getString('club') ?? '',
          prefs.getString('cc') ?? '',
          'tutor',
          '');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Credenziali errate'),
        ),
      );
    }
  }

  void _checkPasswordStaff(
      String enteredPassword, String nome, String mood) async {
    if (mood == 'login') {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('ccStaff')
          .doc(nome)
          .get();
      if (snapshot.exists) {
        if (enteredPassword == staffPassword) {
          await _updateUser('staff');
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('cc', 'yes');
          await prefs.setString('ccRole', 'staff');
          await prefs.setString('nome', nome);
          await prefs.setString('club', widget.club ?? '');
          restartApp(context, prefs.getString('club') ?? '',
              prefs.getString('cc') ?? '', 'staff', nome);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Credenziali errate'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Credenziali errate'),
          ),
        );
      }
    } else {
      if (enteredPassword == staffPassword) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('ccStaff')
            .doc(nome)
            .get();
        if (snapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Esiste già un utente con questo nome')),
          );
        } else {
          await FirebaseFirestore.instance
              .collection('ccStaff')
              .doc(nome)
              .set({'nome': nome});
          await _updateUser('staff');
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('cc', 'yes');
          await prefs.setString('ccRole', 'staff');
          await prefs.setString('nome', nome);
          await prefs.setString('club', widget.club ?? '');
          restartApp(context, prefs.getString('club') ?? '',
              prefs.getString('cc') ?? '', 'staff', nome);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Credenziali errate'),
          ),
        );
      }
    }
  }

  void _showRoleSwitchSheet() {
    final tutorPasswordController = TextEditingController();
    final staffPasswordController = TextEditingController();
    final staffDataController = TextEditingController();
    bool showTutor = false;
    bool showStaff = false;
    bool isObscure = false;
    String oldclub = widget.club ?? '';
    String newclub = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF00296B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            InputDecoration getInputDecoration(String label) {
              return InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Colors.white70),
                floatingLabelStyle: const TextStyle(color: Colors.white),
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setModalState(() {
                      isObscure = !isObscure;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromARGB(255, 39, 132, 207)),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Tutor button (visible when staff is NOT selected)
                  if (!showStaff)
                    Row(children: [
                      if (showTutor)
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            setModalState(() {
                              showTutor = false;
                            });
                          },
                        ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setModalState(() {
                              showTutor = !showTutor;
                              showStaff = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            side: showTutor
                                ? const BorderSide(
                                    color: Colors.white, width: 1)
                                : BorderSide.none,
                          ),
                          child: const Text('Entra come tutor'),
                        ),
                      ),
                    ]),
                  if (showTutor) ...[
                    const SizedBox(height: 15),
                    if (oldclub == '')
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF00296B),
                        style: const TextStyle(color: Colors.white),
                        initialValue: newclub != '' ? newclub : null,
                        items: clubs.map((dynamic value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setModalState(() {
                            newclub = newValue!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Club',
                          labelStyle: const TextStyle(color: Colors.white70),
                          floatingLabelStyle:
                              const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 39, 132, 207)),
                          ),
                        ),
                      ),
                    if (oldclub == '') const SizedBox(height: 15),
                    TextField(
                      controller: tutorPasswordController,
                      decoration: getInputDecoration('Password tutor'),
                      obscureText: !isObscure,
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _checkPasswordTutor(
                            tutorPasswordController.text,
                            oldclub != '' ? oldclub : newclub,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 39, 132, 207),
                          ),
                          child: const Text('Entra'),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 10),
                  // Staff button (visible when tutor is NOT selected)
                  if (!showTutor)
                    Row(children: [
                      if (showStaff)
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            setModalState(() {
                              showStaff = false;
                            });
                          },
                        ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setModalState(() {
                              showTutor = false;
                              showStaff = !showStaff;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            side: showStaff
                                ? const BorderSide(
                                    color: Colors.white, width: 1)
                                : BorderSide.none,
                          ),
                          child: const Text('Entra come staff'),
                        ),
                      ),
                    ]),
                  if (showStaff) ...[
                    const SizedBox(height: 15),
                    TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: staffDataController,
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nome e cognome',
                        labelStyle: const TextStyle(color: Colors.white70),
                        floatingLabelStyle:
                            const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 39, 132, 207)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      obscureText: !isObscure,
                      controller: staffPasswordController,
                      decoration: getInputDecoration('Password staff'),
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _checkPasswordStaff(
                            staffPasswordController.text,
                            staffDataController.text,
                            'login',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 39, 132, 207),
                          ),
                          child: const Text('Login'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _checkPasswordStaff(
                            staffPasswordController.text,
                            staffDataController.text,
                            'registrati',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 39, 132, 207),
                          ),
                          child: const Text('Registrati'),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showConfirmDialog(bool user) async {
    if (user) {
      final bool confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Conferma'),
                content: const Text('Sei sicuro di voler passare al Club?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Annulla'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: const Text('Conferma'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          ) ??
          false;
      if (confirm) {
        _updateClub();
      }
    } else {
      final bool confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Conferma'),
                content: const Text('Sei sicuro di uscire?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Annulla'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: const Text('Conferma'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          ) ??
          false;
      if (confirm) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cc', 'no');
        await prefs.setString('club', '');
        restartApp(context, prefs.getString('club') ?? '',
            prefs.getString('cc') ?? '', 'user', '');
      }
    }
  }

  void restartApp(BuildContext context, String club, String cc, String ccRole,
      String nome) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) =>
              MyApp(club: club, cc: cc, ccRole: ccRole, nome: nome)),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _updateClub() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cc', 'no');
    restartApp(context, prefs.getString('club') ?? '',
        prefs.getString('cc') ?? '', prefs.getString('ccRole') ?? '', '');
  }

  Future<void> _creaAlbo() async {
    _showLoadingDialog();
    try {
      final firestore = FirebaseFirestore.instance;
      final int anno = DateTime.now().year;

      // 1. Load team details (logo + city/club)
      final squadreSnap = await firestore.collection('ccSquadre').get();
      final Map<String, Map<String, String>> teamDetails = {};
      for (var doc in squadreSnap.docs) {
        final data = doc.data();
        final squadre = List<Map<String, dynamic>>.from(data['squadre'] ?? []);
        for (var s in squadre) {
          teamDetails[s['squadra']] = {
            'logo': s['logo'] ?? '',
          };
        }
      }

      // 2. Get ordered teams from each knockout phase
      // Helper: get match winner and loser
      Map<String, dynamic> getMatchResult(Map<String, dynamic> matchData) {
        final casa = matchData['casa'] as String;
        final fuori = matchData['fuori'] as String;
        final marcatori =
            List<Map<String, dynamic>>.from(matchData['marcatori'] ?? []);
        int golCasa = marcatori
            .where((m) => m['cosa'] == 'gol' && m['dove'] == 'casa')
            .length;
        int golFuori = marcatori
            .where((m) => m['cosa'] == 'gol' && m['dove'] == 'fuori')
            .length;
        // If draw, whoever has penalties or keep as draw
        return {
          'casa': casa,
          'fuori': fuori,
          'golCasa': golCasa,
          'golFuori': golFuori,
          'winner': golCasa >= golFuori ? casa : fuori,
          'loser': golCasa >= golFuori ? fuori : casa,
        };
      }

      // Collect positions
      final List<Map<String, dynamic>> classifica = [];
      final Set<String> positioned = {};

      // Finali
      final finaliSnap = await firestore.collection('ccPartiteFinali').get();

      // Sort finali by codice to identify final vs 3rd place match
      final finaliDocs =
          finaliSnap.docs.where((d) => d.data()['finita'] == true).toList();
      finaliDocs.sort((a, b) =>
          (a.data()['codice'] ?? '').compareTo(b.data()['codice'] ?? ''));

      // Process all finali matches in order of codice
      // First match (lowest codice) is the final, second is 3rd place, etc.
      for (int i = 0; i < finaliDocs.length; i++) {
        final result = getMatchResult(finaliDocs[i].data());
        final winner = result['winner'] as String;
        final loser = result['loser'] as String;
        if (!positioned.contains(winner)) {
          positioned.add(winner);
          classifica.add({'squadra': winner});
        }
        if (!positioned.contains(loser)) {
          positioned.add(loser);
          classifica.add({'squadra': loser});
        }
      }

      // Semifinali losers (5th-6th or beyond what finali already covered)
      final semiSnap = await firestore.collection('ccPartiteSemifinali').get();
      final semiLosers = semiSnap.docs
          .where((d) => d.data()['finita'] == true)
          .map((d) => getMatchResult(d.data())['loser'] as String)
          .where((team) => !positioned.contains(team))
          .toList();
      for (var team in semiLosers) {
        positioned.add(team);
        classifica.add({'squadra': team});
      }

      // Quarti losers
      final quartiSnap = await firestore.collection('ccPartiteQuarti').get();
      final quartiLosers = quartiSnap.docs
          .where((d) => d.data()['finita'] == true)
          .map((d) => getMatchResult(d.data())['loser'] as String)
          .where((team) => !positioned.contains(team))
          .toList();
      for (var team in quartiLosers) {
        positioned.add(team);
        classifica.add({'squadra': team});
      }

      // Ottavi losers
      final ottaviSnap = await firestore.collection('ccPartiteOttavi').get();
      final ottaviLosers = ottaviSnap.docs
          .where((d) => d.data()['finita'] == true)
          .map((d) => getMatchResult(d.data())['loser'] as String)
          .where((team) => !positioned.contains(team))
          .toList();
      for (var team in ottaviLosers) {
        positioned.add(team);
        classifica.add({'squadra': team});
      }

      // Remaining teams from group stage (sorted by points)
      final gironiSnap = await firestore.collection('ccGironi').get();
      final List<Map<String, dynamic>> groupTeams = [];
      for (var doc in gironiSnap.docs) {
        final data = doc.data();
        final punti = Map<String, int>.from(data['punti'] ?? {});
        final diffReti = Map<String, int>.from(data['diffReti'] ?? {});
        final goalFatti = Map<String, int>.from(data['goalFatti'] ?? {});
        for (var entry in punti.entries) {
          if (!positioned.contains(entry.key)) {
            groupTeams.add({
              'squadra': entry.key,
              'punti': entry.value,
              'diffReti': diffReti[entry.key] ?? 0,
              'goalFatti': goalFatti[entry.key] ?? 0,
            });
          }
        }
      }
      groupTeams.sort((a, b) {
        int c = (b['punti'] as int).compareTo(a['punti'] as int);
        if (c != 0) return c;
        c = (b['diffReti'] as int).compareTo(a['diffReti'] as int);
        if (c != 0) return c;
        return (b['goalFatti'] as int).compareTo(a['goalFatti'] as int);
      });
      for (var team in groupTeams) {
        positioned.add(team['squadra']);
        classifica.add({'squadra': team['squadra']});
      }

      // Assign positions and add team details
      for (int i = 0; i < classifica.length; i++) {
        final name = classifica[i]['squadra'] as String;
        classifica[i]['posizione'] = i + 1;
        classifica[i]['logo'] = teamDetails[name]?['logo'] ?? '';
      }

      // 3. Capocannonieri (same logic as ccCapocannonieri)
      final collections = [
        'ccPartiteGironi',
        'ccPartiteOttavi',
        'ccPartiteQuarti',
        'ccPartiteSemifinali',
        'ccPartiteFinali',
      ];
      final Map<String, int> marcatoriMap = {};
      final Map<String, String> marcatoriSquadre = {};

      for (var collection in collections) {
        final snap = await firestore.collection(collection).get();
        for (var doc in snap.docs) {
          final data = doc.data();
          final List<dynamic> marcatoriList = data['marcatori'] ?? [];
          for (var marcatore in marcatoriList) {
            final String nome =
                (marcatore['nome'] as String).split(' ').sublist(1).join(' ');
            final String dove = marcatore['dove'];
            final String cosa = marcatore['cosa'];
            if (cosa == 'gol') {
              final String squadra =
                  dove == 'casa' ? data['casa'] : data['fuori'];
              marcatoriMap[nome] = (marcatoriMap[nome] ?? 0) + 1;
              marcatoriSquadre.putIfAbsent(nome, () => squadra);
            }
          }
        }
      }

      final sortedMarcatori = marcatoriMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final List<Map<String, dynamic>> marcatoriData = sortedMarcatori
          .map((e) => {
                'nome': e.key,
                'gol': e.value,
                'squadra': marcatoriSquadre[e.key] ?? '',
              })
          .toList();

      // 4. Save to Firestore with random ID
      await firestore.collection('ccAlboDoro').add({
        'anno': anno,
        'classifica': classifica,
        'marcatori': marcatoriData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. Update palmares (vittorie per club)
      final alboSnap = await firestore.collection('ccAlboDoro').get();
      final Map<String, int> vittorie = {};
      for (var doc in alboSnap.docs) {
        final data = doc.data();
        final List<dynamic> cls = data['classifica'] ?? [];
        for (var item in cls) {
          if (item is Map && item['posizione'] == 1) {
            final fullName = item['squadra'] as String? ?? '';
            final club = fullName.split(' ').first;
            if (club.isNotEmpty) {
              vittorie[club] = (vittorie[club] ?? 0) + 1;
            }
            break;
          }
        }
      }
      await firestore.collection('ccVittorieClub').doc('palmares').set({
        'vittorie': vittorie,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop(); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Albo d\'Oro $anno archiviato!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> _createExcelPartite() async {
    _showLoadingDialog();

    try {
      var excelFile = excel.Excel.createExcel();

      final List<Map<String, dynamic>> fasi = [
        {'nome': 'Gironi', 'collezione': 'ccPartiteGironi'},
        {'nome': 'Ottavi', 'collezione': 'ccPartiteOttavi'},
        {'nome': 'Quarti', 'collezione': 'ccPartiteQuarti'},
        {'nome': 'Semifinali', 'collezione': 'ccPartiteSemifinali'},
        {'nome': 'Finali', 'collezione': 'ccPartiteFinali'},
      ];

      for (var fase in fasi) {
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection(fase['collezione'])
            .get();
        final List<DocumentSnapshot> documents = result.docs;

        var sheet = excelFile[fase['nome']];

        sheet
            .cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
            .value = excel.TextCellValue('Casa');
        sheet
            .cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
            .value = excel.TextCellValue('Fuori');
        sheet
            .cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
            .value = excel.TextCellValue('Tipo');
        sheet
            .cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
            .value = excel.TextCellValue('Gol casa');
        sheet
            .cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0))
            .value = excel.TextCellValue('Gol fuori');

        for (var doc in documents) {
          final casa = doc['casa'];
          final fuori = doc['fuori'];
          var tipo = '';
          if (fase['nome'] == 'Gironi') {
            tipo = '${doc['tipo']} ${doc['girone']}';
          } else {
            tipo = '${doc['codice'][0]}${int.parse(doc['codice'][1]) + 1}';
          }

          int golCasa = 0;
          int golFuori = 0;
          List<Map<String, dynamic>> marcatori =
              List<Map<String, dynamic>>.from(doc['marcatori'] ?? []);
          for (var marcatore in marcatori) {
            if (marcatore['dove'] == 'casa' && marcatore['cosa'] == 'gol') {
              golCasa++;
            } else if (marcatore['dove'] == 'fuori' &&
                marcatore['cosa'] == 'gol') {
              golFuori++;
            }
          }

          sheet.appendRow([
            excel.TextCellValue(casa),
            excel.TextCellValue(fuori),
            excel.TextCellValue(tipo),
            excel.IntCellValue(golCasa),
            excel.IntCellValue(golFuori),
          ]);
        }
      }

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/partiteCC2026.xlsx");
      await file.writeAsBytes(excelFile.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('File Excel creato e condiviso con successo!')),
      );

      Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ecco il file Excel delle partite per il Champions Club 2026!',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Errore durante la creazione del file Excel: $e')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<String?> _uploadFileToFirebase(PlatformFile file) async {
    if (file.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Percorso del file non disponibile'),
        ),
      );
      return null;
    }

    try {
      final bytes = File(file.path!).readAsBytesSync();
      final storageRef =
          FirebaseStorage.instance.ref().child('giornalino/${file.name}');
      final uploadTask = storageRef.putData(bytes);
      final snapshot = await uploadTask.whenComplete(() {});

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante il caricamento del file'),
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Champions Club"),
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: widget.ccRole == 'staff'
            ? Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              )
            : null,
        actions: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CcAlboDOroAnni()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  FaIcon(FontAwesomeIcons.medal, color: Colors.white, size: 18),
                  SizedBox(height: 2),
                  Text(
                    'Albo d\'oro',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.ccRole == 'user')
            InkWell(
              onTap: _showRoleSwitchSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.account_circle, color: Colors.white, size: 20),
                    SizedBox(height: 2),
                    Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          widget.ccRole == 'tutor'
              ? InkWell(
                  onTap: () async {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CcIscriviSquadre(
                            club: widget.club ?? '',
                            ccRole: widget.ccRole ?? '')));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit, color: Colors.white, size: 20),
                        SizedBox(height: 2),
                        Text(
                          'Iscrizioni',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
          widget.ccRole != 'staff'
              ? InkWell(
                  onTap: () async {
                    await _showConfirmDialog(widget.user);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.logout_outlined,
                            color: Colors.white, size: 20),
                        SizedBox(height: 2),
                        Text(
                          'Esci',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
          if (_selectedIndex == 2 && widget.ccRole == 'staff')
            InkWell(
              onTap: () async {
                bool? confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Crea Excel'),
                    content:
                        const Text('Vuoi creare un file Excel per le partite?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Si'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _createExcelPartite();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.file_download, color: Colors.white, size: 20),
                    SizedBox(height: 2),
                    Text(
                      'Scarica',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF00296B),
          ),
        ),
      ),
      drawer: widget.ccRole == 'staff'
          ? Drawer(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.zero, topRight: Radius.zero),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color(0xFF00296B),
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                    child: Image.asset(
                      'images/logo_champions_bianco.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  widget.ccRole == 'staff'
                      ? ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Gestione squadre'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => CcAggiungiSquadre()));
                          },
                        )
                      : Container(),
                  widget.ccRole == 'staff'
                      ? ListTile(
                          leading: const Icon(Icons.table_chart_outlined),
                          title: const Text('Gestione gironi'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ccCreazioneGironi()));
                          },
                        )
                      : Container(),
                  widget.ccRole == 'staff'
                      ? ListTile(
                          leading: const Icon(Icons.home),
                          title: const Text('Gestione case'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => CcCreazioneCase()));
                          },
                        )
                      : Container(),
                  widget.ccRole == 'staff' || widget.ccRole == 'tutor'
                      ? ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Iscrivi giocatori'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => CcIscriviSquadre(
                                    club: widget.club ?? '',
                                    ccRole: widget.ccRole ?? '')));
                          },
                        )
                      : Container(),
                  widget.ccRole == 'staff'
                      ? ListTile(
                          leading: const Icon(Icons.description),
                          title: const Text('Carica giornalino'),
                          onTap: () async {
                            await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'docx', 'xlsx'],
                            ).then((result) async {
                              if (result != null) {
                                final file = result.files.first;
                                await _uploadFileToFirebase(file);
                              }
                            });
                          },
                        )
                      : Container(),
                  widget.ccRole == 'staff'
                      ? ListTile(
                          leading: const FaIcon(FontAwesomeIcons.medal,
                              color: Color.fromARGB(255, 51, 51, 51), size: 21),
                          title: const Text('Crea l\'albo d\'oro'),
                          onTap: () async {
                            Navigator.of(context).pop(); // close drawer
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Conferma'),
                                content: Text(
                                    'Creare l\'albo d\'oro ${DateTime.now().year}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Annulla'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Conferma'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _creaAlbo();
                            }
                          },
                        )
                      : Container(),
                  ListTile(
                    leading: const Icon(Icons.logout_outlined),
                    title: Text(widget.user == true ? 'Torna al Club' : 'Esci'),
                    onTap: () async {
                      await _showConfirmDialog(widget.user);
                    },
                  )
                ],
              ),
            )
          : null,
      body: PageView(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _ccWidgetOptions,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.3),
          overlayColor: WidgetStateProperty.all(
            const Color(0xFF1565C0).withValues(alpha: 0.1),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00296B),
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            );
          }),
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.white,
          elevation: 10,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF00296B)),
              label: 'Programma',
            ),
            NavigationDestination(
              icon: Icon(Icons.table_chart_outlined),
              selectedIcon: Icon(Icons.table_chart, color: Color(0xFF00296B)),
              label: 'Gironi',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon:
                  Icon(Icons.calendar_month, color: Color(0xFF00296B)),
              label: 'Calendario',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_soccer_outlined),
              selectedIcon: Icon(Icons.sports_soccer, color: Color(0xFF00296B)),
              label: 'Marcatori',
            ),
          ],
        ),
      ),
    );
  }
}
