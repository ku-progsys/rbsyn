# AI generated: merges RefineTypesPass (refine_types_pass.rb) and DynamicRefineTypes
# (refine_type_pass_v2.rb) into one pass. In build_candidates the two ran back to back on every
# candidate, each calling methods_of (which deep-copies RDL tables) on every call node.
#
#   RefineTypesV2.new                               behaves like RefineTypesPass
#   RefineTypesV2.new(ctx:, env:, dynamic: true)    behaves like RefineTypesPass followed by
#                                                   DynamicRefineTypes, in a single walk
#
# dynamic: true adds what DynamicRefineTypes did on top of RefineTypesPass:
#   - refine subexpressions stored in the LocalEnvironment (on_envref) and write %dyn results back
#   - prune: a call whose (non-nil) receiver has no signature for the method raises NoMethodError,
#     which build_candidates rescues to drop the candidate
#   - nil receivers are refined if possible but never pruned
#
# Kept as in both originals: on_send discards the processed children (node.updated(...) result is
# not used), so a refined inner call type does not reach its parent. Fixing that changes behaviour
# and is a separate step.
class RefineTypesV2 < ::AST::Processor # AI generated
  include TypeOperations

  def initialize(ctx: nil, env: nil, dynamic: false)
    @ctx = ctx
    @env = env
    @dynamic = dynamic
    raise RbSynError, "dynamic refinement needs a LocalEnvironment" if @dynamic && @env.nil?
  end

  # AI altered (2026-10-12): the original on_envref/on_send/handler_missing below (now *_old, kept for REFINE_KEEP_OLD=1)
  # lost refined types below the top of a candidate: TypedNode#updated returns the old node when children are == (node
  # equality ignores types), on_send discarded its processed children and looked up the method with the receiver's
  # unrefined type, and on_envref only stored a type change, not the refined subexpression.
  def on_envref(node) # AI generated
    return on_envref_old(node) if ENV.key?("REFINE_KEEP_OLD")
    return node unless @dynamic

    ref = node.children[0]
    info = @env.get_expr(ref)
    processed = process(info[:expr])
    # store the refined subexpression (refined children included)
    @env.update_expr(ref, processed) unless processed.equal?(info[:expr])
    # the reference node's own type is handled exactly as before: it only takes the refined type when that is %dyn
    # (the root of every candidate is a reference, and the variance filter checks the root's type)
    if processed.ttype.is_a? RDL::Type::DynamicType
      ttype = processed.ttype.is_a?(RDL::Type::MethodType) ? processed.ttype.ret : processed.ttype
      node.update_ttype(ttype)
    else
      node
    end
  end

  def on_send(node) # AI generated
    return on_send_old(node) if ENV.key?("REFINE_KEEP_OLD")
    # refine the children first and keep them (rebuild by identity; see DynArgExhaustion.rebuild_if_changed)
    refined = DynArgExhaustion.rebuild_if_changed(node, node.children.map { |k| k.is_a?(TypedNode) ? process(k) : k })

    trecv = refined.children[0].ttype
    mth = refined.children[1]
    info = methods_of(trecv)[mth]

    if info.nil? || info[:type].nil?
      # dynamic mode prunes (raises) except for nil receivers; otherwise the node is left as is
      if @dynamic && trecv.to_s != "nil"
        raise NoMethodError, "RefineTypesV2: no signature for #{trecv}##{mth}"
      end
      return refined
    end

    targs = refined.children[2..].map &:ttype
    begin
      refined.update_ttype(compute_tout(trecv, info[:type], targs))
    rescue
      refined # compute_tout failures are ignored, as before
    end
  end

  def handler_missing(node) # AI generated
    return handler_missing_old(node) if ENV.key?("REFINE_KEEP_OLD")
    DynArgExhaustion.rebuild_if_changed(node, node.children.map { |k| k.is_a?(TypedNode) ? process(k) : k })
  end

  # ---- original methods, kept unchanged for REFINE_KEEP_OLD=1 ----
  # from DynamicRefineTypes#on_envref (only in dynamic mode; RefineTypesPass did not follow envrefs)
  def on_envref_old(node)
    return node unless @dynamic

    ref = node.children[0]
    info = @env.get_expr(ref)
    processed = process(info[:expr])
    if processed.ttype.is_a? RDL::Type::DynamicType
      @env.update_expr(ref, info[:expr].update_ttype(processed.ttype))
      info = @env.get_expr(ref)

      if info[:expr].ttype.is_a?(RDL::Type::MethodType)
        ttype = info[:expr].ttype.ret
      else
        ttype = info[:expr].ttype
      end
      node.update_ttype(ttype)
    else
      node
    end
  end

  def on_send_old(node)
    # result discarded, as in RefineTypesPass and DynamicRefineTypes (see header)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

    trecv = node.children[0].ttype
    mth = node.children[1]
    mthds = methods_of(trecv)
    info = mthds[mth]

    if info.nil? || info[:type].nil?
      # DynamicRefineTypes pruned (raised) here except for nil receivers; RefineTypesPass leaves the node
      if @dynamic && trecv.to_s != "nil"
        raise NoMethodError, "RefineTypesV2: no signature for #{trecv}##{mth}"
      end
      return node
    end

    targs = node.children[2..].map &:ttype
    begin
      tret = compute_tout(trecv, info[:type], targs)
      node.update_ttype(tret)
    rescue
      # compute_tout failures are ignored (returns nil, so process keeps the original node)
    end
  end

  def handler_missing_old(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
