using Pkg

Pkg.activate(joinpath(pwd(), "PlotsBase"))
Pkg.develop(path=joinpath(@__DIR__, ".."))

using Gaston
Pkg.status(["Gaston", "PlotsBase"])

# test basic plots creation and bitmap or vector exports
using PlotsBase, Test

prefix = tempname()
@time for i ∈ 1:length(PlotsBase._examples)
  i ∈ PlotsBase._backend_skips[:gaston] && continue  # skip unsupported examples
  PlotsBase._examples[i].imports ≡ nothing || continue  # skip examples requiring optional test deps
  pl = PlotsBase.test_examples(:gaston, i; disp = false)
  for ext in (".png", ".pdf")  # TODO: maybe more ?
    fn = string(prefix, i, ext)
    PlotsBase.savefig(pl, fn)
    @test filesize(fn) > 1_000
  end
end
