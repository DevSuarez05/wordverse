import 'package:flutter/material.dart';
import '../../../core/api_client/shest_api_client.dart';
import '../../../core/theme/wordverse_tokens.dart';
import '../components/private_room_card.dart';
import '../components/wordverse_buttons.dart';
import '../models/private_room.dart';

/// Pantalla y Módulo WordVerse Private Suites ("The Boardroom" / Salas Privadas).
class PrivateSuitesScreen extends StatefulWidget {
  const PrivateSuitesScreen({
    super.key,
    required this.apiClient,
    required this.onEnterBoardroom,
    required this.onBackToLobby,
  });

  final ShestApiClient apiClient;
  final ValueChanged<PrivateRoom> onEnterBoardroom;
  final VoidCallback onBackToLobby;

  @override
  State<PrivateSuitesScreen> createState() => _PrivateSuitesScreenState();
}

class _PrivateSuitesScreenState extends State<PrivateSuitesScreen> {
  late List<PrivateRoom> _suites;
  String? _loadingSuiteId;

  @override
  void initState() {
    super.initState();
    _suites = List<PrivateRoom>.of(widget.apiClient.privateSuites);
  }

  void _showUnlockDialog(PrivateRoom suite) {
    final TextEditingController codeCtrl = TextEditingController();
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setDlgState) {
            return AlertDialog(
              title: Row(
                children: const <Widget>[
                  Icon(Icons.lock, color: WordVerseTokens.oroLuminoso),
                  SizedBox(width: 8),
                  Text('DESBLOQUEAR SUITE'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    suite.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: WordVerseTokens.oroLuminoso,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Esta sala es privada y requiere contraseña de acceso o token criptográfico de invitación.',
                    style: TextStyle(
                      color: WordVerseTokens.grisTecnologico,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña o Token VIP',
                      errorText: errorText,
                      prefixIcon: const Icon(Icons.key, color: WordVerseTokens.oroPremium),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tip de demo: Ingresa "ALPHA2026" o token "SYNDICATE-TOKEN"',
                    style: TextStyle(
                      color: Color(0x88FFFFFF),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
                ),
                WordVersePrimaryButton(
                  label: 'VERIFICAR Y ACCEDER',
                  style: WordVerseButtonStyle.gold,
                  onPressed: () async {
                    final String val = codeCtrl.text.trim();
                    final ({bool authorized, String message, RoomRole grantedRole})
                        authRes = await widget.apiClient.authorizePrivateSuiteAccess(
                          suite: suite,
                          enteredCredential: val,
                        );

                    if (authRes.authorized) {
                      if (!mounted) return;
                      setState(() {
                        _suites = List<PrivateRoom>.of(widget.apiClient.privateSuites);
                      });
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      _executeEntry(
                        suite.copyWith(userRole: authRes.grantedRole),
                      );
                    } else {
                      setDlgState(() {
                        errorText = authRes.message;
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeEntry(PrivateRoom suite) async {
    setState(() => _loadingSuiteId = suite.id);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loadingSuiteId = null);
    widget.onEnterBoardroom(suite);
  }

  void _handleAccessRequest(PrivateRoom suite) {
    if (suite.isClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta Suite Privada ha sido cerrada por el anfitrión.'),
          backgroundColor: WordVerseTokens.rojoAlerta,
        ),
      );
      return;
    }
    if (suite.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La Suite "${suite.name}" ha alcanzado su capacidad máxima (${suite.maxCapacity}).',
          ),
          backgroundColor: WordVerseTokens.rojoAlerta,
        ),
      );
      return;
    }
    if (suite.isOwner || suite.isModerator) {
      _executeEntry(suite);
    } else {
      _showUnlockDialog(suite);
    }
  }

  void _showCreateSuiteDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();
    int capacity = 10;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setDlgState) {
            return AlertDialog(
              title: Row(
                children: const <Widget>[
                  Icon(Icons.add_moderator, color: WordVerseTokens.oroPremium),
                  SizedBox(width: 8),
                  Text('CREAR SUITE PRIVADA VIP'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Suite / Boardroom',
                        hintText: 'Ej. Boardroom Estratégico Q4',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Propósito confidencial',
                        hintText: 'Revisión de acuerdos, NDAs, balances',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña de Acceso VIP',
                        hintText: 'Dejar en blanco para acceso sólo con link',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        const Text(
                          'Capacidad VIP: ',
                          style: TextStyle(color: WordVerseTokens.grisTecnologico),
                        ),
                        Text(
                          '$capacity asientos ejecutivos',
                          style: const TextStyle(
                            color: WordVerseTokens.oroLuminoso,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: capacity.toDouble(),
                      min: 4,
                      max: 20,
                      divisions: 8,
                      activeColor: WordVerseTokens.oroPremium,
                      onChanged: (double v) =>
                          setDlgState(() => capacity = v.round()),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
                ),
                WordVersePrimaryButton(
                  label: 'CREAR SALA PRIVADA',
                  style: WordVerseButtonStyle.gold,
                  onPressed: () async {
                    final String name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                    final NavigatorState navigator = Navigator.of(ctx);
                    final PrivateRoom newSuite =
                        await widget.apiClient.createPrivateSuite(
                          ownerId: 'usr_1',
                          ownerName: 'Daniel (Tú)',
                          name: name,
                          description: descCtrl.text.trim(),
                          passcode: passCtrl.text.trim(),
                          maxCapacity: capacity,
                        );
                    if (!mounted) return;
                    setState(() {
                      _suites = List<PrivateRoom>.of(widget.apiClient.privateSuites);
                    });
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Suite VIP "${newSuite.name}" configurada (Token: ${newSuite.validTokens.first}).',
                        ),
                        backgroundColor: WordVerseTokens.oroPremium,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WordVerseTokens.negroProfundo,
      appBar: AppBar(
        backgroundColor: WordVerseTokens.negroObsidiana,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: widget.onBackToLobby,
          tooltip: 'Volver al Lobby Central',
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.security, color: WordVerseTokens.oroPremium, size: 20),
              SizedBox(width: 8),
              Text(
                'WORDVERSE PRIVATE SUITES',
                style: TextStyle(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WordVersePrimaryButton(
              label: 'NUEVA SUITE VIP',
              icon: Icons.shield,
              style: WordVerseButtonStyle.gold,
              onPressed: _showCreateSuiteDialog,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Banner de Seguridad & Conexión
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  WordVerseTokens.oroOscuro.withValues(alpha: 0.3),
                  WordVerseTokens.negroObsidiana,
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0x33D4AF37), width: 1),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.vpn_lock,
                  color: WordVerseTokens.oroLuminoso,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Text(
                        'THE BOARDROOM — AMBIENTE CONFIDENCIAL EJECUTIVO',
                        style: TextStyle(
                          color: WordVerseTokens.oroLuminoso,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Acceso restringido con cifrado punto a punto, hologramas 3D de finanzas y contratos verificados.',
                        style: TextStyle(
                          color: WordVerseTokens.grisTecnologico,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de Suites VIP
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _suites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (BuildContext context, int index) {
                final PrivateRoom suite = _suites[index];
                return PrivateRoomCard(
                  room: suite,
                  isLoading: _loadingSuiteId == suite.id,
                  onAccess: () => _handleAccessRequest(suite),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
