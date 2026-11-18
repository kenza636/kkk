// AirConcept - version corrigée
// Les phrases sont conservées en mémoire pendant l'exécution.
// Les modules Projection, Généralisation, Spécialisation et Base de données
// restent des pages provisoires, comme indiqué dans l'interface.

import 'package:flutter/material.dart';

void main() => runApp(const AirConceptApp());

const Color navy = Color(0xFF173C82);
const Color blue = Color(0xFF3156C8);
const Color ink = Color(0xFF17243A);
const Color muted = Color(0xFF8795B5);
const Color line = Color(0xFFE4E9F2);

class AirConceptApp extends StatelessWidget {
  const AirConceptApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AirConcept',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7FB),
          colorScheme: ColorScheme.fromSeed(seedColor: blue),
          fontFamily: 'Segoe UI',
        ),
        home: const DashboardShell(),
      );
}

class PhraseItem {
  PhraseItem(this.text) : createdAt = DateTime.now();
  String text;
  final DateTime createdAt;
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});
  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int currentIndex = 0;
  final List<PhraseItem> phrases = [
    PhraseItem('Le passager voyage dans un avion vers Paris.'),
    PhraseItem('Le pilote opère le vol AF123 depuis Orly.'),
    PhraseItem('L’avion décolle de l’aéroport de Tunis.'),
    PhraseItem('Le mécanicien inspecte les moteurs.'),
    PhraseItem('La tour de contrôle autorise l’atterrissage.'),
  ];

  final labels = const [
    'Tableau de bord', 'Phrases', 'Graphes conceptuels', 'Projection',
    'Généralisation', 'Spécialisation', 'Base de données'
  ];
  final icons = const [
    Icons.home_outlined, Icons.description_outlined, Icons.share_outlined,
    Icons.alt_route, Icons.call_split, Icons.account_tree_outlined,
    Icons.storage_outlined
  ];

  void addPhrase(String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    setState(() => phrases.insert(0, PhraseItem(value)));
  }

  void deletePhrase(int index) {
    if (index < 0 || index >= phrases.length) return;
    setState(() => phrases.removeAt(index));
  }

  void editPhrase(int index, String value) {
    if (index < 0 || index >= phrases.length) return;

    final newValue = value.trim();
    if (newValue.isEmpty) return;

    setState(() => phrases[index].text = newValue);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 980;
    final pages = <Widget>[
      DashboardPage(onNewPhrase: () => setState(() => currentIndex = 1),
          phraseCount: phrases.length),
      PhrasesPage(phrases: phrases, onAdd: addPhrase,
          onDelete: deletePhrase, onEdit: editPhrase),
      ConceptGraphPage(phrases: phrases),
      const PlaceholderPage(title: 'Projection'),
      const PlaceholderPage(title: 'Généralisation'),
      const PlaceholderPage(title: 'Spécialisation'),
      const PlaceholderPage(title: 'Base de données'),
    ];

    return Scaffold(
      body: Row(children: [
        if (!compact)
          _Sidebar(selected: currentIndex, labels: labels, icons: icons,
              onSelect: (i) => setState(() => currentIndex = i)),
        Expanded(child: Column(children: [
          if (compact)
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
              child: Row(children: [
                const Icon(Icons.flight_takeoff_rounded, color: blue),
                const SizedBox(width: 10),
                const Text('AirConcept', style: TextStyle(
                    fontWeight: FontWeight.w800, color: navy)),
                const Spacer(),
                PopupMenuButton<int>(
                  initialValue: currentIndex,
                  onSelected: (i) => setState(() => currentIndex = i),
                  itemBuilder: (_) => [
                    for (var i = 0; i < labels.length; i++)
                      PopupMenuItem(value: i, child: Text(labels[i]))
                  ],
                ),
              ]),
            ),
          Expanded(child: IndexedStack(index: currentIndex, children: pages)),
        ])),
      ]),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect,
    required this.labels, required this.icons});
  final int selected;
  final ValueChanged<int> onSelect;
  final List<String> labels;
  final List<IconData> icons;

  @override
  Widget build(BuildContext context) => Container(
        width: 270,
        decoration: const BoxDecoration(color: Colors.white,
          border: Border(right: BorderSide(color: Color(0xFFE7EBF3)))),
        child: Column(children: [
          const SizedBox(height: 28),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(color: blue,
                  borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.flight_takeoff_rounded,
                    color: Colors.white, size: 28)),
              const SizedBox(width: 13),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AirConcept', style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800, color: Color(0xFF17358A))),
                  Text('GRAPHES CONCEPTUELS', style: TextStyle(fontSize: 9,
                      letterSpacing: 1.2, color: muted,
                      fontWeight: FontWeight.w700)),
                ])),
            ])),
          const SizedBox(height: 32),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(alignment: Alignment.centerLeft,
              child: Text('MENU PRINCIPAL', style: TextStyle(fontSize: 9,
                letterSpacing: 1.5, color: Colors.grey.shade500,
                fontWeight: FontWeight.w800)))),
          const SizedBox(height: 10),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: labels.length,
            itemBuilder: (_, i) {
              final active = selected == i;
              return Padding(padding: const EdgeInsets.only(bottom: 5),
                child: InkWell(onTap: () => onSelect(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(height: 48,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFEEF3FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      AnimatedContainer(duration: const Duration(milliseconds: 180),
                        width: 3, height: active ? 30 : 0,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: const BoxDecoration(color: blue,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(3)))),
                      Icon(icons[i], size: 21,
                        color: active ? blue : const Color(0xFF7B879E)),
                      const SizedBox(width: 13),
                      Expanded(child: Text(labels[i], style: TextStyle(fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? blue : const Color(0xFF69758B)))),
                    ]))),
              );
            },
          )),
          Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(border: Border(
              top: BorderSide(color: Colors.grey.shade200))),
            child: Row(children: [
              Container(width: 38, height: 38,
                decoration: BoxDecoration(color: blue,
                  borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Text('AK', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800))),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('Allaoua Kenza', style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('Étudiante', style: TextStyle(fontSize: 11, color: muted))])),
            ])),
        ]),
      );
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, height: 1.1,
              fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 7),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: muted)),
        ])),
      Container(width: 42, height: 42,
        decoration: BoxDecoration(color: blue,
          borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: const Text('AK', style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800))),
      const SizedBox(width: 10),
      if (MediaQuery.sizeOf(context).width > 650)
        const Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Allaoua Kenza', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 12)),
            Text('Étudiante', style: TextStyle(fontSize: 10, color: muted))]),
    ]),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.onNewPhrase,
    required this.phraseCount});
  final VoidCallback onNewPhrase;
  final int phraseCount;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'Tableau de bord',
          subtitle: 'Vue d’ensemble de votre espace de modélisation'),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            Container(width: double.infinity, padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(color: navy,
                borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ESPACE ACADÉMIQUE', style: TextStyle(fontSize: 9,
                      letterSpacing: 1.6, color: Color(0xFFCBD8EF),
                      fontWeight: FontWeight.w800)),
                  const SizedBox(height: 13),
                  const Text('Bonjour Allaoua Kenza', style: TextStyle(
                      fontSize: 22, color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 9),
                  const Text('Créez et explorez simplement vos graphes conceptuels aéronautiques.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFCBD8EF))),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: onNewPhrase,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
                      foregroundColor: blue, elevation: 0),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nouvelle phrase')),
                ])),
            const SizedBox(height: 22),
            GridView.count(crossAxisCount: width < 650 ? 1 : (width < 1050 ? 2 : 4),
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16, mainAxisSpacing: 16,
              childAspectRatio: width < 650 ? 3.0 : 2.05,
              children: [
                StatCard(icon: Icons.description_outlined, color: const Color(0xFF4777F6),
                  title: 'Phrases', value: '$phraseCount', change: 'Corpus', detail: 'enregistrées'),
                const StatCard(icon: Icons.layers_outlined, color: Color(0xFF815CF4),
                  title: 'Concepts', value: '—', change: 'À calculer', detail: 'selon analyse'),
                const StatCard(icon: Icons.share_outlined, color: Color(0xFF12A69A),
                  title: 'Graphes créés', value: '—', change: 'À calculer', detail: 'selon analyse'),
                const StatCard(icon: Icons.call_split, color: Color(0xFFE88A48),
                  title: 'Projections', value: '—', change: 'À venir', detail: 'module'),
              ]),
            const SizedBox(height: 22),
            Container(width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white,
                border: Border.all(color: line), borderRadius: BorderRadius.circular(12)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VOTRE ESPACE DE TRAVAIL', style: TextStyle(fontSize: 9,
                      letterSpacing: 1.5, color: muted, fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text('Commencez par ajouter une phrase dans le menu Phrases, puis sélectionnez-la dans Graphes conceptuels.',
                      style: TextStyle(fontSize: 13, color: ink)),
                ])),
          ])),
      ]));
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.icon, required this.color,
    required this.title, required this.value, required this.change,
    required this.detail});
  final IconData icon;
  final Color color;
  final String title, value, change, detail;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line),
      borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(title, style: const TextStyle(fontSize: 11, color: muted)),
          const SizedBox(height: 4), Text(value, style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800))])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(change, style: TextStyle(fontSize: 10, color: color,
            fontWeight: FontWeight.w800)), const SizedBox(height: 5),
          Text(detail, style: const TextStyle(fontSize: 9, color: muted))]),
    ]),
  );
}

