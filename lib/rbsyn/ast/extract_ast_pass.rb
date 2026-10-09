class ExtractASTPass < ::AST::Processor
  # def initialize(selection, old_env)
  #   @selection = selection
  #   @new_env = Marshal.load(Marshal.dump(old_env))
  # end
  # AI altered: the deep copy above copied the whole environment for every combination, including every alternative
  # that hole expansion had written into it (12 MB for hash-key variants, ~0.5 s per combination). The pass only
  # modifies the environment's entry hashes (replacing an entry's :expr, bumping :count, adding entries); tree nodes
  # are never modified in place (changes always build new nodes). So copying the table and each entry hash, and
  # sharing the nodes, is enough. EXTRACT_DEEP_COPY=1 (or deep_copy: true) restores the original deep copy.
  def initialize(selection, old_env, deep_copy: ENV.key?("EXTRACT_DEEP_COPY")) # AI generated
    @selection = selection
    @new_env = deep_copy ? Marshal.load(Marshal.dump(old_env)) : ExtractASTPass.shallow_env_copy(old_env)
  end

  def self.shallow_env_copy(env) # AI generated
    copy = LocalEnvironment.new
    copy.info = env.info.transform_values(&:dup)
    copy
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
