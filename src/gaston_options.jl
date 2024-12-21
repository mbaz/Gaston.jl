# Macro and functions to handle options in brackets

macro Q_str(s)
    "'$s'"
end

function pushorreplace!(v, pair)
    pf = pair.first
    for i in eachindex(v)
        if v[i].first == pf
            # replace
            v[i] = pair
            return
        end
    end
    # insert
    push!(v, pair)
end

function expand(d...)
    dd = Pair[]
    for (k,v) in d
        if v isa Vector{Pair}
            for (k1,v1) in v
                push!(dd, k1 => v1)
            end
        else
            push!(dd, k => v)
        end
    end
    return dd
end

function prockey(key)
    if @capture(key, a_ = b_)
        return :($(string(a)) => $b)
    elseif @capture(key, g_...)
        return :("theme" => $g)
    elseif @capture(key, a_)
        return :($(string(a)) => true)
    end
end

function procopts(d)
    if @capture(d, {xs__})
        return :($(expand)($(map(prockey, xs)...)))
    elseif @capture(d, f_(xs__))
        return :($f($(map(procopts, xs)...)))
    else
        return d
    end
end

macro gpkw(ex)
    esc(postwalk(procopts, ex))
end

macro plot(ex...)
    args = (esc(procopts(v)) for v in ex)
    :( plot($(args...)) )
end

macro plot!(ex...)
    args = (esc(procopts(v)) for v in ex)
    :( plot!($(args...)) )
end

macro splot(ex...)
    args = (esc(procopts(v)) for v in ex)
:( splot($(args...)) )
end

macro splot!(ex...)
    args = (esc(procopts(v)) for v in ex)
    :( splot!($(args...)) )
end
