import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:pehlivan_isg/services/theme_service.dart';

const _systemPrompt = '''
Sen PehlivanİSG uygulamasının yapay zeka asistanısın. Türkiye'deki İş Sağlığı ve Güvenliği (İSG) alanında uzman bir danışmansın. Kullanıcılar saha İSG uzmanları ve işyeri hekimleridir.

Görevin:
- Türk iş sağlığı ve güvenliği mevzuatı hakkında bilgi vermek (6331 sayılı Kanun ve alt yönetmelikler)
- Yönetmelik ve kanun maddelerini açıklamak, madde numaralarını belirtmek
- Risk değerlendirmesi, acil durum planları, eğitim yükümlülükleri konularında rehberlik etmek
- İş kazası ve meslek hastalığı prosedürleri, bildirim süreleri, SGK işlemleri hakkında bilgi vermek
- KKD seçimi, kullanımı ve standartları (EN normları) konusunda yardımcı olmak
- Tehlike sınıfı belirleme, MSDS/SDS okuma ve değerlendirme konularında destek sağlamak
- Periyodik kontrol, ölçüm ve muayene yükümlülüklerini açıklamak
- İSGKATİP kayıt ve bildirim süreçleri hakkında bilgi vermek

Yanıt kuralları:
- Her zaman Türkçe yanıt ver
- **Yanıtlarını markdown formatında yaz**: başlıklar (##), kalın metin (**bold**), listeler (- veya 1.), tablolar ve kod blokları kullan
- Mevzuata atıfta bulunurken kanun/yönetmelik adı ve madde numarasını açıkça yaz
- Pratik ve uygulanabilir bilgiler sun
- Yanıtlar yapılandırılmış ve okunması kolay olsun
- Önemli süreler, rakamlar ve yasal dayanak metinleri **kalın** yaz
- Gerektiğinde sektör veya işyeri tipini sorarak yanıtı özelleştir

Uzmanlık alanları:
• 6331 sayılı İş Sağlığı ve Güvenliği Kanunu
• İSG Risk Değerlendirmesi Yönetmeliği
• Çalışan Eğitimleri Yönetmeliği
• KKD Yönetmelikleri ve EN standartları
• Acil Durum Planları Yönetmeliği
• İş Kazası bildirimi (3 iş günü kuralı, SGK, e-bildirge)
• Tehlikeli Kimyasallar, MSDS/SDS, REACH
• Elle Taşıma, Ergonomi, Ekranlı Araçlar Yönetmelikleri
• Gürültü, Titreşim, Toz, Kimyasal Maruziyet limit değerleri
• İnşaat, Kimya, Madencilik, Sağlık sektörü özel yönetmelikleri
• Periyodik kontroller (elektrik, bina, asansör, baskılı kap vb.)
• OSGB hizmet alımı, sözleşme şartları
''';

const _hizliSorular = [
  '📋  İş kazası bildirim süresi ve prosedürü nedir?',
  '🔄  Risk değerlendirmesi ne zaman yenilenmeli?',
  '🎓  İSG eğitimi süreleri ve periyotları nedir?',
  '⚠️  Tehlikeli işyerinde çalışan sayısı sınırları?',
];

const _aiPurple = Color(0xFF7C4DFF);
const _aiPurpleLight = Color(0xFF9C6DFF);
const _aiPurpleDark = Color(0xFF4527A0);

class AiAsistanPage extends StatefulWidget {
  const AiAsistanPage({super.key});

  @override
  State<AiAsistanPage> createState() => _AiAsistanPageState();
}

