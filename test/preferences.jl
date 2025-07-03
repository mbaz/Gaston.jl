using Preferences, Gaston

const PREVIOUS_DEFAULT_GNUPLOT = load_preference(Gaston, "gnuplot_binary")

invalidate_compiled_cache!(m::Module) =  # make sure the compiled cache is removed
    rm.(Base.find_all_in_cache_path(Base.PkgId(m, string(nameof(m)))))

@testset "Invalid path" begin
    script = tempname()
    set_preferences!(Gaston, "gnuplot_binary" => "/_some_non_existent_invalid_path_"; force = true)
    invalidate_compiled_cache!(Gaston)
    write(
        script,
        """
        using Gaston, Test
        res = @testset "[subtest] invalid gnuplot_binary path" begin
            @test Gaston.config.exec ≡ nothing
        end
        exit(res.n_passed == 1 ? 0 : 123)
        """
    )
    @test run(`$(Base.julia_cmd()) $script`) |> success
end

Sys.islinux() && @testset "System gnuplot" begin
    script = tempname()
    sys_gnuplot = Sys.which("gnuplot")
    set_preferences!(Gaston, "gnuplot_binary" => sys_gnuplot; force = true)
    invalidate_compiled_cache!(Gaston)
    write(
        script,
        """
        using Gaston, Test
        res = @testset "[subtest] system gnuplot path" begin
            @test Gaston.config.exec.exec == ["$sys_gnuplot"]
        end
        exit(res.n_passed == 1 ? 0 : 123)
        """
    )
    @test run(`$(Base.julia_cmd()) $script`) |> success
end

if PREVIOUS_DEFAULT_GNUPLOT ≡ nothing
    # restore the absence of a preference
    delete_preferences!(Gaston, "gnuplot_binary"; force = true)
else
    # reset to previous state
    set_preferences!(Gaston, "gnuplot_binary" => PREVIOUS_DEFAULT_GNUPLOT; force = true)
end
