function histogram(data::Coord;bins::Int=10,norm::Real=1.0,args...)
    # validation
    bins < 1 && throw(DomainError(bins, "at least one bin is required"))
    norm < 0 && throw(DomainError(norm, "norm must be a positive number."))

    x, y = hist(data,bins)
    y = norm*y/(step(x)*sum(y))  # make area under histogram equal to norm

    bar(x, y; boxwidth="0.9 relative", fillstyle="solid 0.5",args...)
end
