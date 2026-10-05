class TTypePrint < ::AST::Processor
  include TypeOperations
  require_relative "../ast"

  def expanded_ttype_to_s(tipe)
    str = ""
    # tipe = node.ttype

    case tipe  
    when RDL::Type::OptionalType
      str += "OPT: "
      str += expanded_ttype_to_s(tipe.type)
    when RDL::Type::SingletonType
      str += "SINGLETON:"
      str += expanded_ttype_to_s(tipe.nominal)
      str += ", VAL: "
      str += tipe.val.to_s
    when RDL::Type::FiniteHashType 
      str += "FHASH: "
      str += "Elements: "
      tipe.elts.each {|k, t| str += k.to_s; str += "=>"; str += expanded_ttype_to_s(t); str == "\n" }
    when RDL::Type::NominalType

      str += "NOMINAL: "
      str += tipe.to_s
    when RDL::Type::GenericType
      str += "GENERIC: "
      str += "BASE: "
      str += expanded_ttype_to_s(tipe.base)
      tipe.params.each {|i| str += expanded_ttype_to_s(i)}
    else
      #TODO FURTHER EXPAND UPON THESE TYPES, ELSE YOU WILL RUN INTO MORE PROBLEMS WHERE THE TO_STRING FUNCTION HAS COLLISIONS
      str += "OTHER: "
      str += tipe.to_s
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
      @stack.append(expanded_ttype_to_s(node.ttype))
    else
      ref = node.children[0]
      info = @env.get_expr(ref)
      temp = @stack.clone
      @stack = []
      processed = process(info[:expr])
      processed = "(ENV: #{@stack.join(' ')})#{expanded_ttype_to_s(node.ttype)}"
      @stack = temp
      @stack.append(processed)
    end
  end

  def on_send(node)

    @stack.append("(")
    node.updated(nil, node.children.map { |k|
        k.is_a?(TypedNode) ? process(k) : @stack.append(k)
        })

    @stack.append("):#{expanded_ttype_to_s(node.ttype)}")
    
  end

  def on_hole(node)

    @stack.append("(hole#{node.children[0]}: #{expanded_ttype_to_s(node.ttype)})")
  end

  def handler_missing(node)

    @stack.append("(")
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : @stack.append(k)
    })
    if node.children.size == 0 #Handles true and false classes
      @stack.append(node.to_s)
    end
    @stack.append("):#{expanded_ttype_to_s(node.ttype)}")

  end
end
