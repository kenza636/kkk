import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const AirGraphApp());

const Color navy = Color(0xFF152F50);
const Color blue = Color(0xFF2864E8);
const Color ink = Color(0xFF122C4B);
const Color muted = Color(0xFF7E91AD);
const Color line = Color(0xFFDCE5F2);
const Color page = Color(0xFFF6F8FC);

class AirGraphApp extends StatelessWidget {
  const AirGraphApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AirGraph',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Segoe UI',
          scaffoldBackgroundColor: page,
          colorScheme: ColorScheme.fromSeed(seedColor: blue),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: line),
            ),
          ),
        ),
        home: const AirGraphShell(),
      );
}

class GraphNode {
  GraphNode({
    required this.id,
    required this.label,
    required this.isRelation,
    required this.x,
    required this.y,
  });

  final String id;
  String label;
  bool isRelation;
  double x;
  double y;

  Map<String, Object> toJson() => {
        'id': id,
        'label': label,
        'isRelation': isRelation,
        'x': x,
        'y': y,
      };

  factory GraphNode.fromJson(Map<String, dynamic> json) => GraphNode(
        id: json['id'] as String,
        label: json['label'] as String,
        isRelation: json['isRelation'] as bool? ?? false,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );
}

class GraphArc {
  GraphArc({required this.from, required this.to, required this.label});

  final String from;
  final String to;
  String label;

  Map<String, Object> toJson() => {'from': from, 'to': to, 'label': label};

  factory GraphArc.fromJson(Map<String, dynamic> json) => GraphArc(
        from: json['from'] as String,
        to: json['to'] as String,
        label: json['label'] as String? ?? '',
      );
}

class GraphDocument {
  GraphDocument({
    required this.id,
    required this.title,
    required this.phrase,
    List<GraphNode>? nodes,
    List<GraphArc>? arcs,
  })  : nodes = nodes ?? [],
        arcs = arcs ?? [];

  final String id;
  String title;
  String phrase;
  final List<GraphNode> nodes;
  final List<GraphArc> arcs;

  Map<String, Object> toJson() => {
        'id': id,
        'title': title,
        'phrase': phrase,
        'nodes': nodes.map((node) => node.toJson()).toList(),
        'arcs': arcs.map((arc) => arc.toJson()).toList(),
      };

  factory GraphDocument.fromJson(Map<String, dynamic> json) => GraphDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        phrase: json['phrase'] as String? ?? '',
        nodes: (json['nodes'] as List<dynamic>? ?? [])
            .map((item) => GraphNode.fromJson(item as Map<String, dynamic>))
            .toList(),
        arcs: (json['arcs'] as List<dynamic>? ?? [])
            .map((item) => GraphArc.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  GraphDocument copy() => GraphDocument.fromJson(
        jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>,
      );
}

class PhraseItem {
  PhraseItem(this.text);
  String text;
}

class AirGraphShell extends StatefulWidget {
  const AirGraphShell({super.key});

  @override
  State<AirGraphShell> createState() => _AirGraphShellState();
}

class _AirGraphShellState extends State<AirGraphShell> {
  static const _storageKey = 'airgraph.workspace.v1';
  int _currentPage = 0;
  bool _storageReady = false;
  String? _storageError;
  late SharedPreferences _preferences;

