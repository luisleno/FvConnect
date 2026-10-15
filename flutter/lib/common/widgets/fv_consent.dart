import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';

import '../../utils/http_service.dart' as http;

// Termo de acesso remoto (LGPD). Aparece uma vez por versão do termo, antes de usar o
// FvConnect; o aceite fica salvo no computador e é registrado no portal.
const kFvConsentVersion = '1';
const _kFvConsentOption = 'fv-consent-version';
bool _fvConsentShowing = false;

const _kFvConsentText = '''
Este programa permite que técnicos autorizados acessem este computador remotamente para prestar suporte.

• O acesso só acontece com a sua autorização: você aceita na hora ou define uma senha para acesso sem ninguém do outro lado.
• Durante o acesso, o técnico pode ver a tela, usar mouse e teclado e transferir arquivos, conforme o que você permitir.
• Você vê quando alguém está conectado e pode desconectar a qualquer momento.
• A conexão é criptografada de ponta a ponta. A tela não é gravada.
• Cada acesso é registrado (computador, técnico, data, hora e duração) para sua segurança, conforme a Lei Geral de Proteção de Dados (Lei 13.709/2018).

Ao clicar em "Li e aceito", você confirma que é o usuário ou responsável por este computador e concorda com estes termos e com a política de privacidade em fvconnect.net/privacidade.''';

Future<void> _fvRecordConsent() async {
  try {
    final api = await bind.mainGetApiServer();
    if (api.trim().isEmpty) return;
    var hostname = '';
    try {
      hostname = jsonDecode(bind.mainGetLoginDeviceInfo())['name'] ?? '';
    } catch (_) {}
    await http.post(Uri.parse('$api/api/fv/consent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': await bind.mainGetMyId(),
          'hostname': hostname,
          'version': kFvConsentVersion,
        }));
  } catch (e) {
    debugPrint('fv consent record failed: $e');
  }
}

/// Mostra o termo se ainda não foi aceito nesta versão. Recusar fecha o programa.
void fvEnsureConsent() {
  if (_fvConsentShowing) return;
  if (bind.mainGetLocalOption(key: _kFvConsentOption) == kFvConsentVersion) return;
  _fvConsentShowing = true;
  gFFI.dialogManager.show((setState, close, context) {
    return CustomAlertDialog(
      title: const Text('Termo de acesso remoto'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(child: Text(_kFvConsentText)),
      ),
      actions: [
        dialogButton('Recusar e sair', isOutline: true, onPressed: () => exit(0)),
        dialogButton('Li e aceito', onPressed: () async {
          await bind.mainSetLocalOption(key: _kFvConsentOption, value: kFvConsentVersion);
          _fvConsentShowing = false;
          close();
          _fvRecordConsent();
        }),
      ],
    );
  }, tag: 'fv-consent');
}
