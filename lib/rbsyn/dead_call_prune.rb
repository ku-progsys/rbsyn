# AI generated (2026-10-20): drops candidates that cannot succeed however their holes are filled.
#
# A candidate is dead when it contains a call whose receiver type is known before running and for which inference
# recorded a method-missing failure on that receiver type for any arguments (InferTypes stores args = :ALL).
# Each rule can be switched off on its own:
#   PRUNE_DEAD_LITERAL=off  receiver is a literal (symbol, nil, string, number): recorded as its runtime class
#   PRUNE_DEAD_VAR=off      receiver is a variable with a known, non-%dyn type (an argument or a class constant):
#                           recorded with that declared type
#   PRUNE_TYPE_ERR=off      (2026-10-20) the call matches a type-level failure (trace[:type_level], printed
#                           :type_except): receiver known as above, and every argument position is either ANY in the
#                           record or holds a literal / known-type variable / literal hash whose type matches. An
#                           argument that is still a hole or %dyn is unknown and never matches.
#   PRUNE_CHECK=off         (2026-10-20) CheckErrorPassV2 (lib/rbsyn/ast/check_error_pass_v2.rb) reports a drop: a
#                           type-level or :ALL failure matched with known types, receivers and arguments resolved
#                           through learned successes (so call results count as known receivers)
#   PRUNE=off               all rules off
# Receivers match by exact type equality, the same way the failure was recorded, so a mismatch only means no pruning.
class DeadCallPrune # AI generated
  LITERAL_CLASSES = { sym: Symbol, nil: NilClass, str: String, int: Integer, float: Float }.freeze

  attr_reader :dropped

  def initialize(type_info)
    @type_info = type_info
    @dead = Set.new # [method, receiver type] pairs with an :ALL failure
    @typed = Hash.new { |h, k| h[k] = [] } # method => type-level failure records (not :ALL)
    @seen_errs = 0
    @dropped = Hash.new(0) # rule name => candidates dropped
  end

  def self.on?(rule)
    ENV["PRUNE"] != "off" && ENV[rule] != "off"
  end

  def active?
    %w[PRUNE_DEAD_LITERAL PRUNE_DEAD_VAR PRUNE_TYPE_ERR PRUNE_CHECK].any? { |r| self.class.on?(r) }
  end

  # re-reads the recorded failures; true when a new dead pair or type-level record appeared
  def refresh
    total = @type_info.type_errs.sum { |_, errs| errs.size }
    return false if total == @seen_errs
    @seen_errs = total
    before = [@dead.size, @typed.sum { |_, v| v.size }]
    @typed.clear
    @type_info.type_errs.each { |meth, errs|
      errs.each { |e|
        if e[:args] == :ALL then @dead << [meth, e[:recvr]]
        elsif e[:type_level] then @typed[meth] << e
        end
      }
    }
    [@dead.size, @typed.sum { |_, v| v.size }] != before
  end

  # the rule that kills the candidate, or nil
  def dead_rule(prog_wrap)
    return nil if @dead.empty? && @typed.empty?
    found = nil
    walk(prog_wrap.to_ast) { |node|
      next if found || node.type != :send
      recv = node.children[0]
      next unless recv.is_a?(Parser::AST::Node)
      rule, rt = receiver_type(recv)
      next if rule.nil?
      if self.class.on?(rule) && @dead.include?([node.children[1], rt])
        found = rule
      elsif self.class.on?("PRUNE_TYPE_ERR") && type_dead?(node.children[1], rt, node.children[2..])
        found = "PRUNE_TYPE_ERR"
      end
    }
    found = "PRUNE_CHECK" if found.nil? && self.class.on?("PRUNE_CHECK") && check_drop?(prog_wrap)
    found
  end

  # keeps the live candidates, counting the dropped ones per rule
  def filter(progs)
    return progs if (@dead.empty? && @typed.empty?) || !active?
    progs.reject { |pw|
      rule = dead_rule(pw)
      @dropped[rule] += 1 if rule
      rule
    }
  end

  private

  def check_drop?(prog_wrap)
    @checker ||= CheckErrorPassV2.new(@type_info.type_errs, @type_info.type_successes)
    @checker.update_reset(@type_info.type_errs, @type_info.type_successes)
    @checker.process(prog_wrap.to_ast)
    @checker.drop?
  end

  def receiver_type(recv)
    if LITERAL_CLASSES.key?(recv.type)
      ["PRUNE_DEAD_LITERAL", RDL::Type::NominalType.new(LITERAL_CLASSES[recv.type])]
    elsif recv.type == :lvar && recv.respond_to?(:ttype) && !recv.ttype.nil? && !recv.ttype.is_a?(RDL::Type::DynamicType)
      ["PRUNE_DEAD_VAR", recv.ttype]
    end
  end

  # a type-level record for this method and receiver whose every position matches the call's argument nodes
  def type_dead?(meth, rt, arg_nodes)
    recs = @typed[meth]
    return false if recs.empty?
    arg_types = arg_nodes.map { |a| static_type(a) }
    recs.any? { |rec|
      rec[:recvr] == rt && rec[:args].size == arg_types.size &&
        rec[:args].zip(arg_types).all? { |t, s| position_dead?(t, s) }
    }
  end

  def position_dead?(t, s)
    return true if t.equal?(:ANY)
    return false if s.nil?
    if t.is_a?(AnyKeysHash)
      elts = s.is_a?(Hash) ? s : (s.is_a?(RDL::Type::FiniteHashType) ? s.elts : nil)
      return false unless elts && elts.key?(t.key)
      return true if t.type.equal?(:ANY)
      return false if elts[t.key].nil?
      return sub?(unopt(elts[t.key]), unopt(t.type))
    end
    return false if s.is_a?(Hash) # a literal hash against a whole recorded hash type: not compared
    sub?(s, t)
  end

  # the type of an argument node known before running, nil if unknown (a hole, %dyn, or anything else). A literal
  # hash gives a Ruby Hash of key => type (nil for unknown values).
  def static_type(node)
    return nil unless node.is_a?(Parser::AST::Node)
    node = node.children[0] while node.type == :begin && node.children.size == 1 && node.children[0].is_a?(Parser::AST::Node)
    if LITERAL_CLASSES.key?(node.type)
      RDL::Type::NominalType.new(LITERAL_CLASSES[node.type])
    elsif node.type == :true || node.type == :false
      RDL::Type::UnionType.new(RDL::Type::SingletonType.new(false), RDL::Type::SingletonType.new(true))
    elsif node.type == :lvar && node.respond_to?(:ttype) && !node.ttype.nil? && !node.ttype.is_a?(RDL::Type::DynamicType)
      node.ttype
    elsif node.type == :hash
      node.children.each_with_object({}) { |pair, h|
        next unless pair.is_a?(Parser::AST::Node) && pair.type == :pair && pair.children[0].type == :sym
        h[pair.children[0].children[0]] = static_type(pair.children[1])
      }
    end
  end

  def unopt(t)
    t.is_a?(RDL::Type::OptionalType) ? t.type : t
  end

  # a recorded type containing %dyn would accept every argument (everything is a subtype of %dyn): never prune on it
  def has_dyn?(t)
    case t
    when RDL::Type::DynamicType then true
    when RDL::Type::OptionalType then has_dyn?(t.type)
    when RDL::Type::UnionType then t.types.any? { |x| has_dyn?(x) }
    when RDL::Type::FiniteHashType then t.elts.values.any? { |x| has_dyn?(x) } || (!t.rest.nil? && has_dyn?(t.rest))
    when RDL::Type::GenericType then has_dyn?(t.base) || t.params.any? { |x| has_dyn?(x) }
    else false
    end
  end

  def sub?(s, t)
    return false if has_dyn?(t)
    TypeOperations.leq_nc(s, t)
  rescue StandardError
    false
  end

  def walk(node, &blk)
    return unless node.is_a?(Parser::AST::Node)
    blk.call(node)
    node.children.each { |c| walk(c, &blk) }
  end
end