  final List<PhraseItem> _phrases = [
    PhraseItem('Le passager réserve un billet pour Paris.'),
    PhraseItem('Le pilote conduit un avion vers l’aéroport.'),
    PhraseItem('La compagnie aérienne transporte des voyageurs.'),
  ];
  late List<GraphDocument> _graphs = [
    GraphDocument(
      id: _newId(),
      title: 'Ma première représentation',
      phrase: 'Le passager réserve un billet pour Paris.',
    ),
  ];

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  Future<void> _loadWorkspace() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      final saved = _preferences.getString(_storageKey);
      if (saved != null) {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        final graphs = (data['graphs'] as List<dynamic>)
            .map((item) => GraphDocument.fromJson(item as Map<String, dynamic>))
            .toList();
        final phrases = (data['phrases'] as List<dynamic>? ?? [])
            .map((item) => PhraseItem(item as String))
            .toList();
        if (graphs.isNotEmpty) _graphs = graphs;
        if (phrases.isNotEmpty) {
          _phrases
            ..clear()
            ..addAll(phrases);
        }
      }
    } catch (error) {
      _storageError = 'Chargement local impossible : $error';
    } finally {
      if (mounted) setState(() => _storageReady = true);
    }
  }

  Future<void> _saveWorkspace() async {
    if (!_storageReady) {
      _message('Le chargement local n’est pas encore terminé.');
      return;
    }
    try {
      await _preferences.setString(
        _storageKey,
        jsonEncode({
          'graphs': _graphs.map((graph) => graph.toJson()).toList(),
          'phrases': _phrases.map((phrase) => phrase.text).toList(),
        }),
      );
      _message('Espace enregistré sur cet appareil.');
    } catch (error) {
      _message('Échec de l’enregistrement local : $error');
    }
  }

  Future<void> _restoreWorkspace() async {
    try {
      final saved = _preferences.getString(_storageKey);
      if (saved == null) {
        _message('Aucun espace enregistré à restaurer.');
        return;
      }
      final data = jsonDecode(saved) as Map<String, dynamic>;
      setState(() {
        _graphs = (data['graphs'] as List<dynamic>)
            .map((item) => GraphDocument.fromJson(item as Map<String, dynamic>))
            .toList();
        _phrases
          ..clear()
          ..addAll((data['phrases'] as List<dynamic>? ?? [])
              .map((item) => PhraseItem(item as String)));
      });
      _message('Votre espace enregistré a été restauré.');
    } catch (error) {
      _message('Restauration impossible : $error');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _addPhrase(String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    if (_phrases.any((phrase) => phrase.text == value)) {
      _message('Cette phrase est déjà dans le corpus.');
      return;
    }
    setState(() => _phrases.insert(0, PhraseItem(value)));
    _message('Phrase ajoutée au corpus.');
  }

  void _createGraph(GraphDocument graph) {
    setState(() {
      _graphs.insert(0, graph);
      _currentPage = 2;
    });
  }

  void _updateGraph(GraphDocument graph) {
    final index = _graphs.indexWhere((item) => item.id == graph.id);
    if (index >= 0) setState(() => _graphs[index] = graph);
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Accueil',
      'Apprendre',
      'Représentation des phrases',
      'Projection',
      'Généralisation',
      'Spécialisation',
      'Exercices',
    ];
    const icons = [
      Icons.home_outlined,
      Icons.menu_book_outlined,
      Icons.account_tree_outlined,
      Icons.layers_outlined,
      Icons.north_outlined,
      Icons.south_outlined,
      Icons.assignment_outlined,
    ];
    final compact = MediaQuery.sizeOf(context).width < 900;
    final activeGraph = _graphs.first;
    final pages = <Widget>[
      HomePage(
        graphCount: _graphs.length,
        phraseCount: _phrases.length,
        onNavigate: (index) => setState(() => _currentPage = index),
        onCreateGraph: () => _createGraph(GraphDocument(
          id: _newId(),
          title: 'Nouvelle représentation',
          phrase: _phrases.first.text,
        )),
      ),
      LearningPage(onOpenGraph: () => setState(() => _currentPage = 2)),
      GraphEditorPage(
        key: ValueKey(activeGraph.id),
        graphs: _graphs,
        phrases: _phrases,
        onAddPhrase: _addPhrase,
        onGraphChanged: _updateGraph,
        onCreateGraph: _createGraph,
        onSave: _saveWorkspace,
        onRestore: _restoreWorkspace,
      ),
      ProjectionPage(graphs: _graphs, onCreateGraph: _createGraph),
      GeneralizationPage(graphs: _graphs),
      SpecializationPage(graphs: _graphs),
      const ExercisePage(),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (!compact)
            _Sidebar(
              selected: _currentPage,
              labels: labels,
              icons: icons,
              onSelect: (index) => setState(() => _currentPage = index),
            ),
          Expanded(
            child: Column(
              children: [
                if (compact)
                  Container(
                    height: 62,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: navy,
                    child: Row(
                      children: [
                        const Icon(Icons.flight_takeoff, color: Colors.white),
                        const SizedBox(width: 10),
                        const Text('AirGraph',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                        const Spacer(),
                        PopupMenuButton<int>(
                          iconColor: Colors.white,
                          onSelected: (index) =>
                              setState(() => _currentPage = index),
                          itemBuilder: (_) => [
                            for (var i = 0; i < labels.length; i++)
                              PopupMenuItem(value: i, child: Text(labels[i])),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (_storageError != null)
                  MaterialBanner(
                    content: Text(_storageError!),
                    actions: [
                      TextButton(
                        onPressed: () => setState(() => _storageError = null),
                        child: const Text('Fermer'),
                      )
                    ],
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _currentPage,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.labels,
    required this.icons,
    required this.onSelect,
  });

  final int selected;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        width: 285,
        color: navy,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 20, 52),
              child: Row(
                children: [
                  const Icon(Icons.flight_takeoff,
                      color: Color(0xFF5FD4E6), size: 29),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.7),
                          children: [
                            TextSpan(
                                text: 'AirGraph',
                                style: TextStyle(color: Colors.white)),
                            TextSpan(
                                text: '.',
                                style: TextStyle(color: Color(0xFF5FD4E6))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(42, 0, 20, 18),
              child: Text('VOTRE ESPACE\nD’EXPLORATION',
                  style: TextStyle(
                      color: Color(0xFF9BB2D2),
                      fontSize: 10,
                      letterSpacing: 1.6,
                      height: 1.5,
                      fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: labels.length,
                itemBuilder: (context, index) {
                  final active = selected == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: InkWell(
                      onTap: () => onSelect(index),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 55),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(
                          color: active ? blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          children: [
                            Icon(icons[index],
                                size: 21,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFFB7C7DA)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(labels[index],
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.35,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500)),
                            ),
                            if (active)
                              const Icon(Icons.circle,
                                  size: 7, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3B60),
                border: Border.all(color: const Color(0xFF345476)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_outlined, color: Color(0xFF5FD4E6)),
                  SizedBox(height: 17),
                  Text('Une notion à la fois.',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text(
                      'Les grandes idées commencent par de petites connexions.',
                      style: TextStyle(
                          color: Color(0xFFB5C8E1), height: 1.5, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.child,
    this.breadcrumb = 'Espace pédagogique',
    this.showHeader = true,
  });

  final Widget child;
  final String breadcrumb;
  final bool showHeader;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (showHeader)
            Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 34),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(breadcrumb,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: muted, fontSize: 12)),
                  ),
                  const SizedBox(width: 14),
                  const Text('/', style: TextStyle(color: line, fontSize: 16)),
                  const SizedBox(width: 14),
                  const Expanded(
                    flex: 3,
                    child: Text('Le transport aérien, autrement',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: ink, fontSize: 12)),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Aide',
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Aide AirGraph'),
                        content: const Text(
                            'Utilisez le menu de gauche pour explorer les leçons, créer des graphes et pratiquer.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Compris'),
                          )
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.help_outline, color: muted),
                  ),
                  const SizedBox(width: 7),
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFFEAF1FC),
                    child: Text('AG',
                        style: TextStyle(
                            color: blue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          Expanded(child: child),
        ],
      );
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.graphCount,
    required this.phraseCount,
    required this.onNavigate,
    required this.onCreateGraph,
  });

  final int graphCount;
  final int phraseCount;
  final ValueChanged<int> onNavigate;
  final VoidCallback onCreateGraph;

  @override
  Widget build(BuildContext context) => _PageFrame(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 760
                ? 1
                : constraints.maxWidth < 1120
                    ? 2
                    : 4;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(34, 30, 34, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bienvenue dans votre espace AirGraph',
                      style: TextStyle(
                          color: ink,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 7),
                  const Text(
                      'De la phrase au graphe, du particulier au général.',
                      style: TextStyle(color: muted, fontSize: 13)),
                  const SizedBox(height: 35),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                            'Quatre façons d’explorer les connaissances',
                            style: TextStyle(
                                fontSize: 19,
                                color: ink,
                                fontWeight: FontWeight.w700)),
                      ),
                      Text('VOTRE BOÎTE À OUTILS',
                          style: TextStyle(
                              color: muted, fontSize: 9, letterSpacing: 1.4)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Choisissez une activité pour commencer.',
                      style: TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(height: 21),
                  GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: columns == 1 ? 2.2 : 1.05,
                    children: [
                      _ActivityCard(
                        number: '01',
                        icon: Icons.account_tree_outlined,
                        title: 'Représentation des phrases',
                        text:
                            'Transformez vos phrases en graphes conceptuels clairs et structurés.',
                        action: 'Créer un graphe',
                        onTap: onCreateGraph,
                      ),
                      _ActivityCard(
                        number: '02',
                        icon: Icons.layers_outlined,
                        title: 'Projection',
                        text:
                            'Découvrez les correspondances et les liens entre deux graphes.',
                        action: 'Comparer des graphes',
                        tint: const Color(0xFF13A7BC),
                        onTap: () => onNavigate(3),
                      ),
                      _ActivityCard(
                        number: '03',
                        icon: Icons.north_outlined,
                        title: 'Généralisation',
                        text:
                            'Passez des connaissances particulières aux connaissances générales.',
                        action: 'Généraliser un concept',
                        tint: const Color(0xFF647ED0),
                        onTap: () => onNavigate(4),
                      ),
                      _ActivityCard(
                        number: '04',
                        icon: Icons.south_outlined,
                        title: 'Spécialisation',
                        text:
                            'Explorez les différentes formes spécifiques d’un concept.',
                        action: 'Spécialiser un concept',
                        tint: const Color(0xFF4A9FAB),
                        onTap: () => onNavigate(5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (constraints.maxWidth < 800)
                    Column(
                      children: [
                        _LearningPromo(onTap: () => onNavigate(1)),
                        const SizedBox(height: 18),
                        _ExercisePromo(onTap: () => onNavigate(6)),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 6,
                            child: _LearningPromo(onTap: () => onNavigate(1))),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: _ExercisePromo(onTap: () => onNavigate(6)),
                        ),
                      ],
                    ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 22,
                    runSpacing: 12,
                    children: [
                      _MiniStat(
                          icon: Icons.description_outlined,
                          label: '$phraseCount phrases'),
                      _MiniStat(
                          icon: Icons.account_tree_outlined,
                          label: '$graphCount graphes'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                      'Chaque connexion est une nouvelle façon de comprendre.',
                      style: TextStyle(color: muted, fontSize: 10)),
                ],
              ),
            );
          },
        ),
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
    required this.onTap,
    this.tint = blue,
  });

  final String number;
  final IconData icon;
  final String title;
  final String text;
  final String action;
  final VoidCallback onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            side: const BorderSide(color: line),
            borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: tint.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: tint),
                    ),
                    const Spacer(),
                    Text(number,
                        style: const TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 22),
                Text(title,
                    style: const TextStyle(
                        color: ink, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          color: muted, fontSize: 11, height: 1.65)),
                ),
                const Divider(color: line, height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(action,
                          style: TextStyle(color: tint, fontSize: 11)),
                    ),
                    Icon(Icons.arrow_forward, color: tint, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _LearningPromo extends StatelessWidget {
  const _LearningPromo({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _PromoCard(
        title: 'Un peu de théorie, beaucoup de déclics.',
        subtitle: 'Les bonnes bases pour donner vie à vos premiers graphes.',
        icon: Icons.menu_book_outlined,
        onTap: onTap,
        child: Material(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.account_tree_outlined, color: blue, size: 27),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Introduction aux graphes conceptuels',
                            style: TextStyle(
                                color: ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 5),
                        Text('Comprendre les concepts et leurs relations',
                            style: TextStyle(color: muted, fontSize: 10)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: muted),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ExercisePromo extends StatelessWidget {
  const _ExercisePromo({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _PromoCard(
        title: 'À vous de jouer.',
        subtitle:
            'Une notion comprise ? Mettez-la en pratique avec nos exercices interactifs.',
        icon: Icons.assignment_outlined,
        highlighted: true,
        onTap: onTap,
        child: Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Commencer un exercice'),
          ),
        ),
      );
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 215),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFF0F5FE) : Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                Icon(icon, color: const Color(0xFF8DA8CD)),
              ],
            ),
            const SizedBox(height: 5),
            Text(subtitle,
                style:
                    const TextStyle(color: muted, fontSize: 11, height: 1.5)),
            const SizedBox(height: 17),
            child,
          ],
        ),
      );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: muted, size: 15),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: muted, fontSize: 11)),
        ],
      );
}

class LearningPage extends StatefulWidget {
  const LearningPage({super.key, required this.onOpenGraph});
  final VoidCallback onOpenGraph;

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  final Set<int> _completed = {};

  static const _lessons = [
    (
      'Introduction aux graphes conceptuels',
      'Découvrez comment organiser et relier les connaissances.',
      Icons.account_tree_outlined
    ),
    (
      'Les concepts',
      'Un concept représente une entité, un objet ou une idée.',
      Icons.crop_square_outlined
    ),
    (
      'Les relations et les arcs',
      'Une relation exprime le lien entre plusieurs concepts.',
      Icons.alt_route
    ),
    (
      'La représentation des phrases',
      'Transformez une phrase en une structure de connaissances.',
      Icons.account_tree_outlined
    ),
    (
      'La projection',
      'Retrouvez la structure d’un graphe dans un autre.',
      Icons.layers_outlined
    ),
    (
      'La généralisation',
      'Remontez du particulier vers le général.',
      Icons.north_outlined
    ),
    (
      'La spécialisation',
      'Explorez les formes particulières d’un concept.',
      Icons.south_outlined
    ),
  ];

