class TTypePrint < ::AST::Processor
  include TypeOperations
  require_relative "../ast"

  attr_accessor :stack
  def initialize()
    @stack = []
  end


  def on_envref(node)
    @stack.append(node.ttype.to_s)
  end

  def on_send(node)

    @stack.append("(")
    node.updated(nil, node.children.map { |k|
        k.is_a?(TypedNode) ? process(k) : @stack.append(k)
        })

    @stack.append("):#{node.ttype.to_s}")
    
  end

  def on_hole(node)

    @stack.append("(hole#{node.children[0]}: #{node.ttype})")
  end

  def handler_missing(node)


    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : @stack.append(k)
    })
  end
end
