class InferTypeErrPass < ::AST::Processor

  attr_reader :bad_type

  def initialize(meth)
    @meth = meth
  end

  def on_send(node)
    if node.children[1] == @meth
      trecv = node.children[0].ttype
      targs = node.children[2..].map { |i| i.ttype }
      @bad_type = [trecv, @meth, *targs]
    end
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