  Future<void> _openLesson(int index) async {
    final done = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_lessons[index].$1),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_lessons[index].$2),
            const SizedBox(height: 14),
            const Text(
                'Dans un graphe conceptuel, les concepts sont représentés par des nœuds. Les relations les relient et les arcs indiquent le sens de ces liens.',
                style: TextStyle(height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Marquer comme terminée'),
          ),
        ],
      ),
    );
    if (done == true && mounted) {
      setState(() => _completed.add(index));
    }
  }

  @override
  Widget build(BuildContext context) => _PageFrame(
        breadcrumb: 'Espace pédagogique',
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(34, 40, 34, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LES FONDAMENTAUX',
                    style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Text('Apprendre les graphes conceptuels.',
                    style: TextStyle(
                        color: ink, fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 9),
                const Text(
                    'Des notions simples, des exemples concrets et de nouvelles connexions.',
                    style: TextStyle(color: muted, fontSize: 14)),
                const SizedBox(height: 33),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF4FF),
                    border: Border.all(color: line),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          color: ink, size: 24),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Votre parcours d’apprentissage',
                                style: TextStyle(
                                    color: ink, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                                '${_completed.length} leçon${_completed.length == 1 ? '' : 's'} terminée${_completed.length == 1 ? '' : 's'} sur 7 · À votre rythme, sans compte.',
                                style: const TextStyle(
                                    color: muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (constraints.maxWidth > 600)
                        SizedBox(
                          width: 180,
                          child: LinearProgressIndicator(
                            value: _completed.length / _lessons.length,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                GridView.builder(
                  itemCount: _lessons.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth < 700
                        ? 1
                        : constraints.maxWidth < 1050
                            ? 2
                            : 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: constraints.maxWidth < 700 ? 1.6 : 1.22,
                  ),
                  itemBuilder: (context, index) => _LessonCard(
                    number: index + 1,
                    title: _lessons[index].$1,
                    description: _lessons[index].$2,
                    icon: _lessons[index].$3,
                    complete: _completed.contains(index),
                    onTap: () => _openLesson(index),
                  ),
                ),
                const SizedBox(height: 23),
                FilledButton.icon(
                  onPressed: widget.onOpenGraph,
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('Créer mon premier graphe'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.complete,
    required this.onTap,
  });

  final int number;
  final String title;
  final String description;
  final IconData icon;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: complete ? blue : line),
            borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEDF3FF),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: blue),
                    ),
                    const Spacer(),
                    Text('LEÇON ${number.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: muted, fontSize: 9, letterSpacing: 1.2)),
                    if (complete)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check_circle, size: 16, color: blue),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(title,
                    style: const TextStyle(
                        color: ink, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 9),
                Expanded(
                  child: Text(description,
                      style: const TextStyle(
                          color: muted, fontSize: 12, height: 1.6)),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Text('Comprendre cette notion',
                        style: TextStyle(color: blue, fontSize: 12)),
                    SizedBox(width: 9),
                    Icon(Icons.arrow_forward, color: blue, size: 17),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class GraphEditorPage extends StatefulWidget {
  const GraphEditorPage({
    super.key,
    required this.graphs,
    required this.phrases,
    required this.onAddPhrase,
    required this.onGraphChanged,
    required this.onCreateGraph,
    required this.onSave,
    required this.onRestore,
  });

  final List<GraphDocument> graphs;
  final List<PhraseItem> phrases;
  final ValueChanged<String> onAddPhrase;
  final ValueChanged<GraphDocument> onGraphChanged;
  final ValueChanged<GraphDocument> onCreateGraph;
  final VoidCallback onSave;
  final VoidCallback onRestore;

  @override
  State<GraphEditorPage> createState() => _GraphEditorPageState();
}

class _GraphEditorPageState extends State<GraphEditorPage> {
  final _labelController = TextEditingController();
  String? _fromId;
  String? _toId;
  String? _draggedNode;
  bool _addingRelation = false;
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  GraphDocument get graph => widget.graphs.first;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  String _snapshot() => jsonEncode(graph.toJson());

  void _recordChange(VoidCallback change) {
    _undoStack.add(_snapshot());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
    setState(change);
    widget.onGraphChanged(graph);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_snapshot());
    final old = GraphDocument.fromJson(
        jsonDecode(_undoStack.removeLast()) as Map<String, dynamic>);
    setState(() {
      graph.nodes
        ..clear()
        ..addAll(old.nodes);
      graph.arcs
        ..clear()
        ..addAll(old.arcs);
      graph.phrase = old.phrase;
    });
    widget.onGraphChanged(graph);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_snapshot());
    final next = GraphDocument.fromJson(
        jsonDecode(_redoStack.removeLast()) as Map<String, dynamic>);
    setState(() {
      graph.nodes
        ..clear()
        ..addAll(next.nodes);
      graph.arcs
        ..clear()
        ..addAll(next.arcs);
      graph.phrase = next.phrase;
    });
    widget.onGraphChanged(graph);
  }

  void _beginNodeDrag(String? nodeId) {
    if (nodeId == null) return;
    _undoStack.add(_snapshot());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
    setState(() => _draggedNode = nodeId);
  }

  void _moveNode(GraphNode node, double x, double y) {
    setState(() {
      node.x = x;
      node.y = y;
    });
    widget.onGraphChanged(graph);
  }

  void _endNodeDrag() => setState(() => _draggedNode = null);

  void _addNode() {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      _notify('Saisissez un nom pour l’élément.');
      return;
    }
    final count = graph.nodes.length;
    _recordChange(() {
      graph.nodes.add(GraphNode(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        isRelation: _addingRelation,
        x: .20 + (count % 3) * .27,
        y: .22 + ((count ~/ 3) % 4) * .19,
      ));
      _labelController.clear();
    });
  }

  void _addArc() {
    if (_fromId == null || _toId == null) {
      _notify('Choisissez une origine et une destination.');
      return;
    }
    if (_fromId == _toId) {
      _notify('L’origine et la destination doivent être différentes.');
      return;
    }
    if (graph.arcs.any((arc) => arc.from == _fromId && arc.to == _toId)) {
      _notify('Cet arc existe déjà.');
      return;
    }
    final selectedRelation = graph.nodes
        .where((node) => node.isRelation)
        .cast<GraphNode?>()
        .firstWhere((node) => node?.id == _relationId, orElse: () => null);
    _recordChange(() {
      graph.arcs.add(GraphArc(
        from: _fromId!,
        to: _toId!,
        label: selectedRelation?.label ?? '',
      ));
    });
  }

  String? _relationId;

  void _deleteNode(GraphNode node) {
    _recordChange(() {
      graph.nodes.removeWhere((item) => item.id == node.id);
      graph.arcs.removeWhere((arc) => arc.from == node.id || arc.to == node.id);
      if (_fromId == node.id) _fromId = null;
      if (_toId == node.id) _toId = null;
    });
  }

  void _deleteArc(GraphArc arc) => _recordChange(
        () => graph.arcs
            .removeWhere((item) => item.from == arc.from && item.to == arc.to),
      );

  Future<void> _editNode(GraphNode node) async {
    final controller = TextEditingController(text: node.label);
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Modifier ${node.isRelation ? 'la relation' : 'le concept'}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    controller.dispose();
    if (label != null && label.trim().isNotEmpty) {
      _recordChange(() => node.label = label.trim());
    }
  }

  void _notify(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _clearGraph() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tout effacer ?'),
        content: const Text(
            'Les concepts, relations et arcs de cette représentation seront supprimés.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tout effacer')),
        ],
      ),
    );
    if (clear == true) {
      _recordChange(() {
        graph.nodes.clear();
        graph.arcs.clear();
        _fromId = null;
        _toId = null;
      });
    }
  }

  void _validate() {
    final concepts = graph.nodes.where((node) => !node.isRelation).length;
    final broken = graph.arcs.any((arc) =>
        !graph.nodes.any((node) => node.id == arc.from) ||
        !graph.nodes.any((node) => node.id == arc.to));
    _notify(broken
        ? 'Le graphe contient un arc sans extrémité valide.'
        : concepts == 0
            ? 'Ajoutez au moins un concept avant de valider.'
            : 'Graphe valide : $concepts concept${concepts > 1 ? 's' : ''}, ${graph.nodes.length - concepts} relation${graph.nodes.length - concepts == 1 ? '' : 's'} et ${graph.arcs.length} arc${graph.arcs.length == 1 ? '' : 's'}.');
  }

  Future<void> _newRepresentation() async {
    final titleController = TextEditingController();
    final phraseController = TextEditingController(
        text: widget.phrases.isEmpty ? '' : widget.phrases.first.text);
    final data = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle représentation'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(labelText: 'Nom du graphe')),
              const SizedBox(height: 12),
              TextField(
                  controller: phraseController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Phrase de départ (facultative)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, (
              titleController.text.trim().isEmpty
                  ? 'Nouvelle représentation'
                  : titleController.text.trim(),
              phraseController.text.trim()
            )),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    titleController.dispose();
    phraseController.dispose();
    if (data != null) {
      widget.onCreateGraph(GraphDocument(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: data.$1,
        phrase: data.$2,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => _PageFrame(
        breadcrumb: 'Construction manuelle · Aucune analyse automatique',
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 10, 28, 14),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: graph.id,
                        isExpanded: true,
                        items: [
                          for (final item in widget.graphs)
                            DropdownMenuItem(
                                value: item.id, child: Text(item.title))
                        ],
                        onChanged: (id) {
                          if (id == null) return;
                          final selected =
                              widget.graphs.firstWhere((item) => item.id == id);
                          setState(() {
                            widget.graphs.remove(selected);
                            widget.graphs.insert(0, selected);
                            _fromId = null;
                            _toId = null;
                            _relationId = null;
                            _undoStack.clear();
                            _redoStack.clear();
                          });
                          widget.onGraphChanged(selected);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _newRepresentation,
                    icon: const Icon(Icons.add, size: 17),
                    label: const Text('Nouvelle représentation'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
              child: _PhraseBox(
                graph: graph,
                phrases: widget.phrases,
                onAddPhrase: widget.onAddPhrase,
                onChanged: (value) => _recordChange(() => graph.phrase = value),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 900;
                  final editorPanel = _GraphControls(
                    graph: graph,
                    controller: _labelController,
                    addingRelation: _addingRelation,
                    onModeChanged: (value) =>
                        setState(() => _addingRelation = value),
                    onAddNode: _addNode,
                    fromId: _fromId,
                    toId: _toId,
                    relationId: _relationId,
                    onFromChanged: (value) => setState(() => _fromId = value),
                    onToChanged: (value) => setState(() => _toId = value),
                    onRelationChanged: (value) =>
                        setState(() => _relationId = value),
                    onAddArc: _addArc,
                    onEditNode: _editNode,
                    onDeleteNode: _deleteNode,
                    onDeleteArc: _deleteArc,
                  );
                  final canvas = _GraphCanvasPanel(
                    graph: graph,
                    canUndo: _undoStack.isNotEmpty,
                    canRedo: _redoStack.isNotEmpty,
                    onUndo: _undo,
                    onRedo: _redo,
                    onClear: _clearGraph,
                    onValidate: _validate,
                    onNodeMoved: _moveNode,
                    onEditNode: _editNode,
                    draggedNode: _draggedNode,
                    onDragStart: _beginNodeDrag,
                    onDragEnd: _endNodeDrag,
                  );
                  if (narrow) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Column(
                        children: [
                          editorPanel,
                          const SizedBox(height: 18),
                          SizedBox(height: 570, child: canvas),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 330, child: editorPanel),
                        const SizedBox(width: 22),
                        Expanded(child: canvas),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                        'Enregistrement local uniquement · Aucun compte nécessaire.',
                        style: TextStyle(color: muted, fontSize: 11)),
                  ),
                  OutlinedButton(
                      onPressed: widget.onRestore,
                      child: const Text('Restaurer')),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: widget.onSave,
                    icon: const Icon(Icons.save_outlined, size: 17),
                    label: const Text('Enregistrer localement'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PhraseBox extends StatefulWidget {
  const _PhraseBox({
    required this.graph,
    required this.phrases,
    required this.onAddPhrase,
    required this.onChanged,
  });

  final GraphDocument graph;
  final List<PhraseItem> phrases;
  final ValueChanged<String> onAddPhrase;
  final ValueChanged<String> onChanged;

  @override
  State<_PhraseBox> createState() => _PhraseBoxState();
}

class _PhraseBoxState extends State<_PhraseBox> {
  late final TextEditingController _controller;
  late String _lastPhrase;

  @override
  void initState() {
    super.initState();
    _lastPhrase = widget.graph.phrase;
    _controller = TextEditingController(text: _lastPhrase);
  }

  @override
  void didUpdateWidget(covariant _PhraseBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final phrase = widget.graph.phrase;
    if (phrase != _lastPhrase) {
      _lastPhrase = phrase;
      _controller.value = TextEditingValue(
        text: phrase,
        selection: TextSelection.collapsed(offset: phrase.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePhraseChanged(String value) {
    _lastPhrase = value;
    widget.onChanged(value);
  }

  static const _examples = [
    'Le passager réserve un billet auprès de la compagnie.',
    'Le pilote conduit l’avion vers l’aéroport.',
    'La compagnie transporte les voyageurs.',
  ];

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(11)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                    child: Text('Votre phrase — support de réflexion',
                        style: TextStyle(color: ink, fontSize: 13))),
                if (widget.phrases.isNotEmpty)
                  SizedBox(
                    width: 245,
                    child: DropdownButtonFormField<String>(
                      initialValue: widget.phrases
                              .any((item) => item.text == widget.graph.phrase)
                          ? widget.graph.phrase
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Choisir une phrase du corpus',
                      ),
                      items: [
                        for (final phrase in widget.phrases)
                          DropdownMenuItem(
                            value: phrase.text,
                            child: Text(phrase.text,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          )
                      ],
                      onChanged: (value) {
                        if (value != null) _handlePhraseChanged(value);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Écrivez une phrase sur le transport aérien…',
              ),
              onChanged: _handlePhraseChanged,
            ),
            const SizedBox(height: 8),
            const Text(
                'Repérez vous-même les concepts et les relations, puis ajoutez les arcs. Modifier cette phrase ne modifie jamais le graphe.',
                style: TextStyle(color: muted, fontSize: 11)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Phrase d’aide :',
                    style: TextStyle(color: muted, fontSize: 11)),
                for (var i = 0; i < _PhraseBoxState._examples.length; i++)
                  TextButton(
                    onPressed: () =>
                        _handlePhraseChanged(_PhraseBoxState._examples[i]),
                    child: Text('Exemple ${i + 1}',
                        style: const TextStyle(fontSize: 11)),
                  ),
                TextButton(
                  onPressed: widget.graph.phrase.trim().isEmpty
                      ? null
                      : () => widget.onAddPhrase(widget.graph.phrase),
                  child: const Text('Ajouter au corpus',
                      style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      );
}

class _GraphControls extends StatelessWidget {
  const _GraphControls({
    required this.graph,
    required this.controller,
    required this.addingRelation,
    required this.onModeChanged,
    required this.onAddNode,
    required this.fromId,
    required this.toId,
    required this.relationId,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onRelationChanged,
    required this.onAddArc,
    required this.onEditNode,
    required this.onDeleteNode,
    required this.onDeleteArc,
  });

  final GraphDocument graph;
  final TextEditingController controller;
  final bool addingRelation;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onAddNode;
  final String? fromId;
  final String? toId;
  final String? relationId;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;
  final ValueChanged<String?> onRelationChanged;
  final VoidCallback onAddArc;
  final ValueChanged<GraphNode> onEditNode;
  final ValueChanged<GraphNode> onDeleteNode;
  final ValueChanged<GraphArc> onDeleteArc;

  @override
  Widget build(BuildContext context) {
    final concepts = graph.nodes.where((node) => !node.isRelation).toList();
    final relations = graph.nodes.where((node) => node.isRelation).toList();
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(11)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('Concept'),
                    icon: Icon(Icons.crop_square_outlined)),
                ButtonSegment(
                    value: true,
                    label: Text('Relation'),
                    icon: Icon(Icons.circle_outlined)),
              ],
              selected: {addingRelation},
              onSelectionChanged: (selection) => onModeChanged(selection.first),
            ),
            const SizedBox(height: 19),
            Text(
                'Ajouter ${addingRelation ? 'une relation (ovale)' : 'un concept (rectangle)'}',
                style: const TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 9),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: addingRelation ? 'Ex. réserve' : 'Ex. Passager',
                isDense: true,
              ),
              onSubmitted: (_) => onAddNode(),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddNode,
                icon: const Icon(Icons.add, size: 17),
                label: Text(
                    'Ajouter ${addingRelation ? 'une relation' : 'un concept'}'),
              ),
            ),
            const SizedBox(height: 16),
            _SectionHeading(title: 'Éléments', count: graph.nodes.length),
            if (graph.nodes.isEmpty)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 9),
                  child: Text('Aucun élément pour le moment.',
                      style: TextStyle(color: muted, fontSize: 11)))
            else
              ...graph.nodes.map(
                (node) => _ElementRow(
                  node: node,
                  onEdit: () => onEditNode(node),
                  onDelete: () => onDeleteNode(node),
                ),
              ),
            const SizedBox(height: 12),
            _SectionHeading(title: 'Arcs orientés', count: graph.arcs.length),
            const SizedBox(height: 5),
            const Text('Origine → Destination',
                style: TextStyle(color: muted, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NodeDropdown(
                      value: fromId,
                      nodes: concepts,
                      hint: 'Origine',
                      onChanged: onFromChanged),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _NodeDropdown(
                      value: toId,
                      nodes: concepts,
                      hint: 'Destination',
                      onChanged: onToChanged),
                ),
              ],
            ),
            if (relations.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: relations.any((node) => node.id == relationId)
                    ? relationId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('Relation (facultative)'),
                items: [
                  for (final relation in relations)
                    DropdownMenuItem(
                        value: relation.id, child: Text(relation.label))
                ],
                onChanged: onRelationChanged,
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddArc,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter un arc'),
              ),
            ),
            if (graph.arcs.isNotEmpty) ...[
              const SizedBox(height: 7),
              ...graph.arcs.map((arc) {
                final from = graph.nodes
                    .where((node) => node.id == arc.from)
                    .firstOrNull;
                final to =
                    graph.nodes.where((node) => node.id == arc.to).firstOrNull;
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${from?.label ?? '?'} → ${to?.label ?? '?'}${arc.label.isEmpty ? '' : ' (${arc.label})'}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: muted, fontSize: 10)),
                    ),
                    IconButton(
                        tooltip: 'Supprimer cet arc',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onDeleteArc(arc),
                        icon: const Icon(Icons.close, size: 15)),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: ink, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(5)),
            child: Text('$count',
                style: const TextStyle(
                    color: muted, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ],
      );
}

class _ElementRow extends StatelessWidget {
  const _ElementRow({
    required this.node,
    required this.onEdit,
    required this.onDelete,
  });
  final GraphNode node;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(
              node.isRelation
                  ? Icons.circle_outlined
                  : Icons.crop_square_outlined,
              size: 16,
              color: blue),
          const SizedBox(width: 8),
          Expanded(
              child: Text(node.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ink, fontSize: 11))),
          IconButton(
              tooltip: 'Modifier ${node.label}',
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 15)),
          IconButton(
              tooltip: 'Supprimer ${node.label}',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 15)),
        ],
      );
}