class _AiAsistanPageState extends State<AiAsistanPage> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  final List<_ChatMessage> _mesajlar = [];
  late ChatSession _chat;
  bool _yukleniyor = false;
  bool _chatBasladi = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
    _chat = model.startChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _gonder(String metin) async {
    final temiz = metin.trim();
    if (temiz.isEmpty || _yukleniyor) return;

    setState(() {
      _mesajlar.add(_ChatMessage(metin: temiz, isUser: true));
      _yukleniyor = true;
      _chatBasladi = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final yanit = await _chat.sendMessage(Content.text(temiz));
      final yanitMetni = yanit.text ?? 'Yanıt alınamadı.';
      setState(() {
        _mesajlar.add(_ChatMessage(metin: yanitMetni, isUser: false));
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _mesajlar.add(_ChatMessage(
          metin: '**Bağlantı hatası**\n\n${e.toString()}',
          isUser: false,
          isHata: true,
        ));
        _yukleniyor = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sifirla() {
    setState(() {
      _mesajlar.clear();
      _chatBasladi = false;
      _yukleniyor = false;
    });
    _initChat();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: _buildAppBar(colors),
      body: Column(
        children: [
          Expanded(
            child: _chatBasladi
                ? _buildChatList(colors)
                : _KarsilamaEkrani(
                    onSoruSec: _gonder,
                    colors: colors,
                  ),
          ),
          _buildGirdi(colors, context),
        ],
      ),
    );
  }

  AppBar _buildAppBar(AppColors colors) {
    return AppBar(
      backgroundColor: colors.card,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: colors.text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_aiPurpleDark, _aiPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AI İSG Asistanı',
                style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF69FF47),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Gemini 2.5 Flash',
                    style:
                        TextStyle(color: colors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_chatBasladi)
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: colors.textMuted, size: 20),
            tooltip: 'Yeni Sohbet',
            onPressed: _sifirla,
          ),
      ],
    );
  }

  Widget _buildChatList(AppColors colors) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: _mesajlar.length + (_yukleniyor ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _mesajlar.length) {
          return const _YaziyorGostergesi();
        }
        return _MesajBalonu(mesaj: _mesajlar[i], colors: colors);
      },
    );
  }

  Widget _buildGirdi(AppColors colors, BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocus,
              enabled: !_yukleniyor,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: TextStyle(color: colors.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'İSG sorunuzu yazın...',
                hintStyle:
                    TextStyle(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.bg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: colors.border, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: _aiPurple, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _GonderButonu(
            yukleniyor: _yukleniyor,
            onTap: () => _gonder(_inputController.text),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// KARŞILAMA EKRANI
// ─────────────────────────────────────────────

class _KarsilamaEkrani extends StatelessWidget {
  final void Function(String) onSoruSec;
  final AppColors colors;

  const _KarsilamaEkrani(
      {required this.onSoruSec, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        children: [
          // ── AI İKON ──
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [_aiPurpleLight, _aiPurpleDark],
                center: Alignment.topLeft,
                radius: 1.5,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _aiPurple.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            'İSG Uzman Asistanı',
            style: TextStyle(
              color: colors.text,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yönetmelik araştırma • Kanun sorgulama\nRisk değerlendirmesi • Mevzuat analizi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // ── KAPASİTE ROZET SATIRI ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RozetKart(ikon: Icons.gavel_rounded, metin: '6331 SK'),
              const SizedBox(width: 8),
              _RozetKart(
                  ikon: Icons.health_and_safety_outlined,
                  metin: 'KKD & ETA'),
              const SizedBox(width: 8),
              _RozetKart(
                  ikon: Icons.science_outlined, metin: 'MSDS/SDS'),
            ],
          ),
          const SizedBox(height: 32),

          // ── HIZLI SORULAR ──
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'HIZLI SORULAR',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ..._hizliSorular.map(
            (soru) => _HizliSoruKart(
              soru: soru,
              onTap: () => onSoruSec(
                soru.replaceAll(RegExp(r'^[\p{Emoji}\s]+', unicode: true), '').trim(),
              ),
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }
}

class _RozetKart extends StatelessWidget {
  final IconData ikon;
  final String metin;
  const _RozetKart({required this.ikon, required this.metin});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _aiPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _aiPurple.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, color: _aiPurpleLight, size: 13),
          const SizedBox(width: 5),
          Text(
            metin,
            style: TextStyle(
              color: colors.text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HizliSoruKart extends StatelessWidget {
  final String soru;
  final VoidCallback onTap;
  final AppColors colors;

  const _HizliSoruKart(
      {required this.soru, required this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _aiPurple.withValues(alpha: 0.18), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    soru,
                    style:
                        TextStyle(color: colors.text, fontSize: 13.5),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: _aiPurpleLight, size: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MESAJ BALONU — Markdown destekli
// ─────────────────────────────────────────────

class _MesajBalonu extends StatelessWidget {
  final _ChatMessage mesaj;
  final AppColors colors;

  const _MesajBalonu({required this.mesaj, required this.colors});

  @override
  Widget build(BuildContext context) {
    final isUser = mesaj.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_aiPurpleDark, _aiPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _aiPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 15),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: mesaj.metin));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Yanıt kopyalandı'),
                    backgroundColor: colors.card,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: isUser
                  ? _KullaniciBaIonu(metin: mesaj.metin, colors: colors)
                  : _AiBaIonu(
                      metin: mesaj.metin,
                      isHata: mesaj.isHata,
                      colors: colors,
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _KullaniciBaIonu extends StatelessWidget {
  final String metin;
  final AppColors colors;
  const _KullaniciBaIonu({required this.metin, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent,
            colors.accent.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        metin,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AiBaIonu extends StatelessWidget {
  final String metin;
  final bool isHata;
  final AppColors colors;
  const _AiBaIonu(
      {required this.metin,
      required this.isHata,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
      decoration: BoxDecoration(
        color: isHata
            ? Colors.red.withValues(alpha: 0.08)
            : colors.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(
          color: isHata
              ? Colors.red.withValues(alpha: 0.3)
              : colors.border.withValues(alpha: 0.8),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: MarkdownBody(
            data: metin,
            selectable: true,
            extensionSet: md.ExtensionSet(
              md.ExtensionSet.gitHubFlavored.blockSyntaxes,
              <md.InlineSyntax>[
                md.EmojiSyntax(),
                ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
              ],
            ),
            styleSheet: _buildMarkdownStyle(colors),
            builders: {
              'code': _CodeBlockBuilder(colors: colors),
            },
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyle(AppColors colors) {
    return MarkdownStyleSheet(
      // Paragraf
      p: TextStyle(
          color: colors.text, fontSize: 14, height: 1.6),
      // Başlıklar
      h1: TextStyle(
          color: colors.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.4),
      h2: TextStyle(
          color: colors.text,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.4),
      h3: TextStyle(
          color: _aiPurpleLight,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1.4),
      // Bold ve italic
      strong: TextStyle(
          color: colors.text,
          fontWeight: FontWeight.w700),
      em: TextStyle(
          color: colors.textMuted,
          fontStyle: FontStyle.italic),
      // Listeler
      listBullet: TextStyle(color: _aiPurpleLight, fontSize: 14),
      listIndent: 16,
      // Blok alıntı
      blockquote: TextStyle(
          color: colors.textMuted, fontSize: 13, height: 1.5),
      blockquoteDecoration: BoxDecoration(
        color: _aiPurple.withValues(alpha: 0.08),
        border: Border(
            left: BorderSide(color: _aiPurple, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      // Inline kod
      code: TextStyle(
        color: _aiPurpleLight,
        backgroundColor: _aiPurple.withValues(alpha: 0.12),
        fontSize: 13,
        fontFamily: 'monospace',
      ),
      // Kod bloğu
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _aiPurple.withValues(alpha: 0.2), width: 1),
      ),
      codeblockPadding: const EdgeInsets.all(14),
      // Tablo
      tableHead: TextStyle(
          color: colors.text,
          fontWeight: FontWeight.bold,
          fontSize: 13),
      tableBody: TextStyle(color: colors.text, fontSize: 13),
      tableBorder: TableBorder.all(
          color: colors.border, width: 0.8,
          borderRadius: BorderRadius.circular(6)),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 7),
      tableColumnWidth: const FlexColumnWidth(),
      // Yatay çizgi
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: colors.border.withValues(alpha: 0.5),
                width: 1)),
      ),
      // Bağlantı
      a: const TextStyle(
          color: _aiPurpleLight,
          decoration: TextDecoration.underline),
      // Aralıklar
      h1Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h2Padding: const EdgeInsets.only(top: 6, bottom: 4),
      h3Padding: const EdgeInsets.only(top: 4, bottom: 2),
      pPadding: const EdgeInsets.only(bottom: 4),
    );
  }
}

// Kod bloğu için özel builder (başlık satırı ekler)
class _CodeBlockBuilder extends MarkdownElementBuilder {
  final AppColors colors;
  _CodeBlockBuilder({required this.colors});

  @override
  Widget? visitElementAfterWithContext(
      BuildContext context,
      md.Element element,
      TextStyle? preferredStyle,
      TextStyle? parentStyle) {
    if (element.tag != 'code') return null;
    final code = element.textContent;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: _aiPurple.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _aiPurple.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.code_rounded,
                    color: _aiPurpleLight, size: 13),
                const SizedBox(width: 6),
                Text('Kod',
                    style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Clipboard.setData(
                      ClipboardData(text: code)),
                  child: Icon(Icons.copy_rounded,
                      color: colors.textMuted, size: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              code,
              style: const TextStyle(
                color: Color(0xFFE6EDF3),
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// YAZILIYOR GÖSTERGESİ
// ─────────────────────────────────────────────

class _YaziyorGostergesi extends StatefulWidget {
  const _YaziyorGostergesi();

  @override
  State<_YaziyorGostergesi> createState() => _YaziyorGostergesiState();
}

class _YaziyorGostergesiState extends State<_YaziyorGostergesi>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_aiPurpleDark, _aiPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _aiPurple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 15),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                  color: colors.border.withValues(alpha: 0.8),
                  width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i / 3;
                  final val = ((_ctrl.value - delay) % 1.0);
                  final opacity = val < 0.5
                      ? val * 2
                      : (1 - val) * 2;
                  return Container(
                    width: 7,
                    height: 7,
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                    decoration: BoxDecoration(
                      color: _aiPurple
                          .withValues(alpha: 0.3 + opacity * 0.7),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GÖNDER BUTONU
// ─────────────────────────────────────────────

class _GonderButonu extends StatelessWidget {
  final bool yukleniyor;
  final VoidCallback onTap;

  const _GonderButonu({required this.yukleniyor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: yukleniyor ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: yukleniyor
              ? null
              : const LinearGradient(
                  colors: [_aiPurpleDark, _aiPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: yukleniyor ? const Color(0xFF2A2A3A) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: yukleniyor
              ? null
              : [
                  BoxShadow(
                    color: _aiPurple.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: yukleniyor
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _aiPurple,
                  ),
                ),
              )
            : const Icon(Icons.send_rounded,
                color: Colors.white, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MESAJ MODELİ
// ─────────────────────────────────────────────

class _ChatMessage {
  final String metin;
  final bool isUser;
  final bool isHata;

  _ChatMessage({
    required this.metin,
    required this.isUser,
    this.isHata = false,
  });
}
