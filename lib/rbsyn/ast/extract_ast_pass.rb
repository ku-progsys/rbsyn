class ExtractASTPass < ::AST::Processor
  def initialize(selection, old_env)
    @selection = selection
    @new_env = Marshal.load(Marshal.dump(old_env))
  end

  def on_envref(node)
    subexpr = @new_env.get_expr(node.children[0])
    subexpr[:expr] = process(subexpr[:expr])
    nil
  end

  def on_filled_hole(node)
    idx = @selection.shift
    method_arg = node.children.last.fetch(:method_arg, false)
    if method_arg && node.type == :send
      ref = @new_env.add_expr(node.children[idx])
      s(node.ttype, :envref, ref)
    else
      selected = node.children[idx]
      begin
        @new_env.bump_count(selected.children[0]) if selected.type == :envref
      rescue Exception => e 
        binding.pry
      end
      #TODO MOVE REGEX HANDLING TO A MORE APPROPRIATE LOCATION
      # if selected.ttype <= RDL::Globals.types[:regexp]

      #   regex = selected.children[0].to_s
      #   string = TypedNode.new(RDL::Type::NominalType.new(:str), :str, regex)
      #   opts = TypedNode.new(nil, :regopt, :i)
      #   TypedNode.new(RDL::Type::NominalType.new('Regexp'), :regexp, string, opts )
      # else
      #  selected
      # end
      selected
      
    end
  end

  def env
    @new_env
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