class _NodeDropdown extends StatelessWidget {
  const _NodeDropdown({
    required this.value,
    required this.nodes,
    required this.hint,
    required this.onChanged,
  });
  final String? value;
  final List<GraphNode> nodes;
  final String hint;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: nodes.any((node) => node.id == value) ? value : null,
        isExpanded: true,
        decoration: const InputDecoration(isDense: true),
        hint: Text(hint, overflow: TextOverflow.ellipsis),
        items: [
          for (final node in nodes)
            DropdownMenuItem(
                value: node.id,
                child: Text(node.label,
                    maxLines: 1, overflow: TextOverflow.ellipsis))
        ],
        onChanged: nodes.isEmpty ? null : onChanged,
      );
}

class _GraphCanvasPanel extends StatelessWidget {
  const _GraphCanvasPanel({
    required this.graph,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onValidate,
    required this.onNodeMoved,
    required this.onEditNode,
    required this.draggedNode,
    required this.onDragStart,
    required this.onDragEnd,
  });

  final GraphDocument graph;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onValidate;
  final void Function(GraphNode, double, double) onNodeMoved;
  final ValueChanged<GraphNode> onEditNode;
  final String? draggedNode;
  final ValueChanged<String?> onDragStart;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(11),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Votre graphe conceptuel',
                        style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  const Text(
                      'Glisser pour déplacer · Double-cliquer pour modifier',
                      style: TextStyle(color: muted, fontSize: 10)),
                ],
              ),
            ),
            const Divider(height: 1, color: line),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onPanStart: (details) {
                      final node = _hitNode(details.localPosition, size);
                      onDragStart(node?.id);
                    },
                    onPanUpdate: (details) {
                      final id = draggedNode;
                      if (id == null || size.width == 0 || size.height == 0) {
                        return;
                      }
                      final node =
                          graph.nodes.firstWhere((item) => item.id == id);
                      onNodeMoved(
                        node,
                        (details.localPosition.dx / size.width)
                            .clamp(.06, .94)
                            .toDouble(),
                        (details.localPosition.dy / size.height)
                            .clamp(.08, .92)
                            .toDouble(),
                      );
                    },
                    onPanEnd: (_) => onDragEnd(),
                    onDoubleTapDown: (details) {
                      final node = _hitNode(details.localPosition, size);
                      if (node != null) onEditNode(node);
                    },
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _InteractiveGraphPainter(graph: graph),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: line),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: canUndo ? onUndo : null,
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Annuler'),
                  ),
                  TextButton.icon(
                    onPressed: canRedo ? onRedo : null,
                    icon: const Icon(Icons.redo, size: 16),
                    label: const Text('Refaire'),
                  ),
                  const Spacer(),
                  TextButton(
                      onPressed: onClear, child: const Text('Tout effacer')),
                ],
              ),
            ),
            const Divider(height: 1, color: line),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            '${graph.nodes.where((node) => !node.isRelation).length} concepts · ${graph.nodes.where((node) => node.isRelation).length} relations · ${graph.arcs.length} arcs',
                            style: const TextStyle(color: muted, fontSize: 11)),
                      ),
                      OutlinedButton(
                          onPressed: onValidate, child: const Text('Valider')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'Rectangle = concept · Ovale = relation · Flèche = arc orienté.\nUne relation se place entre deux concepts. Glissez les éléments pour les déplacer.',
                        style: TextStyle(
                            color: muted, fontSize: 10, height: 1.55)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  GraphNode? _hitNode(Offset position, Size size) {
    for (final node in graph.nodes.reversed) {
      final center = Offset(node.x * size.width, node.y * size.height);
      final width = node.isRelation ? 125.0 : 155.0;
      final height = node.isRelation ? 48.0 : 60.0;
      if ((position - center).dx.abs() <= width / 2 &&
          (position - center).dy.abs() <= height / 2) {
        return node;
      }
    }
    return null;
  }
}

