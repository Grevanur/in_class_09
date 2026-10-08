import 'package:flutter/material.dart';
import 'database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper();
  try { await helper.init(); runApp(CardCatalogueApp(helper: helper)); }
  catch (_) { runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Could not open local storage. Restart and check logs.'))))); }
}

class CardCatalogueApp extends StatelessWidget {
  const CardCatalogueApp({super.key, required this.helper}); final DatabaseHelper helper;
  @override Widget build(BuildContext context) => MaterialApp(title: 'Card Catalogue', debugShowCheckedModeBanner: false, theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true), home: FolderScreen(helper: helper));
}

class FolderScreen extends StatefulWidget { const FolderScreen({super.key, required this.helper}); final DatabaseHelper helper; @override State<FolderScreen> createState() => _FolderScreenState(); }
class _FolderScreenState extends State<FolderScreen> {
  List<Folder> _folders = const []; bool _loading = true; bool _busy = false; String _message = '';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { setState(() => _loading = true); try { final folders = await widget.helper.getFoldersWithCounts(); if (mounted) setState(() { _folders = folders; _loading = false; }); } catch (_) { if (mounted) setState(() { _message = 'Could not load folders.'; _loading = false; }); } }
  Future<void> _addFolder() async {
    final c = TextEditingController(); final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Add folder'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Folder name')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Add'))]));
    if (name == null || name.isEmpty || _busy) { if (name != null && mounted) setState(() => _message = 'Folder name is required; nothing was saved.'); return; }
    setState(() => _busy = true); try { final id = await widget.helper.insertFolder(name); if (mounted) setState(() => _message = 'Saved folder "$name" with ID $id.'); await _load(); } catch (_) { if (mounted) setState(() => _message = 'Folder was not saved. Names must be unique.'); } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _delete(Folder f) async {
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete folder?'), content: Text('Delete "${f.name}" and its ${f.cardCount} card(s)?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
    if (yes != true || _busy) { if (mounted) setState(() => _message = 'Deletion cancelled; no data changed.'); return; }
    setState(() => _busy = true); final affected = await widget.helper.deleteFolder(f.id); if (mounted) setState(() => _message = affected == 1 ? 'Deleted "${f.name}" and its child cards.' : 'Folder was not found.'); await _load(); if (mounted) setState(() => _busy = false);
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Card Catalogue')), floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : _addFolder, icon: const Icon(Icons.create_new_folder), label: const Text('Add folder')), body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: _load, child: _folders.isEmpty ? ListView(children: const [SizedBox(height: 220), Center(child: Text('No folders yet. Add your first folder.'))]) : ListView(children: [if (_message.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(_message, textAlign: TextAlign.center)), ..._folders.map((f) => ListTile(title: Text(f.name), subtitle: Text('Folder ID ${f.id} · ${f.cardCount} card(s)'), leading: const Icon(Icons.folder), onTap: _busy ? null : () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => CardScreen(helper: widget.helper, folder: f))); _load(); }, trailing: IconButton(tooltip: 'Delete ${f.name}', onPressed: _busy ? null : () => _delete(f), icon: const Icon(Icons.delete_outline))))])));
}

class CardScreen extends StatefulWidget { const CardScreen({super.key, required this.helper, required this.folder}); final DatabaseHelper helper; final Folder folder; @override State<CardScreen> createState() => _CardScreenState(); }
class _CardScreenState extends State<CardScreen> {
  static const suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades']; List<PlayingCard> _cards = const []; bool _loading = true; bool _busy = false; String _message = '';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { setState(() => _loading = true); final cards = await widget.helper.getCards(widget.folder.id); if (mounted) setState(() { _cards = cards; _loading = false; }); }
  Future<void> _edit([PlayingCard? card]) async {
    final title = TextEditingController(text: card?.title ?? ''); final notes = TextEditingController(text: card?.notes ?? ''); final image = TextEditingController(text: card?.imageRef ?? ''); var suit = card?.suit ?? suits.first; String? error;
    final saved = await showDialog<PlayingCard>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(title: Text(card == null ? 'Add card' : 'Edit card ID ${card.id}'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: InputDecoration(labelText: 'Title', errorText: error)), DropdownButtonFormField(initialValue: suit, decoration: const InputDecoration(labelText: 'Suit'), items: suits.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setDialog(() => suit = v!)), TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes optional')), TextField(controller: image, decoration: const InputDecoration(labelText: 'Image reference optional'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (title.text.trim().isEmpty) { setDialog(() => error = 'A title is required.'); return; } Navigator.pop(context, PlayingCard(id: card?.id, title: title.text.trim(), suit: suit, notes: notes.text.trim(), imageRef: image.text.trim().isEmpty ? null : image.text.trim(), folderId: widget.folder.id)); }, child: const Text('Save'))])));
    if (saved == null || _busy) { if (mounted) setState(() => _message = 'Edit cancelled; no database row was changed.'); return; }
    setState(() => _busy = true); final affected = card == null ? await widget.helper.insertCard(saved) : await widget.helper.updateCard(saved); if (mounted) setState(() => _message = affected > 0 ? (card == null ? 'Saved card with ID $affected.' : 'Updated card ID ${card.id}.') : 'No row was changed.'); await _load(); if (mounted) setState(() => _busy = false);
  }
  Future<void> _delete(PlayingCard c) async { final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete card?'), content: Text('Delete "${c.title}" (ID ${c.id})?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))])); if (yes != true || _busy) return; setState(() => _busy = true); final affected = await widget.helper.deleteCard(c.id!); if (mounted) setState(() => _message = affected == 1 ? 'Deleted card ID ${c.id}.' : 'Card was not found.'); await _load(); if (mounted) setState(() => _busy = false); }
  String _symbol(String suit) => switch (suit) { 'Hearts' => '♥', 'Diamonds' => '♦', 'Clubs' => '♣', _ => '♠' };
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.folder.name)), floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : () => _edit(), icon: const Icon(Icons.add), label: const Text('Add card')), body: _loading ? const Center(child: CircularProgressIndicator()) : _cards.isEmpty ? const Center(child: Text('No cards in this folder yet.')) : ListView(children: [if (_message.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(_message, textAlign: TextAlign.center)), ..._cards.map((c) => ListTile(leading: CircleAvatar(child: Text(_symbol(c.suit))), title: Text(c.title), subtitle: Text('Card ID ${c.id} · ${c.suit}${c.notes.isEmpty ? '' : '\n${c.notes}'}${c.imageRef == null ? '\nImage unavailable — suit symbol used.' : ''}'), isThreeLine: c.notes.isNotEmpty || c.imageRef == null, onTap: _busy ? null : () => _edit(c), trailing: IconButton(tooltip: 'Delete ${c.title}', icon: const Icon(Icons.delete_outline), onPressed: _busy ? null : () => _delete(c))))]));
}
