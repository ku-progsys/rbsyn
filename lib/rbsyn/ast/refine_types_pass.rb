class RefineTypesPass < ::AST::Processor
  include TypeOperations

  def initialize
    @tenv = {}
  end

  def on_def(node)
    @tenv = {}
    # Method return type is refined when processing the body
    node.updated(nil, node.children.map { |c| c.is_a?(TypedNode) ? process(c) : c })
  end

  def on_args(node)
    node.children.each do |arg|
      # In sketches, args might not have types yet.
      # We assume they will be refined by callsites, so we start with TopType.
      @tenv[arg.children[0]] = arg.ttype if arg.ttype
    end
    node
  end

  def on_lvar(node)
    var_name = node.children[0]
    if @tenv.key?(var_name) && node.ttype.is_a?(RDL::Type::TopType)
      node.update_ttype(@tenv[var_name])
    end
  end

  def on_send(node)
    # post-order traversal
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

    trecv = node.children[0]&.ttype
    # if receiver is a hole, we can't do anything
    return if trecv.nil? || (trecv.is_a?(RDL::Type::TopType) && node.children[0].type == :hole)

    mth = node.children[1]
    
    # Special case for ActiveRecord constructors, which are not in RDL
    if trecv.is_a?(RDL::Type::SingletonType) && trecv.val.ancestors.include?(ActiveRecord::Base) && [:new, :create].include?(mth)
      node.update_ttype(RDL::Type::NominalType.new(trecv.val))
      return
    end

    begin
      mthds = methods_of(trecv)
    rescue
      # if we can't get methods, we can't do anything
      return
    end
    
    info = mthds[mth]
    return if info.nil? # method not found

    tmeth = info[:type]
    
    # Infer types of arguments, including holes
    expected_targs = compute_targs(trecv, tmeth)
    
    node.children[2..].each_with_index do |arg_node, i|
      if arg_node.type == :hole && arg_node.ttype.is_a?(RDL::Type::TopType)
        inferred_type = expected_targs[i]
        # puts "Inferred type for hole: #{inferred_type.to_s}" if inferred_type
        arg_node.update_ttype(inferred_type) if inferred_type
      end
    end

    # Now, re-calculate argument types after potential refinement
    targs = node.children[2..].map(&:ttype)

    # Then, compute the return type of the call
    begin
      tret = compute_tout(trecv, tmeth, targs)
      node.update_ttype(tret)
    rescue
      # Could not compute return type, leave as is
    end
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