class _InteractiveGraphPainter extends CustomPainter {
  _InteractiveGraphPainter({required this.graph});
  final GraphDocument graph;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFFCFDFE);
    canvas.drawRect(Offset.zero & size, background);
    final dots = Paint()
      ..color = const Color(0xFFDDE7F5)
      ..strokeWidth = 1.5;
    for (double x = 10; x < size.width; x += 20) {
      for (double y = 10; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), 1, dots);
      }
    }

    final nodeById = {for (final node in graph.nodes) node.id: node};
    for (final arc in graph.arcs) {
      final from = nodeById[arc.from];
      final to = nodeById[arc.to];
      if (from == null || to == null) continue;
      final start = Offset(from.x * size.width, from.y * size.height);
      final end = Offset(to.x * size.width, to.y * size.height);
      _drawArrow(canvas, start, end, from, to);
      if (arc.label.isNotEmpty) {
        final middle = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        _drawText(canvas, arc.label, middle.translate(0, -12),
            const TextStyle(color: Color(0xFF5795A5), fontSize: 10));
      }
    }

    for (final node in graph.nodes) {
      final center = Offset(node.x * size.width, node.y * size.height);
      final rect = Rect.fromCenter(
        center: center,
        width: node.isRelation ? 125 : 155,
        height: node.isRelation ? 48 : 60,
      );
      final radius = node.isRelation ? rect.height / 2 : 8.0;
      final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      final borderColor =
          node.isRelation ? const Color(0xFF81CFD9) : const Color(0xFFBBD0F6);
      canvas.drawRRect(shape, Paint()..color = Colors.white);
      canvas.drawRRect(
          shape,
          Paint()
            ..color = borderColor
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);
      _drawText(
        canvas,
        node.label,
        center,
        TextStyle(
            color: node.isRelation ? const Color(0xFF278497) : ink,
            fontSize: 12,
            fontWeight: FontWeight.w600),
        maxWidth: rect.width - 16,
      );
    }
    if (graph.nodes.isEmpty) {
      _drawText(
        canvas,
        'Ajoutez un concept, une relation, puis leurs arcs.',
        Offset(size.width / 2, size.height / 2),
        const TextStyle(color: muted, fontSize: 13),
        maxWidth: size.width - 24,
      );
    }
  }

  void _drawArrow(
      Canvas canvas, Offset start, Offset end, GraphNode from, GraphNode to) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance < 1) return;
    final direction = delta / distance;
    final fromRadius = from.isRelation ? 62.5 : 77.5;
    final toRadius = to.isRelation ? 62.5 : 77.5;
    final startPoint = start + direction * fromRadius;
    final endPoint = end - direction * toRadius;
    final paint = Paint()
      ..color = const Color(0xFF8CB2D5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(startPoint, endPoint, paint);
    final angle = math.atan2(direction.dy, direction.dx);
    const arrowLength = 8.0;
    final wing1 = Offset(endPoint.dx - arrowLength * math.cos(angle - .45),
        endPoint.dy - arrowLength * math.sin(angle - .45));
    final wing2 = Offset(endPoint.dx - arrowLength * math.cos(angle + .45),
        endPoint.dy - arrowLength * math.sin(angle + .45));
    canvas.drawLine(endPoint, wing1, paint);
    canvas.drawLine(endPoint, wing2, paint);
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style,
      {double maxWidth = 220}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas,
        Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _InteractiveGraphPainter oldDelegate) =>
      oldDelegate.graph != graph;
}

class _ToolPage extends StatelessWidget {
  const _ToolPage({
    required this.title,
    required this.subtitle,
    required this.body,
  });
  final String title;
  final String subtitle;
  final Widget body;

  @override
  Widget build(BuildContext context) => _PageFrame(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(34, 36, 34, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: ink, fontSize: 29, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: const TextStyle(color: muted, fontSize: 13)),
              const SizedBox(height: 27),
              body,
            ],
          ),
        ),
      );
}

class ProjectionPage extends StatefulWidget {
  const ProjectionPage(
      {super.key, required this.graphs, required this.onCreateGraph});
  final List<GraphDocument> graphs;
  final ValueChanged<GraphDocument> onCreateGraph;

  @override
  State<ProjectionPage> createState() => _ProjectionPageState();
}

class _ProjectionPageState extends State<ProjectionPage> {
  String? _graphId;
  final Set<String> _selected = {};
  String? _result;

  @override
  Widget build(BuildContext context) {
    final graph =
        widget.graphs.where((item) => item.id == _graphId).firstOrNull;
    return _ToolPage(
      title: 'Projection',
      subtitle:
          'Conservez les concepts utiles et leurs arcs dans un nouveau graphe.',
      body: _ToolCard(
        title: 'Projeter un graphe',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GraphPicker(
                graphs: widget.graphs,
                value: graph?.id,
                onChanged: (value) => setState(() {
                      _graphId = value;
                      _selected.clear();
                      _result = null;
                    })),
            if (graph != null) ...[
              const SizedBox(height: 15),
              const Text('Choisissez les concepts à conserver :',
                  style: TextStyle(color: muted, fontSize: 12)),
              for (final node in graph.nodes.where((item) => !item.isRelation))
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _selected.contains(node.id),
                  title: Text(node.label),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selected.add(node.id);
                    } else {
                      _selected.remove(node.id);
                    }
                    _result = null;
                  }),
                ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () {
                        final sourceNodes = graph.nodes
                            .where((node) => _selected.contains(node.id))
                            .toList();
                        final sourceToProjectionId = {
                          for (final node in sourceNodes)
                            node.id: '${graph.id}-projection-${node.id}'
                        };
                        final nodes = sourceNodes
                            .map((node) => GraphNode(
                                  id: sourceToProjectionId[node.id]!,
                                  label: node.label,
                                  isRelation: false,
                                  x: node.x,
                                  y: node.y,
                                ))
                            .toList();
                        final arcs = graph.arcs
                            .where((arc) =>
                                _selected.contains(arc.from) &&
                                _selected.contains(arc.to))
                            .map((arc) => GraphArc(
                                  from: sourceToProjectionId[arc.from]!,
                                  to: sourceToProjectionId[arc.to]!,
                                  label: arc.label,
                                ))
                            .toList();
                        final projection = GraphDocument(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          title: 'Projection de ${graph.title}',
                          phrase: graph.phrase,
                          nodes: nodes,
                          arcs: arcs,
                        );
                        widget.onCreateGraph(projection);
                        setState(() => _result =
                            'Projection créée avec ${nodes.length} concept(s) et ${arcs.length} arc(s). Ouvrez la représentation pour la compléter.');
                      },
                icon: const Icon(Icons.layers_outlined),
                label: const Text('Créer la projection'),
              ),
              if (_result != null)
                Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(_result!, style: const TextStyle(color: blue))),
            ],
          ],
        ),
      ),
    );
  }
}

class GeneralizationPage extends StatefulWidget {
  const GeneralizationPage({super.key, required this.graphs});
  final List<GraphDocument> graphs;

  @override
  State<GeneralizationPage> createState() => _GeneralizationPageState();
}

