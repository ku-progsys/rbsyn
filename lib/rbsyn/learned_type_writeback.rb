# AI generated: write learned types back into hole-free candidates.
#
# CheckErrorPass already resolves each moi call against the learned signatures every time the work list is
# re-scored, but only keeps the resulting scores; the candidate's node types stay as built (often %dyn from a
# placeholder signature). For a candidate with no holes left nothing remains to be discovered (it has run), so
# its calls can safely take the type of the learned signature that matches their receiver/argument types.
#
# Only writes a type when the receiver and every argument type are known (not %dyn), so a stale %dyn cannot
# match an arbitrary signature; a begin that wraps a single call (as fn_call wraps moi calls) takes the call's
# new type when it was %dyn.
class LearnedTypeWriteBack < ::AST::Processor # AI generated
  attr_reader :changed

  def initialize(type_info)
    @successes = type_info.type_successes
    @matcher = CheckErrorPass.new(type_info.type_errs, type_info.type_successes)
    @changed = false
  end

  def on_send(node)
    recv, mth, *args = node.children
    new_recv = recv.is_a?(TypedNode) ? process(recv) : recv
    new_args = args.map { |a| a.is_a?(TypedNode) ? process(a) : a }
    rebuilt = node.updated(nil, [new_recv, mth, *new_args])

    learned = learned_result(mth, new_recv, new_args)
    return rebuilt if learned.nil? || learned == node.ttype
    @changed = true
    rebuilt.update_ttype(learned)
  end

  def handler_missing(node)
    rebuilt = node.updated(nil, node.children.map { |k| k.is_a?(TypedNode) ? process(k) : k })
    if node.type == :begin && rebuilt.children.size == 1 && rebuilt.children[0].is_a?(TypedNode) &&
       node.ttype.is_a?(RDL::Type::DynamicType) && !rebuilt.children[0].ttype.is_a?(RDL::Type::DynamicType)
      @changed = true
      return rebuilt.update_ttype(rebuilt.children[0].ttype)
    end
    rebuilt
  end

  private

  def learned_result(mth, recv, args)
    return nil unless @successes.key?(mth)
    return nil unless recv.is_a?(TypedNode) && args.all? { |a| a.is_a?(TypedNode) }
    types = [recv.ttype, *args.map(&:ttype)]
    return nil if types.any? { |t| t.nil? || t.is_a?(RDL::Type::DynamicType) }
    signature = { recvr: recv.ttype, args: args.map(&:ttype), method: mth }
    match = @successes[mth].find { |s|
      begin
        @matcher.match_success(s, signature)
      rescue StandardError
        false
      end
    }
    return nil if match.nil? || match[:result].is_a?(RDL::Type::DynamicType)
    match[:result]
  end
end
