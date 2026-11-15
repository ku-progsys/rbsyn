# AI generated (2026-11-15): a standalone pass that checks a program like CheckErrorPassV2 and also writes the types it
# works out into the nodes.
#
# Same walk, matching and counting as CheckErrorPassV2; the matching helpers below are copied from it, so the two can be
# changed separately. The difference is what each handler returns: [status, type, node] instead of a type.
#   status  :ok or :error (CheckErrorPassV2 returned the string "error"); an error makes the enclosing call an error
#   type    the type CheckErrorPassV2 would have returned, used for checking the enclosing call
#   node    the node rebuilt with its new children and, where a type was worked out, that type
# Nodes are frozen, so a changed node is a new copy and every parent is rebuilt around its new children.
#
# A type is written into a node only when it is known (not %dyn) and, for a method of interest, only when the receiver
# and every argument are known: a %dyn receiver matches any success, so its type is used for checking but not written.
# Use: status, _type, new_root = RefineTypesV3.new(errs, successes).process(root)
class RefineTypesV3 < ::AST::Processor # AI generated
  include TypeOperations
  require "set"
  attr_reader :errors, :dynamic_components, :drop_reason, :changed

  def initialize(errs, successes)
    update_reset(errs, successes)
  end

  def update_reset(type_errs, type_successes)
    @type_errs = type_errs
    @type_successes = type_successes
    @errors = 0
    @dynamic_components = 0
    @drop_reason = nil
    @changed = false
  end

  def drop?
    !@drop_reason.nil?
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
      # @type_successes[mth].each { |i| # AI altered (2026-11-15): nil results last, so a call fitting both a nil and a
      #                                 # non-nil success takes the non-nil one (nil records are kept, see InferTypes)
      @type_successes[mth].each_with_index.sort_by { |i, idx| [nil_type?(i[:result]) ? 1 : 0, idx] }.map(&:first).each { |i| # AI generated
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

  # a recorded success against the call: argument count, receiver (call <= record), each argument (call <= record),
  # all with the nil carve-out
  # Arguments follow normal (Liskov) substitution like the receiver: the call's argument must be the recorded one or
  # more specific, and every member of a union argument must be covered.
  def match_success(template, signature)
    return false if template[:args].size != signature[:args].size
    return false unless nil_safe_leq(signature[:recvr], template[:recvr])
    # template[:args].zip(signature[:args]).all? { |t, s| members(t).any? { |l| members(s).any? { |u| nil_safe_leq(l, u) } } }
    template[:args].zip(signature[:args]).all? { |t, s| members(s).all? { |u| members(t).any? { |l| nil_safe_leq(u, l) } } }
  end

  # one failure record against the call: :pass, :fail or :drop (see the top of the file)
  # A failure matches a call whose types are the recorded ones (:exact) or more general (:super, the value may still
  # be the failing type). A more specific type may add what was missing, so it does not match. Only an all-exact
  # match keeps :drop; any :super position makes it :fail.
  # def err_outcome(template, signature)
  #   if template[:args] == :ALL
  #     return :pass unless known?(signature[:recvr]) && sub?(signature[:recvr], template[:recvr])
  #     return :drop
  #   end
  #   return :pass if template[:args].size != signature[:args].size
  #   return :pass unless known?(signature[:recvr]) && sub?(signature[:recvr], template[:recvr])
  #   return :pass unless template[:args].zip(signature[:args]).all? { |t, s| position_match?(t, s) }
  #   template[:type_level] ? :drop : :fail
  # end
  def err_outcome(template, signature)
    recv = known?(signature[:recvr]) ? fail_match(signature[:recvr], template[:recvr]) : nil
    return :pass if recv.nil?
    return(recv == :exact ? :drop : :fail) if template[:args] == :ALL
    return :pass if template[:args].size != signature[:args].size
    matches = [recv] + template[:args].zip(signature[:args]).map { |t, s| position_match(t, s) }
    return :pass if matches.include?(nil)
    return :fail unless matches.all? { |m| m == :exact }
    template[:type_level] ? :drop : :fail
  end

  # def position_match?(t, s)
  #   return true if t.equal?(:ANY)
  #   if t.is_a?(AnyKeysHash)
  #     return false unless s.is_a?(RDL::Type::FiniteHashType) && s.elts.key?(t.key)
  #     return true if t.type.equal?(:ANY)
  #     v = s.elts[t.key]
  #     return known?(v) && sub?(unopt(v), unopt(t.type))
  #   end
  #   known?(s) && sub?(s, t)
  # end
  def position_match(t, s) # :exact, :super or nil (no match)
    return :exact if t.equal?(:ANY)
    if t.is_a?(AnyKeysHash)
      return nil unless s.is_a?(RDL::Type::FiniteHashType) && s.elts.key?(t.key)
      return :exact if t.type.equal?(:ANY)
      v = s.elts[t.key]
      return known?(v) ? fail_match(unopt(v), unopt(t.type)) : nil
    end
    known?(s) ? fail_match(s, t) : nil
  end

  # call type s against recorded failing type t: :exact if every member of s is a member of t, :super if some
  # member of t lies below some member of s, nil otherwise (s only more specific, or unrelated)
  def fail_match(s, t)
    eq = lambda { |x, y| nil_safe_leq(x, y) && nil_safe_leq(y, x) }
    return :exact if members(s).all? { |x| members(t).any? { |y| eq.(x, y) } }
    return :super if members(s).any? { |x| members(t).any? { |y| nil_safe_leq(y, x) } }
    nil
  end

  def known?(t)
    case t
    when nil, String then false
    when RDL::Type::DynamicType then false
    when RDL::Type::OptionalType then known?(t.type)
    when RDL::Type::UnionType then t.types.all? { |x| known?(x) }
    when RDL::Type::FiniteHashType then t.elts.values.all? { |x| known?(x) } && (t.rest.nil? || known?(t.rest))
    when RDL::Type::GenericType then known?(t.base) && t.params.all? { |x| known?(x) }
    else true
    end
  end

  # failure side: the call's type must be entirely within the recorded one
  def sub?(s, t)
    members(s).all? { |x| nil_safe_leq(x, t) || (t.is_a?(RDL::Type::UnionType) && t.types.any? { |y| nil_safe_leq(x, y) }) }
  end

  def members(t)
    t.is_a?(RDL::Type::UnionType) ? t.types : [t]
  end

  def unopt(t)
    t.is_a?(RDL::Type::OptionalType) ? t.type : t
  end

  def nil_type?(t)
    (t.is_a?(RDL::Type::SingletonType) && t.val.nil?) || (t.is_a?(RDL::Type::NominalType) && t.name == "NilClass")
  end

  # <= except that nil only matches nil (a union matches nil if one of its members is nil); %dyn keeps RDL's
  # behaviour (matches anything): it only reaches here on the success side, failures require known types
  def nil_safe_leq(a, b)
    return false if a.nil? || b.nil? || a.is_a?(String) || b.is_a?(String)
    a, b = unopt(a), unopt(b)
    return true if a.is_a?(RDL::Type::DynamicType) || b.is_a?(RDL::Type::DynamicType)
    if nil_type?(a)
      return nil_type?(b) || (b.is_a?(RDL::Type::UnionType) && b.types.any? { |x| nil_type?(x) })
    end
    return false if nil_type?(b)
    begin
      TypeOperations.leq_nc(a, b)
    rescue FrozenError
      TypeOperations.leq_nc(thaw(a), thaw(b))
    end
  rescue StandardError
    false
  end

  # copy of the top-level thaw in check_error_pass.rb: unfrozen copies of frozen types for comparison
  def thaw(type)
    case type
    when RDL::Type::NominalType then type.frozen? ? RDL::Type::NominalType.new(type.name) : type
    when RDL::Type::SingletonType then RDL::Type::SingletonType.new(type.val)
    when RDL::Type::UnionType then RDL::Type::UnionType.new(type.types.map { |t| thaw(t) })
    when RDL::Type::TupleType then RDL::Type::TupleType.new(type.types.map { |t| thaw(t) })
    when RDL::Type::GenericType then RDL::Type::GenericType.new(thaw(type.base), type.params.map { |p| thaw(p) })
    when RDL::Type::MethodType then RDL::Type::MethodType.new(type.args.map { |a| thaw(a) }, thaw(type.ret), type.block ? thaw(type.block) : nil)
    else type
    end
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