class _GeneralizationPageState extends State<GeneralizationPage> {
  static const _knownParents = <String, String>{
    'Airbus A320': 'Avion commercial',
    'Boeing 737': 'Avion commercial',
    'Avion commercial': 'Avion',
    'Avion cargo': 'Avion',
    'Avion privé': 'Avion',
    'Hélicoptère': 'Aéronef',
    'Avion': 'Moyen de transport',
    'Aéronef': 'Moyen de transport',
    'Train': 'Moyen de transport',
    'Bateau': 'Moyen de transport',
    'Air Algérie': 'Compagnie aérienne',
    'Compagnie régionale': 'Compagnie aérienne',
    'Passager': 'Personne',
    'Pilote': 'Personne',
    'Aéroport international': 'Aéroport',
    'Aéroport régional': 'Aéroport',
  };

  static const _suggestedConcepts = [
    'Avion',
    'Hélicoptère',
    'Avion commercial',
    'Avion cargo',
    'Avion privé',
    'Airbus A320',
    'Boeing 737',
    'Air Algérie',
    'Compagnie régionale',
    'Passager',
    'Pilote',
    'Aéroport international',
    'Aéroport régional',
    'Aéronef',
    'Moyen de transport',
    'Compagnie aérienne',
    'Personne',
    'Aéroport',
    'Train',
    'Bateau',
  ];

  String _selectedConcept = 'Airbus A320';
  List<String> _ancestors = [];
  String? _message;

  List<String> get _conceptOptions {
    final values = [..._suggestedConcepts];
    for (final graph in widget.graphs) {
      for (final node in graph.nodes.where((item) => !item.isRelation)) {
        if (!values.contains(node.label)) values.add(node.label);
      }
    }
    return values;
  }

  void _selectConcept(String? concept) {
    if (concept == null) return;
    setState(() {
      _selectedConcept = concept;
      _ancestors = [];
      _message = null;
    });
  }

  void _generalize() {
    var current = _ancestors.isEmpty ? _selectedConcept : _ancestors.last;
    final newAncestors = <String>[];
    final visited = {_selectedConcept, ..._ancestors};
    while (true) {
      final parent = _knownParents[current];
      if (parent == null) break;
      if (!visited.add(parent)) break;
      newAncestors.add(parent);
      current = parent;
    }
    if (newAncestors.isEmpty) {
      setState(() =>
          _message = 'Aucune catégorie parente proposée pour « $current ».');
      return;
    }
    setState(() {
      _ancestors.addAll(newAncestors);
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) => _PageFrame(
        showHeader: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 920;
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ESPACE D’EXPLORATION',
                    style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                        color: ink,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1),
                    children: [
                      TextSpan(text: 'Généralisation'),
                      TextSpan(text: '.', style: TextStyle(color: blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                    'Explorez comment passer d’une connaissance particulière à une connaissance plus générale.',
                    style: TextStyle(color: muted, fontSize: 14)),
              ],
            );
            final controls = _GeneralizationControls(
              concept: _selectedConcept,
              concepts: _conceptOptions,
              message: _message,
              onConceptChanged: _selectConcept,
              onGeneralize: _generalize,
            );
            final hierarchy = _GeneralizationHierarchy(
              initialConcept: _selectedConcept,
              ancestors: _ancestors,
            );

            if (compact) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    const SizedBox(height: 30),
                    controls,
                    const SizedBox(height: 20),
                    SizedBox(height: 520, child: hierarchy),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(60, 58, 34, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  const SizedBox(height: 38),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 357, child: controls),
                        const SizedBox(width: 30),
                        Expanded(child: hierarchy),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

class _GeneralizationControls extends StatelessWidget {
  const _GeneralizationControls({
    required this.concept,
    required this.concepts,
    required this.message,
    required this.onConceptChanged,
    required this.onGeneralize,
  });

  final String concept;
  final List<String> concepts;
  final String? message;
  final ValueChanged<String?> onConceptChanged;
  final VoidCallback onGeneralize;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xFFEDF3FF),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.north_outlined, color: blue),
              ),
              const SizedBox(height: 27),
              const Text('Prenez de la hauteur.',
                  style: TextStyle(
                      color: ink, fontSize: 23, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              const Text(
                  'Choisissez une connaissance précise, puis découvrez toutes ses catégories parentes, du plus proche au plus général.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.7)),
              const SizedBox(height: 30),
              const Text('Concept initial',
                  style: TextStyle(color: muted, fontSize: 12)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey(concept),
                initialValue: concept,
                isExpanded: true,
                decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 15, vertical: 15)),
                items: [
                  for (final option in concepts)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: onConceptChanged,
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: onGeneralize,
                  icon: const Icon(Icons.north, size: 20),
                  label: const Text('Généraliser',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(message!,
                    style: const TextStyle(color: muted, fontSize: 11)),
              ],
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(19, 18, 19, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF4FF),
                  border: Border.all(color: const Color(0xFFD8E5FF)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                    'Un concept spécialisé hérite des propriétés de son concept parent.',
                    style: TextStyle(
                        color: Color(0xFF5578AA), fontSize: 12, height: 1.65)),
              ),
            ],
          ),
        ),
      );
}

class _GeneralizationHierarchy extends StatelessWidget {
  const _GeneralizationHierarchy({
    required this.initialConcept,
    required this.ancestors,
  });

  final String initialConcept;
  final List<String> ancestors;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Hiérarchie des concepts',
                        style: TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text('Du particulier au général',
                      style: TextStyle(color: muted, fontSize: 10)),
                ],
              ),
            ),
            const Divider(height: 1, color: line),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final concepts = [initialConcept, ...ancestors];
                  final minHeight = concepts.length == 1 ? 410.0 : 0.0;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: const _HierarchyPainter(links: []),
                        ),
                      ),
                      SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: math
                                  .max(constraints.maxHeight, minHeight)
                                  .toDouble()),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 30, 18, 30),
                            child: Column(
                              mainAxisAlignment: concepts.length == 1
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                              children: [
                                _GeneralizationNodeCard(
                                  concept: initialConcept,
                                  initial: true,
                                ),
                                if (ancestors.isEmpty) ...[
                                  const SizedBox(height: 26),
                                  const Icon(Icons.arrow_downward,
                                      color: Color(0xFF8DA8CD), size: 16),
                                  const SizedBox(height: 22),
                                  Container(
                                    constraints:
                                        const BoxConstraints(minHeight: 68),
                                    width: 256,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: .93),
                                      border: Border.all(
                                          color: const Color(0xFFCBD9EF)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                        'Votre exploration commence ici.',
                                        style: TextStyle(
                                            color: muted, fontSize: 13)),
                                  ),
                                ] else
                                  for (final ancestor in ancestors) ...[
                                    const SizedBox(height: 20),
                                    const Icon(Icons.arrow_downward,
                                        color: Color(0xFF8DA8CD), size: 16),
                                    const SizedBox(height: 20),
                                    _GeneralizationNodeCard(
                                      concept: ancestor,
                                      initial: false,
                                    ),
                                  ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _GeneralizationNodeCard extends StatelessWidget {
  const _GeneralizationNodeCard({
    required this.concept,
    required this.initial,
  });

  final String concept;
  final bool initial;

  @override
  Widget build(BuildContext context) => Container(
        width: 175,
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: initial ? const Color(0xFFEDF4FF) : const Color(0xFFEAF9FB),
          border: Border.all(
              color:
                  initial ? const Color(0xFF8CB2FF) : const Color(0xFF8AD4DE)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(concept,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: initial ? ink : const Color(0xFF278497),
                    fontSize: 14)),
            const SizedBox(height: 8),
            Text(initial ? 'CONCEPT INITIAL' : 'CONCEPT GÉNÉRALISÉ',
                maxLines: 1,
                style: const TextStyle(
                    color: muted, fontSize: 8, letterSpacing: 1.1)),
          ],
        ),
      );
}

class SpecializationPage extends StatefulWidget {
  const SpecializationPage({super.key, required this.graphs});
  final List<GraphDocument> graphs;

  @override
  State<SpecializationPage> createState() => _SpecializationPageState();
}

class _SpecializationPageState extends State<SpecializationPage> {
  static const _knownBranches = <String, List<String>>{
    'Moyen de transport': ['Avion', 'Train', 'Bateau'],
    'Avion': ['Avion commercial', 'Avion cargo', 'Avion privé'],
    'Avion commercial': ['Airbus A320', 'Boeing 737'],
    'Avion cargo': ['Boeing 747 cargo', 'Airbus Beluga'],
    'Avion privé': ['Jet privé', 'Avion léger'],
    'Compagnie aérienne': ['Air Algérie', 'Air France'],
    'Personne': ['Passager', 'Pilote'],
    'Aéroport': ['Aéroport international', 'Aéroport régional'],
    'Airbus A320': ['A320-200', 'A320neo'],
    'Train': ['Train régional', 'Train à grande vitesse'],
    'Bateau': ['Navire de croisière', 'Cargo maritime'],
  };

  static const _suggestedConcepts = [
    'Moyen de transport',
    'Avion',
    'Avion commercial',
    'Compagnie aérienne',
    'Personne',
    'Aéroport',
  ];

  String _selectedConcept = 'Avion';
  late _HierarchyConcept _root = _HierarchyConcept(_selectedConcept);
  String? _message;

  List<String> get _conceptOptions {
    final values = [..._suggestedConcepts];
    for (final graph in widget.graphs) {
      for (final node in graph.nodes.where((item) => !item.isRelation)) {
        if (!values.contains(node.label)) values.add(node.label);
      }
    }
    return values;
  }

  void _selectConcept(String? concept) {
    if (concept == null) return;
    setState(() {
      _selectedConcept = concept;
      _root = _HierarchyConcept(concept);
      _message = null;
    });
  }

