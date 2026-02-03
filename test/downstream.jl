using Downloads, JSON, Test

function available_channels()
    juliaup = "https://julialang-s3.julialang.org/juliaup"
    for i ∈ 1:6
        buf = PipeBuffer()
        Downloads.download("$juliaup/DBVERSION", buf)
        dbversion = VersionNumber(readline(buf))
        dbversion.major == 1 || continue
        buf = PipeBuffer()
        Downloads.download(
            "$juliaup/versiondb/versiondb-$dbversion-x86_64-unknown-linux-gnu.json",
            buf,
        )
        json = JSON.parse(buf)
        haskey(json, "AvailableChannels") || continue
        return json["AvailableChannels"]
        sleep(10i)
    end
    return
end

"""
julia> is_latest(:lts)
julia> is_latest(:release)
"""
function is_latest(variant)
    channels = available_channels()
    ver = let var::String = (
        release = "release",
        rel = "release",
        lts = "lts",
        release_candidate = "rc",
        alpha = "alpha",
        beta = "beta",
        rc = "rc",
    )[variant]
        VersionNumber(split(channels[var]["Version"], '+') |> first)
    end
    dev = occursin("DEV", string(VERSION))  # or length(VERSION.prerelease) < 2
    return !dev && (
        VersionNumber(ver.major, ver.minor, 0, ("",)) ≤ VERSION < VersionNumber(ver.major, ver.minor + 1)
    )
end

(is_ci() && Sys.islinux() && is_latest(:release)) && @testset "downstream" begin
    tmpd = mktempdir()
    Plots_jl = joinpath(tmpd, "Plots.jl")
    @test Cmd(`$(Base.julia_cmd()) $(joinpath(@__DIR__, "downstream_dev.jl")) $tmpd`) |> run |> success
    script = tempname()
    write(
        script,
        """
        using Pkg

        Pkg.activate(joinpath("$Plots_jl", "PlotsBase"))
        Pkg.develop(path="$(joinpath(@__DIR__, ".."))")

        import Gaston  # trigger `PlotsBase` extension
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
        """
    )
    @test Cmd(`$(Base.julia_cmd()) --project=@. $script`; dir = Plots_jl) |> run |> success
end
