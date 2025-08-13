class SyncResult {
  final int totalCount;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  SyncResult({
    required this.totalCount,
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });

  bool get hasErrors => failureCount > 0;
  
  double get successRate => 
      totalCount > 0 ? successCount / totalCount : 0.0;
      
  String get summary => 
      '同步完成: 成功 $successCount/$totalCount (${(successRate * 100).toStringAsFixed(1)}%)' +
      (hasErrors ? ', 失败 $failureCount 项' : '');
}