  void _specialize() {
    final target = _findConcept(_root, _selectedConcept);
    if (target == null) return;
    final branches = _knownBranches[target.label];
    if (branches == null || branches.isEmpty) {
      setState(() => _message =
          'Aucune sous-catégorie proposée pour « ${target.label} ».');
      return;
    }
    if (target.children.isNotEmpty) {
      setState(() => _message =
          'Les formes spécifiques de « ${target.label} » sont déjà affichées.');
      return;
    }
    setState(() {
      target.children.addAll(branches.map(_HierarchyConcept.new));
      _message = null;
    });
  }

  _HierarchyConcept? _findConcept(_HierarchyConcept node, String label) {
    if (node.label == label) return node;
    for (final child in node.children) {
      final found = _findConcept(child, label);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => _PageFrame(
        showHeader: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 920;
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ESPACE D’EXPLORATION',
                    style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                        color: ink,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1),
                    children: [
                      TextSpan(text: 'Spécialisation'),
                      TextSpan(text: '.', style: TextStyle(color: blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                    'Découvrez les différentes formes spécifiques d’un concept général.',
                    style: TextStyle(color: muted, fontSize: 14)),
              ],
            );
            final controls = _SpecializationControls(
              concept: _selectedConcept,
              concepts: _conceptOptions,
              message: _message,
              onConceptChanged: _selectConcept,
              onSpecialize: _specialize,
            );
            final hierarchy = _HierarchyPanel(
              root: _root,
              selectedConcept: _selectedConcept,
              onSelect: (concept) => setState(() {
                _selectedConcept = concept;
                _message = null;
              }),
            );

            if (compact) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    const SizedBox(height: 30),
                    controls,
                    const SizedBox(height: 20),
                    SizedBox(height: 520, child: hierarchy),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(60, 58, 34, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  const SizedBox(height: 38),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 357, child: controls),
                        const SizedBox(width: 30),
                        Expanded(child: hierarchy),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

class _HierarchyConcept {
  _HierarchyConcept(this.label);

  final String label;
  final List<_HierarchyConcept> children = [];
}

class _SpecializationControls extends StatelessWidget {
  const _SpecializationControls({
    required this.concept,
    required this.concepts,
    required this.message,
    required this.onConceptChanged,
    required this.onSpecialize,
  });

  final String concept;
  final List<String> concepts;
  final String? message;
  final ValueChanged<String?> onConceptChanged;
  final VoidCallback onSpecialize;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xFFEDF3FF),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.south_outlined, color: blue),
              ),
              const SizedBox(height: 27),
              const Text('Explorez les branches.',
                  style: TextStyle(
                      color: ink, fontSize: 23, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              const Text(
                  'Choisissez un concept général pour découvrir ses formes particulières.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.7)),
              const SizedBox(height: 30),
              const Text('Concept général',
                  style: TextStyle(color: muted, fontSize: 12)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey(concept),
                initialValue: concept,
                isExpanded: true,
                decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 15, vertical: 15)),
                items: [
                  for (final option in concepts)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: onConceptChanged,
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: onSpecialize,
                  icon: const Icon(Icons.south, size: 20),
                  label: const Text('Spécialiser',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(message!,
                    style: const TextStyle(color: muted, fontSize: 11)),
              ],
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(19, 18, 19, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF4FF),
                  border: Border.all(color: const Color(0xFFD8E5FF)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                    'Un concept spécialisé hérite des propriétés de son concept parent.',
                    style: TextStyle(
                        color: Color(0xFF5578AA), fontSize: 12, height: 1.65)),
              ),
            ],
          ),
        ),
      );
}

class _HierarchyPanel extends StatelessWidget {
  const _HierarchyPanel({
    required this.root,
    required this.selectedConcept,
    required this.onSelect,
  });

  final _HierarchyConcept root;
  final String selectedConcept;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Hiérarchie des concepts',
                        style: TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text('Du général au particulier',
                      style: TextStyle(color: muted, fontSize: 10)),
                ],
              ),
            ),
            const Divider(height: 1, color: line),
            Expanded(
              child: _HierarchyCanvas(
                root: root,
                selectedConcept: selectedConcept,
                onSelect: onSelect,
              ),
            ),
          ],
        ),
      );
}

class _HierarchyCanvas extends StatelessWidget {
  const _HierarchyCanvas({
    required this.root,
    required this.selectedConcept,
    required this.onSelect,
  });

  final _HierarchyConcept root;
  final String selectedConcept;
  final ValueChanged<String> onSelect;

  List<List<_HierarchyConcept>> _levels() {
    final result = <List<_HierarchyConcept>>[];
    var current = <_HierarchyConcept>[root];
    while (current.isNotEmpty) {
      result.add(current);
      current = [
        for (final node in current) ...node.children,
      ];
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final levels = _levels();
          final widestLevel = levels.fold<int>(
              1,
              (maxCount, level) =>
                  maxCount > level.length ? maxCount : level.length);
          final canvasWidth = math
              .max(constraints.maxWidth, widestLevel * 190.0 + 40)
              .toDouble();
          const cardWidth = 175.0;
          const cardHeight = 96.0;
          const levelGap = 160.0;
          const top = 60.0;
          final canvasHeight = math
              .max(460.0, top + (levels.length - 1) * levelGap + 100)
              .toDouble();
          final centers = <_HierarchyConcept, Offset>{};
          final links = <(Offset, Offset)>[];

          for (var depth = 0; depth < levels.length; depth++) {
            final level = levels[depth];
            for (var index = 0; index < level.length; index++) {
              centers[level[index]] = Offset(
                canvasWidth * (index + .5) / level.length,
                top + depth * levelGap + cardHeight / 2,
              );
            }
          }
          for (var depth = 0; depth < levels.length - 1; depth++) {
            for (final parent in levels[depth]) {
              final parentCenter = centers[parent]!;
              for (final child in parent.children) {
                final childCenter = centers[child]!;
                links.add((
                  Offset(parentCenter.dx, parentCenter.dy + cardHeight / 2),
                  Offset(childCenter.dx, childCenter.dy - cardHeight / 2),
                ));
              }
            }
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HierarchyPainter(links: links),
                    ),
                  ),
                  for (var depth = 0; depth < levels.length; depth++)
                    for (final node in levels[depth])
                      Positioned(
                        left: centers[node]!.dx - cardWidth / 2,
                        top: centers[node]!.dy - cardHeight / 2,
                        width: cardWidth,
                        height: cardHeight,
                        child: _HierarchyNodeCard(
                          concept: node.label,
                          initial: identical(node, root),
                          selected: node.label == selectedConcept,
                          onTap: () => onSelect(node.label),
                        ),
                      ),
                  if (root.children.isEmpty)
                    Positioned(
                      left: canvasWidth / 2 - 128,
                      top: top + levelGap - 35,
                      width: 256,
                      height: 70,
                      child: IgnorePointer(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .93),
                            border: Border.all(
                                color: const Color(0xFFCBD9EF),
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Votre exploration commence ici.',
                              style: TextStyle(color: muted, fontSize: 13)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
}

class _HierarchyNodeCard extends StatelessWidget {
  const _HierarchyNodeCard({
    required this.concept,
    required this.initial,
    required this.selected,
    required this.onTap,
  });

  final String concept;
  final bool initial;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFFEDF4FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: selected
                      ? const Color(0xFF8CB2FF)
                      : const Color(0xFFD6E2F4)),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(concept,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ink, fontSize: 14)),
                const SizedBox(height: 8),
                Text(initial ? 'CONCEPT INITIAL' : 'CONCEPT SPÉCIFIQUE',
                    maxLines: 1,
                    style: const TextStyle(
                        color: muted, fontSize: 8, letterSpacing: 1.1)),
              ],
            ),
          ),
        ),
      );
}

class _HierarchyPainter extends CustomPainter {
  const _HierarchyPainter({required this.links});

  final List<(Offset, Offset)> links;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFFCFDFE);
    canvas.drawRect(Offset.zero & size, background);
    final dots = Paint()
      ..color = const Color(0xFFDDE7F5)
      ..strokeWidth = 1.5;
    for (double x = 10; x < size.width; x += 20) {
      for (double y = 10; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), 1, dots);
      }
    }
    final connector = Paint()
      ..color = const Color(0xFFB7CBE5)
      ..strokeWidth = 1.2;
    for (final (start, end) in links) {
      canvas.drawLine(start, end, connector);
    }
  }

  @override
  bool shouldRepaint(covariant _HierarchyPainter oldDelegate) => true;
}

