# AI generated (2026-10-20): loaded with RUBYOPT=-r by scripts/ablation/ablate.rb for one ablation round. No source edits.
#   ABLATE_ROUND  JSON {"decls": [{"name","args","read","write"}], "moi": [...]} - extra %dyn declarations added to the
#                 benchmark's ParentsHelper window (declared just before its subtract) and extra methods of interest
#   ABLATE_OUT    JSON written at exit: methods of interest available, types learned, types rejected (hard / soft)
#   ABLATE_CHECK  if set: exit right after subtract (used to check that every pool declaration loads)
require "json"

$__abl_round = JSON.parse(File.read(ENV["ABLATE_ROUND"]))
$__abl_infer = []
$__abl_moi = nil

module AblateParents
  def subtract(*a)
    $__abl_round["decls"].each { |d|
      sig = "(#{(['%dyn'] * d['args']).join(', ')}) -> %dyn"
      opts = { wrap: false }
      opts[:read] = d["read"] if d["read"]
      opts[:write] = d["write"] if d["write"]
      RDL.type :DynamicType, d["name"].to_sym, sig, **opts
    }
    r = super
    if ENV["ABLATE_CHECK"]
      $stderr.puts "[ABLATE_CHECK] declared #{$__abl_round['decls'].size} extra signatures, all loaded"
      exit!(0)
    end
    r
  end
end

module AblateProxy
  def initialize(mth_name, type, components, prog_size, max_hash_size, consts, enable_nil, moi, exclude)
    moi = (moi + $__abl_round["moi"].map(&:to_sym)).uniq
    $__abl_moi = moi
    super(mth_name, type, components, prog_size, max_hash_size, consts, enable_nil, moi, exclude)
  end
end

module AblateInfer
  def initialize(*a)
    super
    $__abl_infer << self
  end
end

TracePoint.new(:end) { |tp|
  case tp.self.name
  when "ParentsHelper" then tp.self.singleton_class.prepend(AblateParents) unless tp.self.singleton_class.ancestors.include?(AblateParents)
  when "SynthesizerProxy" then tp.self.prepend(AblateProxy) unless tp.self.ancestors.include?(AblateProxy)
  when "InferTypes" then tp.self.prepend(AblateInfer) unless tp.self.ancestors.include?(AblateInfer)
  end
}.enable

at_exit {
  # rake's parent process loads this hook too and exits last; only the test process (which built a proxy) writes
  next if $__abl_moi.nil?
  learned, hard, soft = [], [], []
  $__abl_infer.each { |ti|
    ti.type_successes.each_value { |list| list.each { |s| learned << ti.type_to_s(s).strip } }
    ti.type_errs.each_value { |list|
      list.each { |e| (e[:args] == :ALL || e[:type_level] ? hard : soft) << ti.type_to_s(e).strip.sub(/ => :(type_)?except\z/, "") }
    }
  }
  File.write(ENV["ABLATE_OUT"], JSON.generate({ "moi" => ($__abl_moi || []).map(&:to_s), "learned" => learned.uniq,
                                                 "rejected_hard" => hard.uniq, "rejected_soft" => soft.uniq }))
}
