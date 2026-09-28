/// A zero-dependency parser and evaluator for Random Forest models stored in JSON format.
///
/// This class enables dynamic loading and execution of Random Forest models
/// without relying on external machine learning libraries.
class DynamicRandomForest {
  /// The unique identifier for this model.
  final String modelId;

  /// The total number of decision trees in the forest.
  final int numTrees;

  /// The collection of decision trees, where each tree is represented as a
  /// map of node IDs to [TreeNode] objects.
  final List<Map<int, TreeNode>> trees;

  DynamicRandomForest._({
    required this.modelId,
    required this.numTrees,
    required this.trees,
  });

  /// Constructs a [DynamicRandomForest] from a JSON map.
  ///
  /// Parameters:
  /// - [json]: A map containing the serialized model structure, including
  ///   the trees and their constituent nodes.
  ///
  /// Returns:
  /// A fully initialized [DynamicRandomForest] instance.
  factory DynamicRandomForest.fromJson(Map<String, dynamic> json) {
    final rawTrees = (json['trees'] as List? ?? []);
    final parsedTrees = rawTrees.map((t) {
      final nodesRaw = (t['nodes'] as List? ?? []);
      final map = <int, TreeNode>{};
      for (final n in nodesRaw) {
        final node = TreeNode.fromJson(n);
        map[node.nodeId] = node;
      }
      return map;
    }).toList();

    return DynamicRandomForest._(
      modelId: json['model_id'] as String? ?? '',
      numTrees: json['num_trees'] as int? ?? parsedTrees.length,
      trees: parsedTrees,
    );
  }

  /// Evaluates an input feature vector against the Random Forest.
  ///
  /// Traverses each decision tree in the forest using the provided [features]
  /// and calculates the average probability scores across all trees.
  ///
  /// Parameters:
  /// - [features]: A list of double values representing the input variables
  ///   (e.g., Radiation, Humidity).
  ///
  /// Returns:
  /// A list of double values representing the averaged probability scores for
  /// each possible class.
  List<double> predict(List<double> features) {
    if (trees.isEmpty) return [0.0];
    final int numClasses = trees.first.values.firstWhere((n) => n.isLeaf).value.length;
    final List<double> classScores = List.filled(numClasses, 0.0);

    for (final treeNodesMap in trees) {
      final leaf = _traverse(treeNodesMap, 0, features);
      for (int i = 0; i < numClasses && i < leaf.value.length; i++) {
        classScores[i] += leaf.value[i];
      }
    }

    return classScores.map((s) => s / trees.length).toList();
  }

  TreeNode _traverse(Map<int, TreeNode> nodesMap, int nodeId, List<double> features) {
    final node = nodesMap[nodeId]!;
    if (node.isLeaf) return node;

    final featVal = features[node.featureIndex];
    final nextId = (featVal <= node.threshold) ? node.leftChild : node.rightChild;
    return _traverse(nodesMap, nextId, features);
  }
}

/// Represents a single node within a decision tree of a [DynamicRandomForest].
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