class PhrasesPage extends StatefulWidget {
  const PhrasesPage({super.key, required this.phrases, required this.onAdd,
    required this.onDelete, required this.onEdit});
  final List<PhraseItem> phrases;
  final ValueChanged<String> onAdd;
  final void Function(int) onDelete;
  final void Function(int, String) onEdit;
  @override
  State<PhrasesPage> createState() => _PhrasesPageState();
}

class _PhrasesPageState extends State<PhrasesPage> {
  final TextEditingController phraseController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    phraseController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void add() {
    if (phraseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une phrase.')));
      return;
    }
    widget.onAdd(phraseController.text);
    phraseController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phrase ajoutée au corpus.')));
  }

  Future<void> editPhrase(int index) async {
    final controller = TextEditingController(text: widget.phrases[index].text);
    final result = await showDialog<String>(context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la phrase'),
        content: TextField(controller: controller, autofocus: true,
          maxLines: 3, decoration: const InputDecoration(
            border: OutlineInputBorder(), labelText: 'Phrase')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enregistrer')),
        ],
      ));
    controller.dispose();

    if (!mounted) return;

    if (result != null && result.trim().isNotEmpty &&
        index >= 0 && index < widget.phrases.length) {
      widget.onEdit(index, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.toLowerCase().trim();
    final visible = <int>[];
    for (var i = 0; i < widget.phrases.length; i++) {
      final matchesSearch = widget.phrases[i].text.toLowerCase().contains(query);
      if (matchesSearch) visible.add(i);
    }

    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'Gestion des phrases',
          subtitle: 'Créez et organisez votre corpus aéronautique'),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            Container(width: double.infinity, padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.description_outlined, color: Colors.white),
                    SizedBox(width: 10), Text('Nouvelle phrase', style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))]),
                  const SizedBox(height: 8),
                  const Text('Saisissez une phrase simple liée au domaine du transport aérien.',
                    style: TextStyle(color: Color(0xFFCBD8EF), fontSize: 11)),
                  const SizedBox(height: 16),
                  TextField(controller: phraseController, maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ex. Le passager embarque dans un avion…',
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => add()),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton(onPressed: phraseController.clear,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70)),
                      child: const Text('Effacer')),
                    ElevatedButton.icon(onPressed: add,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
                        foregroundColor: blue),
                      icon: const Icon(Icons.add), label: const Text('Ajouter la phrase')),
                  ]),
                ])),
            const SizedBox(height: 22),
            Container(width: double.infinity, padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line),
                borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CORPUS', style: TextStyle(fontSize: 9,
                    letterSpacing: 1.5, color: muted, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text('Phrases enregistrées (${widget.phrases.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  TextField(controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: 'Rechercher une phrase…', isDense: true,
                      filled: true, fillColor: const Color(0xFFF8FAFD),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
                        borderSide: const BorderSide(color: line))),
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    const Padding(padding: EdgeInsets.all(20),
                      child: Center(child: Text('Aucune phrase trouvée.',
                        style: TextStyle(color: muted))))
                  else
                    ...visible.map((index) => _PhraseRow(
                      text: widget.phrases[index].text,
                      onEdit: () => editPhrase(index),
                      onDelete: () => showDialog<void>(context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Supprimer cette phrase ?'),
                          content: const Text('Cette action retirera la phrase du corpus.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Annuler')),
                            TextButton(onPressed: () {
                              widget.onDelete(index);
                              Navigator.pop(dialogContext);
                            }, child: const Text('Supprimer')),
                          ],
                        )),
                    )),
                ])),
          ])),
      ]));
  }
}

