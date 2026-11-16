# AI generated (2026-11-15): one pass that checks a program against the recorded successes and failures and writes
# the types it works out into the nodes.
#
# Every handler returns [status, type, node]:
#   status  :pass, :fail or :prune
#             :fail   a call fails the check but the program is kept (a recorded failure, not an exact type-level or
#                     ALL match, counts in errors); with AGGRESSIVE_PRUNING=on every :fail is a :prune instead
#             :prune  a call matches an exact type-level or ALL failure, or its receiver type has no such method
#   type    the type worked out; for a failed call its stored type; nil for :prune
#   node    the node rebuilt with its new children and, where a type was worked out, that type
# A :prune stops the walk at once (the program is dropped). A :fail does not: the failed call keeps its stored type,
# its parent is checked with that type, and the walk carries on, so every failing call is counted. A node is :fail
# if it or anything below it failed. Nodes are frozen, so a changed node is a new copy and every parent is rebuilt
# around its new children.
#
# A type is written into a node only when it is known (not %dyn) and, for a method of interest, only when the receiver
# and every argument are known.
# Use: status, _type, new_root = RefineTypesV3.new(errs, successes).process(root)
#      status, new_seed, new_exprs, new_env_info = RefineTypesV3.new(errs, successes).retype(seed, exprs, env)
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
    @var_types = {} # variable name -> known type its assignment resolved to
    @env = nil # the program's LocalEnvironment, set by retype
    @env_done = {} # env ref -> [status, type, retyped expr], each entry is walked once per program
  end

  def drop?
    !@drop_reason.nil?
  end

  # retypes a stored program (effect expressions, then the seed, and the env entries they reference) rather than its
  # to_ast copy; stops at the first expression that does not pass
  def retype(seed, exprs, env)
    @env = env
    status = :pass
    new_exprs = exprs.map { |e|
      next e if status == :prune
      st, _, node = visit(e)
      status = worse(status, st)
      node
    }
    new_seed = seed
    if status != :prune
      st, _, new_seed = visit(seed)
      status = worse(status, st)
    end
    new_info = env.info.to_h { |ref, entry| [ref, @env_done.key?(ref) ? entry.merge(expr: @env_done[ref][2]) : entry] }
    [status, new_seed, new_exprs, new_info]
  ensure
    @env = nil
  end

  def process(node)
    node = node.to_ast if !node.is_a?(Parser::AST::Node) && node.respond_to?(:to_ast) # as AST::Processor does
    return [:pass, nil, node] unless node.is_a?(Parser::AST::Node)
    super
  end

  # a reference to an env entry stands for its expression (as to_ast inlines it): it passes up the expression's status
  # and type, and the expression is walked once
  def on_envref(node)
    return handler_missing(node) if @env.nil?
    ref = node.children[0]
    @env_done[ref] ||= visit(@env.get_expr(ref)[:expr])
    status, type, _ = @env_done[ref]
    [status, type, status == :pass ? write(node, type) : node]
  end

  # an assignment remembers the type its expression resolved to, so later uses of the variable get it
  def on_lvasgn(node)
    status, type, child = visit(node.children[1])
    rebuilt = rebuild(node, [node.children[0], child])
    return [status, nil, rebuilt] if status == :prune
    @var_types[node.children[0]] = type if status == :pass && all_known?([type])
    @dynamic_components += 1 if node.ttype.is_a?(RDL::Type::DynamicType)
    [status, node.ttype, rebuilt]
  end

  # a use of a variable takes the type of its assignment when that is known; otherwise the stored type
  def on_lvar(node)
    type = @var_types[node.children[0]]
    return handler_missing(node) if type.nil?
    [:pass, type, write(node, type)]
  end

  # a hash literal's type is rebuilt from its values' resolved types; a value that stays unknown keeps its stored type
  def on_hash(node)
    return handler_missing(node) unless node.ttype.is_a?(RDL::Type::FiniteHashType) &&
                                        node.children.all? { |c| c.is_a?(TypedNode) && c.type == :pair }
    elts = node.ttype.elts.dup
    pairs = node.children.dup
    status = :pass
    node.children.each_with_index { |pair, i|
      key_node, value = pair.children
      st, vtype, vnode = visit(value)
      pairs[i] = rebuild(pair, [key_node, vnode])
      return [:prune, nil, rebuild(node, pairs)] if st == :prune
      status = worse(status, st)
      key = key_node.children[0]
      elts[key] = RDL::Type::OptionalType.new(vtype) if st == :pass && all_known?([vtype]) && elts.key?(key)
    }
    rebuilt = rebuild(node, pairs)
    type = RDL::Type::FiniteHashType.new(elts, node.ttype.rest)
    [status, type, write(rebuilt, type)]
  end

  def on_send(node)
    mth = node.children[1]
    children = node.children.dup
    below, trecv, children[0] = visit(node.children[0]) # below: :pass or :fail for everything under this call
    return [:prune, nil, rebuild(node, children)] if below == :prune
    @dynamic_components += 1 if trecv.is_a?(RDL::Type::DynamicType)

    targs = []
    node.children[2..].each_with_index { |k, i|
      st, t, children[i + 2] = k.is_a?(TypedNode) ? visit(k) : [:pass, nil, k]
      return [:prune, nil, rebuild(node, children)] if st == :prune
      below = worse(below, st)
      targs << t
    }
    rebuilt = rebuild(node, children)
    status, type, out = check_call(node, rebuilt, mth, trecv, targs)
    [status == :prune ? :prune : worse(below, status), type, out]
  end

  # the call itself, once its receiver and arguments are typed: [status, type, node]
  def check_call(node, rebuilt, mth, trecv, targs)
    signature = { :recvr => trecv, :args => targs, :method => mth }

    if @type_successes.keys.include?(mth) # a method of interest
      # nil results last, so a call fitting both a nil and a non-nil success takes the non-nil one
      @type_successes[mth].each_with_index.sort_by { |i, idx| [nil_type?(i[:result]) ? 1 : 0, idx] }.map(&:first).each { |i|
        if match_success(i, signature)
          @dynamic_components += 1 if i[:result].is_a?(RDL::Type::DynamicType)
          written = all_known?([trecv, *targs]) ? write(rebuilt, i[:result]) : rebuilt
          return [:pass, i[:result], written]
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
      if outcome == :drop
        @errors += 1
        @drop_reason ||= "#{trecv} :#{mth}"
        return [:prune, nil, rebuilt]
      end
      if outcome == :fail
        @errors += 1
        return failed(rebuilt, "#{trecv} :#{mth}")
      end
      return [:pass, RDL::Type::DynamicType.new, rebuilt]
    else # not a method of interest
      info = methods_of(trecv)[mth]
      if info.nil? || info[:type].nil?
        # the receiver type has no such method: ill-typed, as RefineTypesV2 rejected it (a nil receiver is kept, as there)
        return failed(rebuilt, "nil receiver ##{mth}") if trecv.to_s == "nil"
        @drop_reason ||= "no method #{trecv}##{mth}"
        return [:prune, nil, rebuilt]
      end
      begin
        tret = compute_tout(trecv, info[:type], targs)
        @dynamic_components += 1 if tret.is_a?(RDL::Type::DynamicType)
        return [:pass, tret, write(rebuilt, tret)]
      rescue Exception => e
        raise e if e.is_a?(Timeout::Error) || (defined?(Timeout::ExitException) && e.is_a?(Timeout::ExitException))
        return failed(rebuilt, "#{trecv}##{mth} arguments")
      end
    end
  end

  def handler_missing(node)
    return [:pass, nil, node] unless node.is_a?(TypedNode)
    children = node.children.dup
    last_type = nil
    status = :pass
    node.children.each_with_index { |k, i|
      next unless k.is_a?(TypedNode)
      st, last_type, children[i] = visit(k)
      return [:prune, nil, rebuild(node, children)] if st == :prune
      status = worse(status, st)
    }
    rebuilt = rebuild(node, children)
    # a block of statements has the type of its last statement
    if node.type == :begin && node.children.last.is_a?(TypedNode) && last_type.is_a?(RDL::Type::Type)
      @dynamic_components += 1 if last_type.is_a?(RDL::Type::DynamicType) && node.children.size == 1
      return [status, last_type, all_known?([last_type]) ? write(rebuilt, last_type) : rebuilt] if node.children.size == 1 || all_known?([last_type])
    end
    @dynamic_components += 1 if node.ttype.is_a?(RDL::Type::DynamicType)
    [status, node.ttype, rebuilt]
  end

  # a recorded success against the call: argument count, receiver (call <= record), each argument (call <= record),
  # all with the nil carve-out
  # Arguments follow normal (Liskov) substitution like the receiver: the call's argument must be the recorded one or
  # more specific, and every member of a union argument must be covered.
  def match_success(template, signature)
    return false if template[:args].size != signature[:args].size
    # AI generated (2026-11-15): successes carry no wildcards, so a %dyn receiver or argument cannot be said to match one
    return false unless known?(signature[:recvr]) && signature[:args].all? { |a| known?(a) } # AI generated
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

  # :fail ranks below :pass (only :pass and :fail reach here; :prune returns at once)
  def worse(a, b)
    a == :fail || b == :fail ? :fail : :pass
  end

  # a call that fails the check: kept with its stored type, or dropped with AGGRESSIVE_PRUNING=on
  def failed(node, reason)
    if ENV["AGGRESSIVE_PRUNING"] == "on"
      @drop_reason ||= "aggressive: #{reason}"
      return [:prune, nil, node]
    end
    [:fail, node.ttype, node]
  end

  # a child as CheckErrorPassV2 processed it: any AST node is processed, anything else (nil, a symbol) has no type
  def visit(k)
    k.is_a?(Parser::AST::Node) ? process(k) : [:pass, nil, k]
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