class _GraphPicker extends StatelessWidget {
  const _GraphPicker({
    required this.graphs,
    required this.value,
    required this.onChanged,
  });
  final List<GraphDocument> graphs;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (graphs.isEmpty) {
      return const Text('Créez d’abord une représentation.',
          style: TextStyle(color: muted));
    }
    return DropdownButtonFormField<String>(
      initialValue: graphs.any((graph) => graph.id == value) ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Graphe source'),
      items: [
        for (final graph in graphs)
          DropdownMenuItem(value: graph.id, child: Text(graph.title))
      ],
      onChanged: onChanged,
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: ink, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            child,
          ],
        ),
      );
}

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  static const _exercises = [
    _ExerciseData(
      title: 'Identifier les concepts',
      question:
          'Dans « Un passager réserve un billet », lequel est un concept ?',
      options: ['Réserve', 'Passager', 'Un'],
      correctOption: 1,
      icon: Icons.menu_book_outlined,
      explanation:
          '« Passager » désigne une entité. « Réserve » exprime une relation et « un » est un déterminant.',
    ),
    _ExerciseData(
      title: 'Identifier les relations',
      question:
          'Quel mot relie Pilote et Avion dans « Un pilote pilote un avion » ?',
      options: ['Un', 'Avion', 'Pilote (le verbe)'],
      correctOption: 2,
      icon: Icons.account_tree_outlined,
      explanation:
          'Le verbe « pilote » exprime la relation orientée entre le concept Pilote et le concept Avion.',
    ),
    _ExerciseData(
      title: 'Représenter une phrase',
      question:
          'Quelle structure représente « Un avion transporte un bagage » ?',
      options: [
        'Avion → transporte → Bagage',
        'Bagage → pilote → Avion',
        'Avion → réserve → Billet',
      ],
      correctOption: 0,
      icon: Icons.layers_outlined,
      explanation:
          'Avion et Bagage sont les concepts ; « transporte » est la relation qui les relie.',
    ),
    _ExerciseData(
      title: 'Trouver une projection',
      question:
          'Le graphe « Passager → réserve → Billet » se projette-t-il dans un graphe contenant cette même structure et un Aéroport ?',
      options: [
        'Non, il a trop de concepts',
        'Oui, la structure recherchée y est présente',
        'Seulement sans l’aéroport',
      ],
      correctOption: 1,
      icon: Icons.north_outlined,
      explanation:
          'Une projection existe si la structure recherchée est présente. Des concepts supplémentaires dans le graphe cible ne l’empêchent pas.',
    ),
    _ExerciseData(
      title: 'Généraliser un concept',
      question: 'Quel est le concept plus général pour Airbus A320 ?',
      options: ['Billet', 'Air Algérie', 'Avion commercial'],
      correctOption: 2,
      icon: Icons.south_outlined,
      explanation:
          'Airbus A320 est un avion commercial : « Avion commercial » est donc le concept plus général.',
    ),
    _ExerciseData(
      title: 'Spécialiser un concept',
      question: 'Quel concept est une spécialisation de « Avion » ?',
      options: ['Airbus A320', 'Transporter', 'Compagnie aérienne'],
      correctOption: 0,
      icon: Icons.assignment_outlined,
      explanation:
          'Airbus A320 est un type particulier d’avion. C’est une spécialisation du concept Avion.',
    ),
  ];

  final Set<int> _completed = {};
  int? _activeExercise;
  int? _selectedOption;
  bool _answerChecked = false;
  bool _answerIsCorrect = false;

  void _openExercise(int index) {
    setState(() {
      _activeExercise = index;
      _selectedOption = null;
      _answerChecked = false;
      _answerIsCorrect = false;
    });
  }

  void _returnToExercises() {
    setState(() {
      _activeExercise = null;
      _selectedOption = null;
      _answerChecked = false;
      _answerIsCorrect = false;
    });
  }

  void _checkAnswer() {
    final selected = _selectedOption;
    final index = _activeExercise;
    if (selected == null || index == null || _answerChecked) return;
    final isCorrect = selected == _exercises[index].correctOption;
    setState(() {
      _answerChecked = true;
      _answerIsCorrect = isCorrect;
      if (isCorrect) _completed.add(index);
    });
  }

  @override
  Widget build(BuildContext context) => _PageFrame(
        breadcrumb: _activeExercise == null
            ? 'Espace pédagogique'
            : 'Espace pédagogique · Exercices',
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(34, 34, 34, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    _activeExercise == null
                        ? 'APPRENDRE EN PRATIQUANT'
                        : 'EXERCICE ${(_activeExercise! + 1).toString().padLeft(2, '0')} · ${_exercises[_activeExercise!].title.toUpperCase()}',
                    style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 13),
                Text(
                    _activeExercise == null
                        ? 'À vous de jouer.'
                        : _exercises[_activeExercise!].title,
                    style: const TextStyle(
                        color: ink, fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 9),
                Text(
                    _activeExercise == null
                        ? 'Testez vos connaissances. Chaque essai est une occasion de progresser.'
                        : 'Sélectionnez une réponse, puis vérifiez votre raisonnement.',
                    style: const TextStyle(color: muted, fontSize: 14)),
                const SizedBox(height: 32),
                _ExerciseProgress(
                    completed: _completed.length, total: _exercises.length),
                const SizedBox(height: 25),
                if (_activeExercise == null)
                  _ExerciseCatalogue(
                    exercises: _exercises,
                    completed: _completed,
                    availableWidth: constraints.maxWidth,
                    onOpen: _openExercise,
                  )
                else
                  _ExerciseQuestionCard(
                    exercise: _exercises[_activeExercise!],
                    number: _activeExercise! + 1,
                    selectedOption: _selectedOption,
                    answerChecked: _answerChecked,
                    answerIsCorrect: _answerIsCorrect,
                    onBack: _returnToExercises,
                    onSelect: (option) => setState(() {
                      _selectedOption = option;
                      _answerChecked = false;
                    }),
                    onCheck: _checkAnswer,
                  ),
              ],
            ),
          ),
        ),
      );
}

class _ExerciseData {
  const _ExerciseData({
    required this.title,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.icon,
    required this.explanation,
  });

  final String title;
  final String question;
  final List<String> options;
  final int correctOption;
  final IconData icon;
  final String explanation;
}

class _ExerciseProgress extends StatelessWidget {
  const _ExerciseProgress({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF4FF),
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment_outlined, color: blue, size: 23),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Votre progression dans cette session',
                      style:
                          TextStyle(color: ink, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('$completed / $total exercices réussis',
                      style: const TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
            if (MediaQuery.sizeOf(context).width > 650)
              SizedBox(
                width: math.min(235, MediaQuery.sizeOf(context).width * .2),
                child: LinearProgressIndicator(
                  value: completed / total,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
}

class _ExerciseCatalogue extends StatelessWidget {
  const _ExerciseCatalogue({
    required this.exercises,
    required this.completed,
    required this.availableWidth,
    required this.onOpen,
  });

  final List<_ExerciseData> exercises;
  final Set<int> completed;
  final double availableWidth;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final columns = availableWidth < 650
        ? 1
        : availableWidth < 1000
            ? 2
            : 3;
    return GridView.builder(
      itemCount: exercises.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: columns == 1 ? 1.65 : 1.05,
      ),
      itemBuilder: (context, index) => _ExerciseCard(
        number: index + 1,
        exercise: exercises[index],
        complete: completed.contains(index),
        onTap: () => onOpen(index),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.number,
    required this.exercise,
    required this.complete,
    required this.onTap,
  });

  final int number;
  final _ExerciseData exercise;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF3FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(exercise.icon, color: blue),
                ),
                const SizedBox(height: 24),
                Text('EXERCICE ${number.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: muted, fontSize: 9, letterSpacing: 1.2)),
                const SizedBox(height: 13),
                Text(exercise.title,
                    style: const TextStyle(
                        color: ink, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Expanded(
                  child: Text(
                      'Un exemple concret pour mettre vos connaissances à l’épreuve.',
                      style:
                          TextStyle(color: muted, fontSize: 12, height: 1.6)),
                ),
                Row(
                  children: [
                    Text(complete ? 'Réussi' : 'Commencer',
                        style: const TextStyle(
                            color: blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Icon(
                        complete
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward,
                        color: blue,
                        size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _ExerciseQuestionCard extends StatelessWidget {
  const _ExerciseQuestionCard({
    required this.exercise,
    required this.number,
    required this.selectedOption,
    required this.answerChecked,
    required this.answerIsCorrect,
    required this.onBack,
    required this.onSelect,
    required this.onCheck,
  });

  final _ExerciseData exercise;
  final int number;
  final int? selectedOption;
  final bool answerChecked;
  final bool answerIsCorrect;
  final VoidCallback onBack;
  final ValueChanged<int> onSelect;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(44, 40, 44, 44),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 15),
              label: const Text('Tous les exercices'),
            ),
            const SizedBox(height: 24),
            Text(
                'EXERCICE ${number.toString().padLeft(2, '0')} · ${exercise.title.toUpperCase()}',
                style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 15),
            Text(exercise.question,
                style: const TextStyle(
                    color: ink,
                    fontSize: 23,
                    height: 1.35,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const Text(
                'Sélectionnez une réponse, puis vérifiez votre raisonnement.',
                style: TextStyle(color: muted, fontSize: 14)),
            const SizedBox(height: 25),
            for (var index = 0; index < exercise.options.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AnswerOption(
                  letter: String.fromCharCode(65 + index),
                  text: exercise.options[index],
                  selected: selectedOption == index,
                  onTap: answerChecked && answerIsCorrect
                      ? null
                      : () => onSelect(index),
                ),
              ),
            if (answerChecked) ...[
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: answerIsCorrect
                      ? const Color(0xFFEAF7F0)
                      : const Color(0xFFFFF1EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  answerIsCorrect
                      ? 'Bonne réponse ! ${exercise.explanation}'
                      : 'Ce n’est pas la bonne réponse. ${exercise.explanation}',
                  style: TextStyle(
                    color: answerIsCorrect
                        ? const Color(0xFF24754D)
                        : const Color(0xFFAB4D42),
                    height: 1.45,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 8),
            FilledButton.icon(
              onPressed:
                  selectedOption == null || answerChecked ? null : onCheck,
              icon: const Icon(Icons.check, size: 17),
              label: const Text('Vérifier ma réponse'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              ),
            ),
          ],
        ),
      );
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFFF2F6FF) : Colors.white,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            constraints: const BoxConstraints(minHeight: 74),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? blue : line),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? blue : const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(letter,
                      style: TextStyle(
                          color: selected ? Colors.white : muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(text,
                      style: const TextStyle(color: ink, fontSize: 14)),
                ),
                if (selected)
                  const Icon(Icons.radio_button_checked, color: blue, size: 19),
              ],
            ),
          ),
        ),
      );
}
