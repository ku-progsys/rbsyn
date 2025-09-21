def any_or_k(trec)
  case trec
  when RDL::Type::FiniteHashType
    RDL::Type::UnionType.new(* trec.elts.keys.map { |sym| RDL::Type::SingletonType.new(sym) })
  else
    RDL::Globals.parser.scan_str "#T k"
  end
end

def output_type(trec, targs)
  case trec
  when RDL::Type::FiniteHashType
    targ = targs[0]
    case targ
    when RDL::Type::SingletonType
      trec.elts[targ.val]
    when RDL::Type::UnionType
      RDL::Type::UnionType.new(*targ.types.map { |t|
        val = trec.elts[t.val]
        val.is_a?(RDL::Type::OptionalType) ? val.type : val
      })
    else
      raise RuntimeError, "unhandled type #{targ}"
    end
  else
    raise RuntimeError, "unhandled type #{trec}"
  end
end
