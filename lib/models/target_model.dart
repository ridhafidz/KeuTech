class TargetModel {
  final String id;
  final String? parentId;
  final String title;
  final int targetAmount;
  final int currentAmount;

  TargetModel({
    required this.id,
    this.parentId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
  });

  double get progress =>
      targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);
}