class _PhraseRow extends StatelessWidget {
  const _PhraseRow({required this.text, required this.onEdit, required this.onDelete});
  final String text;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F3F8)))),
    child: Row(children: [
      const Icon(Icons.description_outlined, size: 17, color: blue),
      const SizedBox(width: 10),
      Expanded(child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      )),
      IconButton(tooltip: 'Modifier', onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined, size: 18)),
      IconButton(tooltip: 'Supprimer', onPressed: onDelete,
        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF8795B5))),
    ]),
  );
}

class ConceptGraphPage extends StatefulWidget {
  const ConceptGraphPage({super.key, required this.phrases});
  final List<PhraseItem> phrases;
  @override
  State<ConceptGraphPage> createState() => _ConceptGraphPageState();
}

class _ConceptGraphPageState extends State<ConceptGraphPage> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    if (selectedIndex >= widget.phrases.length) selectedIndex = 0;
    final selectedPhrase = widget.phrases.isEmpty
        ? 'Aucune phrase disponible. Ajoutez une phrase dans le menu Phrases.'
        : widget.phrases[selectedIndex].text;
    return SingleChildScrollView(child: Column(children: [
      const PageHeader(title: 'Graphes conceptuels',
        subtitle: 'Transformez une phrase en représentation conceptuelle'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line),
              borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sélectionnez une phrase à analyser',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: widget.phrases.isEmpty ? null : selectedIndex,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  hint: const Text('Aucune phrase disponible'),
                  items: [for (var i = 0; i < widget.phrases.length; i++)
                    DropdownMenuItem(value: i, child: Text(widget.phrases[i].text,
                      overflow: TextOverflow.ellipsis))],
                  onChanged: widget.phrases.isEmpty ? null : (value) {
                    if (value != null) setState(() => selectedIndex = value);
                  },
                ),
                const SizedBox(height: 10),
                Text('Phrase sélectionnée : $selectedPhrase',
                  style: const TextStyle(fontSize: 12, color: muted)),
              ])),
          const SizedBox(height: 18),
          Container(width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line),
              borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exemple de graphe conceptuel', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Le dessin ci-dessous est un exemple statique : il ne constitue pas encore une extraction automatique de la phrase.',
                  style: TextStyle(fontSize: 11, color: muted)),
                const SizedBox(height: 14),
                SizedBox(height: 300, child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: 720, child: CustomPaint(
                    painter: GraphPainter(), child: const SizedBox.expand())))),
                const SizedBox(height: 12),
                const Wrap(spacing: 8, runSpacing: 8, children: [
                  ConceptChip('Passager', Color(0xFF815CF4)),
                  ConceptChip('AF 123', Color(0xFF4777F6)),
                  ConceptChip('Airbus A320', Color(0xFF4777F6)),
                  ConceptChip('Paris CDG', Color(0xFF12A69A)),
                  ConceptChip('Paris', Color(0xFFE88A48)),
                ]),
              ])),
        ])),
    ]));
  }
}

