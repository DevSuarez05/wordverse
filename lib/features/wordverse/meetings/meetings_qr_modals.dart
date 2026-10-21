import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/models/shest_models.dart';

/// Modales de Reuniones (`WV-45821`) y Sistema QR de Shest (Fases 9, 10, 11, 24, 28).
class MeetingsAndQrModals {
  /// Abre el gestor de Reuniones: permite crear una nueva reunión (Fase 9)
  /// y ver el QR de cualquier reunión activa (Fase 10).
  static Future<void> showMeetingsSheet({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return _MeetingsManagerSheet(
          apiClient: apiClient,
          currentUser: currentUser,
        );
      },
    );
  }

  /// Abre el centro QR de WordVerse (Fases 10, 11, 17, 24, 28):
  /// - Mi QR Personal (Tarjeta Digital)
  /// - Validar / Escanear QR o Código de Invitación (ej. `WV-45821` o `#45821`)
  static Future<void> showQrCenterSheet({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
    String initialCodeToValidate = 'WV-45821',
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return _QrCenterSheet(
          apiClient: apiClient,
          currentUser: currentUser,
          initialCode: initialCodeToValidate,
        );
      },
    );
  }
}

class _MeetingsManagerSheet extends StatefulWidget {
  const _MeetingsManagerSheet({
    required this.apiClient,
    required this.currentUser,
  });

  final ShestApiClient apiClient;
  final ShestUser currentUser;

  @override
  State<_MeetingsManagerSheet> createState() => _MeetingsManagerSheetState();
}

class _MeetingsManagerSheetState extends State<_MeetingsManagerSheet> {
  final TextEditingController _nameCtrl = TextEditingController(
    text: 'Acuerdo Comercial USDT TRC20',
  );
  final TextEditingController _descCtrl = TextEditingController(
    text: 'Definición de términos de entrega y liberación de Escrow.',
  );
  MeetingType _selectedType = MeetingType.negocios;
  bool _isPrivate = false;
  int _durationMinutes = 45;
  List<WordverseMeeting> _meetings = <WordverseMeeting>[];
  WordverseMeeting? _selectedQrMeeting;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    try {
      final List<WordverseMeeting> list =
          await widget.apiClient.qr.listMeetings();
      if (!mounted) return;
      setState(() {
        _meetings = list;
        _selectedQrMeeting ??= list.isNotEmpty ? list.first : null;
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() => _feedback = e.userMessage);
    }
  }

  Future<void> _createMeeting() async {
    try {
      final WordverseMeeting created = await widget.apiClient.qr.createMeeting(
        creatorId: widget.currentUser.id,
        name: _nameCtrl.text.trim().isEmpty
            ? 'Reunión WordVerse'
            : _nameCtrl.text.trim(),
        type: _selectedType,
        description: _descCtrl.text.trim(),
        isPrivate: _isPrivate,
        durationMinutes: _durationMinutes,
      );
      await _loadMeetings();
      if (!mounted) return;
      setState(() {
        _selectedQrMeeting = created;
        _feedback =
            'Reunión ${created.code} creada en Shest con QR listo para compartir.';
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() => _feedback = e.userMessage);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'CREAR REUNIÓN & QR (Fases 9-10, 28)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            if (_feedback != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent),
                ),
                child: Text(
                  _feedback!,
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                ),
              ),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre de la reunión',
                labelStyle: TextStyle(color: Colors.white70),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<MeetingType>(
                    initialValue: _selectedType,
                    dropdownColor: const Color(0xFF162238),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tipo (Fase 9)',
                      labelStyle: TextStyle(color: Colors.white70),
                      isDense: true,
                    ),
                    items: MeetingType.values
                        .map(
                          (MeetingType t) => DropdownMenuItem<MeetingType>(
                            value: t,
                            child: Text(t.label),
                          ),
                        )
                        .toList(),
                    onChanged: (MeetingType? val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Privada',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    value: _isPrivate,
                    onChanged: (bool val) => setState(() => _isPrivate = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Descripción / Agenda',
                labelStyle: TextStyle(color: Colors.white70),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Text(
                  'Duración:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('30 min'),
                  selected: _durationMinutes == 30,
                  onSelected: (_) => setState(() => _durationMinutes = 30),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('45 min'),
                  selected: _durationMinutes == 45,
                  onSelected: (_) => setState(() => _durationMinutes = 45),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('60 min'),
                  selected: _durationMinutes == 60,
                  onSelected: (_) => setState(() => _durationMinutes = 60),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  key: const Key('btn_submit_create_meeting'),
                  onPressed: _createMeeting,
                  icon: const Icon(Icons.add_business, size: 16),
                  label: const Text('Crear Reunión'),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 22),
            const Text(
              'Reuniones Activas y QR de Invitación:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            for (final WordverseMeeting m in _meetings)
              Card(
                color: const Color(0xFF172542),
                child: ListTile(
                  dense: true,
                  title: Text(
                    '${m.code} — ${m.name}',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Tipo: ${m.type.label} • Creador: ${m.creatorName} • ${m.isPrivate ? "Privada" : "Pública"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  trailing: TextButton.icon(
                    onPressed: () => setState(() => _selectedQrMeeting = m),
                    icon: const Icon(Icons.qr_code, color: Colors.cyanAccent),
                    label: const Text('Ver QR'),
                  ),
                ),
              ),
            if (_selectedQrMeeting != null) ...<Widget>[
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      QrImageView(
                        data: _selectedQrMeeting!.qrPayload,
                        size: 130,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reunión WordVerse • Código: ${_selectedQrMeeting!.code}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QrCenterSheet extends StatefulWidget {
  const _QrCenterSheet({
    required this.apiClient,
    required this.currentUser,
    required this.initialCode,
  });

  final ShestApiClient apiClient;
  final ShestUser currentUser;
  final String initialCode;

  @override
  State<_QrCenterSheet> createState() => _QrCenterSheetState();
}

class _QrCenterSheetState extends State<_QrCenterSheet> {
  late final TextEditingController _scanCtrl;
  String? _validationResult;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _scanCtrl = TextEditingController(text: widget.initialCode);
  }

  Future<void> _validateCode() async {
    try {
      final Map<String, Object?> res =
          await widget.apiClient.qr.validateAndResolveQr(
            qrOrCode: _scanCtrl.text,
            scannerUserId: widget.currentUser.id,
          );
      if (!mounted) return;
      setState(() {
        _isError = false;
        _validationResult = res['message'] as String?;
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _validationResult = e.userMessage;
      });
    }
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'CENTRO QR SHEST (Reunión / Escrow / Perfil)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const Text(
              '1. Entrada por QR o Código de Invitación (Fases 11, 24, 28):',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('input_qr_code'),
                    controller: _scanCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ej: WV-45821 o #45821',
                      hintStyle: TextStyle(color: Colors.white38),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  key: const Key('btn_validate_qr'),
                  onPressed: _validateCode,
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Validar en Shest'),
                ),
              ],
            ),
            if (_validationResult != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_isError ? Colors.red : Colors.green)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isError ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
                child: Text(
                  _validationResult!,
                  style: TextStyle(
                    color: _isError ? Colors.redAccent : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            const Divider(color: Colors.white24, height: 24),
            const Text(
              '2. Mi Tarjeta Digital y QR Personal (Fase 17):',
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    QrImageView(
                      data: widget.currentUser.personalQrData,
                      size: 125,
                    ),
                    Text(
                      '${widget.currentUser.name} • ${widget.currentUser.company}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      widget.currentUser.role,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
