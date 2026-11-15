# AI generated (2026-10-20): drops candidates that cannot succeed however their holes are filled.
#
# A candidate is dead when it contains a call whose receiver type is known before running and for which inference
# recorded a method-missing failure on that receiver type for any arguments (InferTypes stores args = :ALL).
# Each rule can be switched off on its own:
#   PRUNE_DEAD_LITERAL=off  receiver is a literal (symbol, nil, string, number): recorded as its runtime class
#   PRUNE_DEAD_VAR=off      receiver is a variable with a known, non-%dyn type (an argument or a class constant):
#                           recorded with that declared type
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
    @type_level = 0 # number of type-level failure records (not :ALL); PRUNE_CHECK only runs once there is one
    @seen_errs = 0
    @dropped = Hash.new(0) # rule name => candidates dropped
  end

  def self.on?(rule)
    ENV["PRUNE"] != "off" && ENV[rule] != "off"
  end

  def active?
    %w[PRUNE_DEAD_LITERAL PRUNE_DEAD_VAR PRUNE_CHECK].any? { |r| self.class.on?(r) }
  end

  # re-reads the recorded failures; true when a new dead pair or type-level record appeared
  def refresh
    total = @type_info.type_errs.sum { |_, errs| errs.size }
    return false if total == @seen_errs
    @seen_errs = total
    before = [@dead.size, @type_level]
    @type_level = 0
    @type_info.type_errs.each { |meth, errs|
      errs.each { |e|
        if e[:args] == :ALL then @dead << [meth, e[:recvr]]
        elsif e[:type_level] then @type_level += 1
        end
      }
    }
    [@dead.size, @type_level] != before
  end

  # the rule that kills the candidate, or nil
  def dead_rule(prog_wrap)
    return nil if @dead.empty? && @type_level.zero?
    found = nil
    walk(prog_wrap.to_ast) { |node|
      next if found || node.type != :send
      recv = node.children[0]
      next unless recv.is_a?(Parser::AST::Node)
      rule, rt = receiver_type(recv)
      next if rule.nil?
      found = rule if self.class.on?(rule) && @dead.include?([node.children[1], rt])
    }
    found = "PRUNE_CHECK" if found.nil? && self.class.on?("PRUNE_CHECK") && check_drop?(prog_wrap)
    found
  end

  # keeps the live candidates, counting the dropped ones per rule
  def filter(progs)
    return progs if (@dead.empty? && @type_level.zero?) || !active?
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

  def walk(node, &blk)
    return unless node.is_a?(Parser::AST::Node)
    blk.call(node)
    node.children.each { |c| walk(c, &blk) }
  end
end
