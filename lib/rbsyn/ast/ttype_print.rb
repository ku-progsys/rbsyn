class TTypePrint < ::AST::Processor
  include TypeOperations
  require_relative "../ast"

  attr_accessor :stack
  def initialize(env: [])
    @env = env
    @stack = []
  end

  def reset()
    @stack = []
  end

  def on_envref(node)
    if @env == []
      @stack.append(node.ttype.to_s)
    else
      ref = node.children[0]
      info = @env.get_expr(ref)
      temp = @stack.clone
      @stack = []
      processed = process(info[:expr])
      processed = "(ENV: #{@stack.join(' ')})#{node.ttype.to_s}"
      @stack = temp
      @stack.append(processed)
    end
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
