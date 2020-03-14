class ASTNodeCount < ::AST::Processor
  attr_reader :size

  def self.size(node)
    pass = ASTNodeCount.new
    pass.process(node)
    pass.size
  end

  def initialize
    @size = 0
  end

  def handler_missing(node)
    node.children.map { |k|
      @size += 1
      k.is_a?(node.class) ? process(k) : k
    }
  end
end