class ConceptChip extends StatelessWidget {
  const ConceptChip(this.text, this.color, {super.key});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: color.withOpacity(.08),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withOpacity(.2))),
    child: Text(text, style: TextStyle(fontSize: 10, color: color,
      fontWeight: FontWeight.w700)),
  );
}

class GraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final edge = Paint()..color = const Color(0xFFB4BDD3)
      ..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final pass = Offset(size.width * .16, size.height * .43);
    final flight = Offset(size.width * .40, size.height * .23);
    final plane = Offset(size.width * .40, size.height * .68);
    final airport = Offset(size.width * .68, size.height * .43);
    final city = Offset(size.width * .88, size.height * .43);
    canvas.drawLine(pass, flight, edge);
    canvas.drawLine(pass, plane, edge);
    canvas.drawLine(flight, airport, edge);
    canvas.drawLine(plane, airport, edge);
    canvas.drawLine(airport, city, edge);

    void node(Offset center, String type, String name, Color color) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 132, height: 58),
        const Radius.circular(8));
      canvas.drawRRect(rect, Paint()..color = Colors.white);
      canvas.drawRRect(rect, Paint()..color = color..strokeWidth = 1.6
        ..style = PaintingStyle.stroke);
      final first = TextPainter(text: TextSpan(text: type.toUpperCase(),
        style: const TextStyle(fontSize: 8, letterSpacing: 1, color: muted)),
        textDirection: TextDirection.ltr)..layout(maxWidth: 120);
      first.paint(canvas, Offset(center.dx - first.width / 2, center.dy - 15));
      final second = TextPainter(text: TextSpan(text: name,
        style: const TextStyle(fontSize: 11, color: ink, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr)..layout(maxWidth: 120);
      second.paint(canvas, Offset(center.dx - second.width / 2, center.dy + 2));
    }

    node(pass, 'Personne', 'Passager', const Color(0xFF815CF4));
    node(flight, 'Vol', 'AF 123', const Color(0xFF4777F6));
    node(plane, 'Aéronef', 'Airbus A320', const Color(0xFF4777F6));
    node(airport, 'Aéroport', 'Paris CDG', const Color(0xFF12A69A));
    node(city, 'Ville', 'Paris', const Color(0xFFE88A48));
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => false;
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Column(children: [
    PageHeader(title: title, subtitle: 'Module connecté à votre espace AirConcept'),
    const Expanded(child: Center(child: Padding(padding: EdgeInsets.all(24),
      child: Text('Cette fonctionnalité reste à développer.',
        textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 14))))),
  ]);
}
