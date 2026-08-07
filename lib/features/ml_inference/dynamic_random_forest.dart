/// Zero-dependency JSON RF tree parser
class DynamicRandomForest {
  final String modelId;
  final int numTrees;
  final List<List<TreeNode>> trees;

  DynamicRandomForest._({
    required this.modelId,
    required this.numTrees,
    required this.trees,
  });

  factory DynamicRandomForest.fromJson(Map<String, dynamic> json) {
    final rawTrees = (json['trees'] as List? ?? []);
    final parsedTrees = rawTrees.map((t) {
      final nodesRaw = (t['nodes'] as List? ?? []);
      return nodesRaw.map((n) => TreeNode.fromJson(n)).toList();
    }).toList();

    return DynamicRandomForest._(
      modelId: json['model_id'] as String? ?? '',
      numTrees: json['num_trees'] as int? ?? parsedTrees.length,
      trees: parsedTrees,
    );
  }

  /// Evaluates input feature vector [Radiation, Humidity, ...]
  /// Returns average probabilities across all trees.
  List<double> predict(List<double> features) {
    if (trees.isEmpty) return [0.0];
    final int numClasses = trees.first.firstWhere((n) => n.isLeaf).value.length;
    final List<double> classScores = List.filled(numClasses, 0.0);

    for (final treeNodes in trees) {
      final leaf = _traverse(treeNodes, 0, features);
      for (int i = 0; i < numClasses && i < leaf.value.length; i++) {
        classScores[i] += leaf.value[i];
      }
    }

    return classScores.map((s) => s / trees.length).toList();
  }

  TreeNode _traverse(List<TreeNode> nodes, int nodeId, List<double> features) {
    final node = nodes.firstWhere((n) => n.nodeId == nodeId);
    if (node.isLeaf) return node;

    final featVal = features[node.featureIndex];
    final nextId = (featVal <= node.threshold) ? node.leftChild : node.rightChild;
    return _traverse(nodes, nextId, features);
  }
}

class TreeNode {
  final int nodeId;
  final bool isLeaf;
  final int featureIndex;
  final double threshold;
  final int leftChild;
  final int rightChild;
  final List<double> value;

  TreeNode({
    required this.nodeId,
    required this.isLeaf,
    required this.featureIndex,
    required this.threshold,
    required this.leftChild,
    required this.rightChild,
    required this.value,
  });

  factory TreeNode.fromJson(Map<String, dynamic> json) {
    return TreeNode(
      nodeId: json['node_id'] as int? ?? 0,
      isLeaf: json['is_leaf'] as bool? ?? false,
      featureIndex: json['feature_index'] as int? ?? 0,
      threshold: (json['threshold'] as num? ?? 0.0).toDouble(),
      leftChild: json['left_child'] as int? ?? 0,
      rightChild: json['right_child'] as int? ?? 0,
      value: (json['value'] as List? ?? []).map((e) => (e as num).toDouble()).toList(),
    );
  }
}