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

  # from DynamicRefineTypes#on_envref (only in dynamic mode; RefineTypesPass did not follow envrefs)
  def on_envref(node)
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

  def on_send(node)
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

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
