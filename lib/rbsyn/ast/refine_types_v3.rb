# AI generated (2026-11-15): CheckErrorPassV2 that also writes the types it works out into the nodes.
#
# Same walk, matching and counting as CheckErrorPassV2 (inherited: match_success, err_outcome, errors,
# dynamic_components, drop?). The difference is what each handler returns: [status, type, node] instead of a type.
#   status  :ok or :error (CheckErrorPassV2 returned the string "error"); an error makes the enclosing call an error
#   type    the type CheckErrorPassV2 would have returned, used for checking the enclosing call
#   node    the node rebuilt with its new children and, where a type was worked out, that type
# Nodes are frozen, so a changed node is a new copy and every parent is rebuilt around its new children.
#
# A type is written into a node only when it is known (not %dyn) and, for a method of interest, only when the receiver
# and every argument are known: a %dyn receiver matches any success, so its type is used for checking but not written.
# Use: status, _type, new_root = RefineTypesV3.new(errs, successes).process(root)
class RefineTypesV3 < CheckErrorPassV2 # AI generated
  attr_reader :changed

  def update_reset(type_errs, type_successes)
    super
    @changed = false
  end

  def process(node)
    node = node.to_ast if !node.is_a?(Parser::AST::Node) && node.respond_to?(:to_ast) # as AST::Processor does
    return [:ok, nil, node] unless node.is_a?(Parser::AST::Node)
    super
  end

  def on_send(node)
    mth = node.children[1]
    _, trecv, recv_node = visit(node.children[0])
    @dynamic_components += 1 if trecv.is_a?(RDL::Type::DynamicType)
    return [:error, "error", rebuild(node, [recv_node, *node.children[1..]])] if trecv.to_s == "error"

    visited = node.children[2..].map { |k| k.is_a?(TypedNode) ? visit(k) : [:ok, nil, k] }
    targs = visited.map { |_, t, _| t }
    rebuilt = rebuild(node, [recv_node, mth, *visited.map { |_, _, n| n }])
    return [:error, "error", rebuilt] if targs.map { |i| i.to_s }.include?("error")
    signature = { :recvr => trecv, :args => targs, :method => mth }

    if @type_successes.keys.include?(mth) # a method of interest
      @type_successes[mth].each { |i|
        if match_success(i, signature)
          @dynamic_components += 1 if i[:result].is_a?(RDL::Type::DynamicType)
          written = all_known?([trecv, *targs]) ? write(rebuilt, i[:result]) : rebuilt
          return [:ok, i[:result], written]
        end
      }

      outcome = :pass
      @type_errs[mth].each { |i|
        o = err_outcome(i, signature)
        if o == :drop
          outcome = :drop
          break
        end
        outcome = :fail if o == :fail
      }
      unless outcome == :pass
        @errors += 1
        @drop_reason ||= "#{trecv} :#{mth}" if outcome == :drop
        return [:error, "error", rebuilt]
      end
      return [:ok, RDL::Type::DynamicType.new, rebuilt]
    else # not a method of interest
      mthds = methods_of(trecv)
      info = mthds[mth]
      return [:error, "error", rebuilt] if info.nil?
      begin
        tret = compute_tout(trecv, info[:type], targs)
        @dynamic_components += 1 if tret.is_a?(RDL::Type::DynamicType)
        return [:ok, tret, write(rebuilt, tret)]
      rescue Exception => e
        raise e if e.is_a?(Timeout::Error) || (defined?(Timeout::ExitException) && e.is_a?(Timeout::ExitException))
        return [:error, "error", rebuilt]
      end
    end
  end

  def handler_missing(node)
    # a begin wrapping a single call passes the call's resolved type up (as CheckErrorPassV2) and takes it as its own
    if node.is_a?(TypedNode) && node.type == :begin && node.children.size == 1 && node.children[0].is_a?(TypedNode)
      status, resolved, child = visit(node.children[0])
      rebuilt = rebuild(node, [child])
      if resolved.is_a?(RDL::Type::Type)
        @dynamic_components += 1 if resolved.is_a?(RDL::Type::DynamicType)
        # the begin takes the call's type only if the call took it (it was written, or already had it)
        return [status, resolved, child.is_a?(TypedNode) && child.ttype == resolved ? write(rebuilt, resolved) : rebuilt]
      end
      @dynamic_components += 1 if node.ttype.is_a?(RDL::Type::DynamicType)
      return [status, node.ttype, rebuilt]
    end

    @dynamic_components += 1 if node.is_a?(TypedNode) && node.ttype.is_a?(RDL::Type::DynamicType)
    children = node.children.map { |k| k.is_a?(TypedNode) ? visit(k)[2] : k }
    [:ok, node.is_a?(TypedNode) ? node.ttype : nil, rebuild(node, children)]
  end

  private

  # a child as CheckErrorPassV2 processed it: any AST node is processed, anything else (nil, a symbol) has no type
  def visit(k)
    k.is_a?(Parser::AST::Node) ? process(k) : [:ok, nil, k]
  end

  def all_known?(types)
    types.all? { |t| t.is_a?(RDL::Type::Type) && known?(t) }
  end

  # the node with a new type, if the type is known and differs
  def write(node, type)
    return node unless node.is_a?(TypedNode) && type.is_a?(RDL::Type::Type) && known?(type)
    return node if node.ttype.equal?(type) || node.ttype == type
    @changed = true
    node.update_ttype(type)
  end

  # the node around new children (compared by identity: TypedNode#updated ignores type-only changes)
  def rebuild(node, new_children)
    changed = new_children.each_with_index.any? { |c, i| !c.equal?(node.children[i]) }
    return node unless changed
    node.is_a?(TypedNode) ? TypedNode.new(node.ttype, node.type, *new_children) : node.updated(nil, new_children)
  end
end
