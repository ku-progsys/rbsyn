class TTypePrint < ::AST::Processor
  include TypeOperations
  require_relative "../ast"

  def expanded_ttype_to_s(node)
    str = ""
    ttype = node.ttype
    case ttype
    when RDL::Type::SingletonType
      str += "SINGLETON: NOM: "
      str += ttype.nominal.to_s
      str += ", VAL: "
      str += ttype.val.to_s
    when RDL::Type::NominalType
      str += "NOMINAL: "
      str += ttype.to_s
    else
      #TODO FURTHER EXPAND UPON THESE TYPES, ELSE YOU WILL RUN INTO MORE PROBLEMS WHERE THE TO_STRING FUNCTION HAS COLLISIONS
      str += "OTHER: "
      str += ttype.to_s
    end
    str
  end

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
      @stack.append(expanded_ttype_to_s(node))
    else
      ref = node.children[0]
      info = @env.get_expr(ref)
      temp = @stack.clone
      @stack = []
      processed = process(info[:expr])
      processed = "(ENV: #{@stack.join(' ')})#{expanded_ttype_to_s(node)}"
      @stack = temp
      @stack.append(processed)
    end
  end

  def on_send(node)

    @stack.append("(")
    node.updated(nil, node.children.map { |k|
        k.is_a?(TypedNode) ? process(k) : @stack.append(k)
        })

    @stack.append("):#{expanded_ttype_to_s(node)}")
    
  end

  def on_hole(node)

    @stack.append("(hole#{node.children[0]}: #{expanded_ttype_to_s(node)})")
  end

  def handler_missing(node)

    @stack.append("(")
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : @stack.append(k)
    })
    if node.children.size == 0 #Handles true and false classes
      @stack.append(node.to_s)
    end
    @stack.append("):#{expanded_ttype_to_s(node)}")

  end
end
