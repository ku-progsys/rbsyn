# AI generated (2026-10-20): replacement for CheckErrorPass (lib/rbsyn/ast/check_error_pass.rb, kept unchanged as the
# reference; CHECKER=old switches every user back to it). Standalone copy with three amendments:
#
# 1. Failure records only match on known types, and give one of three outcomes instead of true/false:
#      :pass  the record does not match with known types
#      :fail  it matches with known types, but the record is not type-level (may depend on values)
#      :drop  it matches with known types and the record is type-level (args = :ALL, or trace[:type_level])
#    "Known" = the type contains no %dyn: a filled value, or a hole whose declared type is not %dyn. A position that is
#    :ANY in the record, or a whole :ALL record, accepts anything, %dyn included. Every other position, and the
#    receiver, must be known and entirely within the recorded type (a union only if every member is).
#    #errors counts :fail and :drop matches (one per call, as before); #drop? is true after any :drop.
# 2. Nil carve-out: RDL ranks nil below every type (nil <= Hash, nil <= Integer are true), so a nil receiver matched
#    any recorded success and a nil argument any recorded failure. Here nil only matches nil, on both sides.
# 3. An :ALL record's receiver is compared by subtype instead of ==: a literal is typed by its own value (a singleton
#    for one symbol), and a method missing on every Symbol is missing on that one too.
#
# Unchanged from CheckErrorPass: the bottom-up walk, a moi call takes the result type of the first recorded success
# it matches (so a receiver that is the result of another call gets a type), successes are checked before failures
# (conflicting records keep the candidate), non-moi calls are typed from their RDL signatures, %dyn counting.
class CheckErrorPassV2 < ::AST::Processor # AI generated
  include TypeOperations
  require "set"
  attr_reader :errors, :dynamic_components, :drop_reason

  def initialize(errs, successes)
    update_reset(errs, successes)
  end

  def update_reset(type_errs, type_successes)
    @type_errs = type_errs
    @type_successes = type_successes
    @errors = 0
    @dynamic_components = 0
    @drop_reason = nil
  end

  def drop?
    !@drop_reason.nil?
  end

  def on_send(node)
    mth = node.children[1]
    trecv = process(node.children[0])
    @dynamic_components += 1 if trecv.is_a?(RDL::Type::DynamicType)
    return "error" if trecv.to_s == "error"

    targs = node.children[2 ..].map { |k| k.is_a?(TypedNode) ? process(k) : nil }
    return "error" if targs.map { |i| i.to_s }.include?("error")
    signature = { :recvr => trecv, :args => targs, :method => mth }

    if @type_successes.keys.include?(mth) # a method of interest
      @type_successes[mth].each { |i|
        if match_success(i, signature)
          @dynamic_components += 1 if i[:result].is_a?(RDL::Type::DynamicType)
          return i[:result]
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
        return "error"
      end
      return RDL::Type::DynamicType.new
    else # not a method of interest
      mthds = methods_of(trecv)
      info = mthds[mth]
      return "error" if info.nil?
      begin
        tret = compute_tout(trecv, info[:type], targs)
        @dynamic_components += 1 if tret.is_a?(RDL::Type::DynamicType)
        return tret
      rescue Exception => e
        raise e if e.is_a?(Timeout::Error) || (defined?(Timeout::ExitException) && e.is_a?(Timeout::ExitException))
        return "error"
      end
    end
  end

  def handler_missing(node)
    # a begin wrapping a single call keeps the static type it was built with (%dyn for calls built from a %dyn
    # placeholder signature): pass the call's resolved type up instead (as CheckErrorPass)
    if node.is_a?(TypedNode) && node.type == :begin && node.children.size == 1 && node.children[0].is_a?(TypedNode)
      resolved = process(node.children[0])
      if resolved.is_a?(RDL::Type::Type)
        @dynamic_components += 1 if resolved.is_a?(RDL::Type::DynamicType)
        return resolved
      end
      @dynamic_components += 1 if node.ttype.is_a?(RDL::Type::DynamicType)
      return node.ttype
    end

    @dynamic_components += 1 if node.is_a?(TypedNode) && node.ttype.is_a?(RDL::Type::DynamicType)
    node.updated(nil, node.children.map { |k| k.is_a?(TypedNode) ? process(k) : k })
    node.ttype
  end

  # a recorded success against the call: argument count, receiver (call <= record), then each argument with
  # any-member-of-a-union semantics (record <= call), all with the nil carve-out
  def match_success(template, signature)
    return false if template[:args].size != signature[:args].size
    return false unless nil_safe_leq(signature[:recvr], template[:recvr])
    template[:args].zip(signature[:args]).all? { |t, s| members(t).any? { |l| members(s).any? { |u| nil_safe_leq(l, u) } } }
  end

  # one failure record against the call: :pass, :fail or :drop (see the top of the file)
  def err_outcome(template, signature)
    if template[:args] == :ALL
      return :pass unless known?(signature[:recvr]) && sub?(signature[:recvr], template[:recvr])
      return :drop
    end
    return :pass if template[:args].size != signature[:args].size
    return :pass unless known?(signature[:recvr]) && sub?(signature[:recvr], template[:recvr])
    return :pass unless template[:args].zip(signature[:args]).all? { |t, s| position_match?(t, s) }
    template[:type_level] ? :drop : :fail
  end

  def position_match?(t, s)
    return true if t.equal?(:ANY)
    if t.is_a?(AnyKeysHash)
      return false unless s.is_a?(RDL::Type::FiniteHashType) && s.elts.key?(t.key)
      return true if t.type.equal?(:ANY)
      v = s.elts[t.key]
      return known?(v) && sub?(unopt(v), unopt(t.type))
    end
    known?(s) && sub?(s, t)
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
end
