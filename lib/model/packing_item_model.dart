class PackingItem {

  String id;
  String name;
  bool isPacked;

  PackingItem({
    required this.id,
    required this.name,
    this.isPacked = false
  });
}
