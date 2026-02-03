using Pkg

LibGit2 = Pkg.GitTools.LibGit2
TOML = Pkg.TOML

failsafe_clone_checkout(path, url, pkg = nothing; stable = true) = begin
    local repo
    for i in 1:6
        try
            repo = Pkg.GitTools.ensure_clone(stdout, path, url)
            break
        catch err
            @warn err
            sleep(20i)
        end
    end

    name, _ = splitext(basename(url))
    registries = joinpath(first(DEPOT_PATH), "registries")
    general = joinpath(registries, "General")
    versions = joinpath(general, name[1:1], name, "Versions.toml")
    if !isfile(versions)
        mkpath(general)
        run(setenv(`tar xf $general.tar.gz`; dir = general))
    end
    @assert isfile(versions)

    if stable
        v_stable = maximum(VersionNumber.(keys(TOML.parse(read(versions, String)))))
        obj = LibGit2.GitObject(repo, "v$v_stable")
        hash = if isa(obj, LibGit2.GitTag)
            LibGit2.target(obj)
        else
            LibGit2.GitHash(obj)
        end |> string
        LibGit2.checkout!(repo, hash)
    end

    toml = if pkg ≢ nothing && (fn = joinpath(path, pkg, "Project.toml")) |> isfile  # monorepo layout
        fn
    elseif (fn = joinpath(path, "Project.toml")) |> isfile  # single package toplevel
        fn
    end
    @assert isfile(toml) "$toml does not exist, bailing out !"
    toml
end

fake_supported_version!(toml) = begin
    # fake the supported Gaston version for testing (for `Pkg.develop`)
    Gaston_version = Pkg.Types.read_package(normpath(@__DIR__, "..", "Project.toml")).version
    parsed_toml = TOML.parse(read(toml, String))
    parsed_toml["compat"]["Gaston"] = string(Gaston_version)
    open(toml, "w") do io
        TOML.print(io, parsed_toml)
    end
    nothing
end

dn = joinpath(ARGS[1], "Plots.jl")
toml = failsafe_clone_checkout(dn, "https://github.com/JuliaPlots/Plots.jl", "PlotsBase"; stable = false)
docs = joinpath(dn, "docs")
isdir(docs) && rm(docs; recursive=true)  # ERROR: LoadError: empty intersection between Gaston@2.0.1 and project compatibility ∅
fake_supported_version!(toml)
