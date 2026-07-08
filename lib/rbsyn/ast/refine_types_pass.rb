class RefineTypesPass < ::AST::Processor
  include TypeOperations

  def initialize
    @tenv = {}
  end

  def on_def(node)
    @tenv = {}
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
    if @tenv.key?(var_name)
      node.update_ttype(@tenv[var_name])
    else
      node
    end
  end

  def on_send(node)
    # post-order traversal — process all children first
    new_children = node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }

    trecv = new_children[0]&.ttype
    # if receiver is a hole, we can't do anything
    return node if trecv.nil? || (trecv.is_a?(RDL::Type::TopType) && new_children[0].type == :hole)

    mth = new_children[1]
    
    # Special case for ActiveRecord constructors, which are not in RDL
    if trecv.is_a?(RDL::Type::SingletonType) && trecv.val.ancestors.include?(ActiveRecord::Base) && [:new, :create].include?(mth)
      return node.update_ttype(RDL::Type::NominalType.new(trecv.val))
    end

    begin
      mthds = methods_of(trecv)
    rescue => e
      $stderr.puts "  [refine] methods_of failed for #{trecv}: #{e.message}" if ENV['DEBUG']
      return node
    end
    
    info = mthds[mth]
    if ENV['DEBUG']
      $stderr.puts "  [refine] send #{mth} on #{trecv}: found=#{!info.nil?}"
      $stderr.puts "  [refine]   ancestors: #{parents_of(trecv).inspect}" 
      info_str = info ? info[:type].inspect : "nil"
      $stderr.puts "  [refine]   type: #{info_str}"
    end
    return node if info.nil? # method not found

    tmeth = info[:type]
    
    # Infer types of arguments, including holes
    expected_targs = compute_targs(trecv, tmeth)
    if ENV['DEBUG']
      $stderr.puts "  [refine]   expected_targs: #{expected_targs.inspect}"
      $stderr.puts "  [refine]   args before: #{new_children[2..].map { |a| "#{a.type}:#{a.ttype}" }.inspect}"
    end
    
    # Refine holes in arguments — replace with updated-ttype nodes
    args = new_children[2..].each_with_index.map do |arg_node, i|
      if arg_node.type == :hole
        inferred_type = expected_targs[i]
        if inferred_type
          updated = arg_node.update_ttype(inferred_type)
          $stderr.puts "  [refine]   refined hole #{i}: #{arg_node.ttype} -> #{inferred_type} (new #{updated.ttype})" if ENV['DEBUG']
          updated
        else
          arg_node
        end
      else
        arg_node
      end
    end
    $stderr.puts "  [refine]   args after: #{args.map { |a| "#{a.type}:#{a.ttype}" }.inspect}" if ENV['DEBUG']

    # Build updated node with refined children
    updated = node.updated(nil, [new_children[0], new_children[1], *args])

    # Compute return type
    targs = args.map(&:ttype)
    begin
      tret = compute_tout(trecv, tmeth, targs)
      updated = updated.update_ttype(tret)
    rescue
      # Could not compute return type, leave as is
    end

    updated
  end

  def on_and(node)
    new_children = node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }
    args = new_children.each_with_index.map do |child, i|
      if child.type == :hole
        child.update_ttype(RDL::Globals.types[:bool])
      else
        child
      end
    end
    updated = node.updated(nil, args)
    updated.update_ttype(RDL::Globals.types[:bool])
  end
  alias on_or on_and

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
