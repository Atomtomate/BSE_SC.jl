"""
    shell_indices(Nν_full::Int, Nν_shell::Int)

Constructs 4 sets of indices for a square array of size `Nν_full` with a shell `Nν_shell` entries on each 
side in which asymptotic behaviour is assumed.
Returns `I_core`, `I_corner`, `I_top_bottom`, `I_left_right` with indices of the corresponding regions.
"""
function shell_indices(Nν_full::Int, Nν_shell::Int)
    ind_inner = (Nν_shell+1):(Nν_full-Nν_shell)
    ind_outer = union(1:(Nν_shell),(Nν_full-Nν_shell+1):Nν_full)
    I_top_bottom = sort([CartesianIndex(νi,νpi) for νi in ind_outer for νpi in ind_inner])
    I_left_right = sort([CartesianIndex(νi,νpi) for νi in ind_inner for νpi in ind_outer])
    I_corner = sort([CartesianIndex(νi,νpi) for νi in ind_outer for νpi in ind_outer])
    I_core = sort([CartesianIndex(νi,νpi) for νi in ind_inner for νpi in ind_inner])
    return I_core, I_corner, I_top_bottom, I_left_right
end

"""
    aux_indices(ind_lst::Vector{CartesianIndex{2}}, ωi::Int, n_iω::Int, n_iν::Int, shift::Int)

Constructs two index lists, one for ν-ν' and one for ν+ν'+ω, from input index list `ind_lst`.
These lists are used by [`improve_χ!`](@ref) interally.
"""
function aux_indices(ind_lst::Vector{CartesianIndex{2}}, ωi::Int, n_iω::Int, n_iν::Int, shift::Int)
    ind1_list = Vector{Int}(undef, length(ind_lst))    # ν' - ν
    ind2_list = Vector{Int}(undef, length(ind_lst))    # ν + ν' + ω
    for (i,ind) in enumerate(ind_lst)
        ind1_list[i] = ωn_to_ωi(ind[1] - ind[2])
        ωn, νn, = OneToIndex_to_Freq(ωi, ind[1], n_iω, n_iν, shift)
        ωn, νpn = OneToIndex_to_Freq(ωi, ind[2], n_iω, n_iν, shift)
        ind2_list[i] = ωn_to_ωi(νn + νpn + 1 + ωn)
    end
    return ind1_list, ind2_list
end

#TODO: index struct
"""
    improve_χ!()

Improves asymptotics of `χsp` and `χch`.
TODO: full documentation here.
"""
function improve_χ!(type::Symbol, ωi::Int, χr::AbstractArray{ComplexF64,2}, χ₀::AbstractArray{ComplexF64,1}, 
                U::Float64, β::Float64, shift::Int, h::BSE_SC_Helper; Nit=200, atol=1e-9)
    f = if type == :sp
        update_Fsp!
    elseif type == :ch
        update_Fch!
    else
        error("Unkown channel. Only sp/ch implemented")
    end

    fill!(h.Fr, 0.0)
    fill!(h.λr, 0.0)
    for i in h.I_core
        δ_ννp = Float64(i[1] == i[2])
        h.Fr[i] = - β^2 * (χr[i] - δ_ννp*χ₀[i[1]])/(χ₀[i[1]]*χ₀[i[2]])
    end
    χr_old = 0.0
    converged = false
    i = 0
    while !converged && (i < Nit)
        χr_n = update_χ!(h.λr, χr, h.Fr, χ₀, β, h.I_asympt)
        f(χr_n, U, ωi, h)
        if (abs(χr_old - χr_n) < atol)
            converged = true
        else
            i += 1
            χr_old = χr_n
        end
    end
    return i
end

function update_Fsp!(χ::ComplexF64, U::Float64, ωi::Int, h::BSE_SC_Helper)
    i1_l = h.ind1_list
    i2_l = view(h.ind2_list, :, ωi)
    for i in 1:length(h.I_asympt)
        i1 = h.I_asympt[i]
        i2 = i1_l[i]
        i3 = i2_l[i]
        h.Fr[i1] = -U - (U^2)*χ + (U^2/2)*h.χch_asympt[i2] - (U^2/2)*h.χsp_asympt[i2] + (U^2)*h.χpp_asympt[i3] # + U*λ[i1[1]]  + U*λ[i1[2]]
    end
    for i in 1:length(h.I_r)
        i1 = h.I_r[i]
        h.Fr[i1] += U*h.λr[i1[1]] + 1*(U^2)*χ
    end
    for i in 1:length(h.I_t)
        i1 = h.I_t[i]
        h.Fr[i1] += U*h.λr[i1[2]] + 1*(U^2)*χ
    end
end

function update_Fch!(χ::ComplexF64, U::Float64, ωi::Int, h::BSE_SC_Helper)
    i1_l = h.ind1_list
    i2_l = view(h.ind2_list, :, ωi)
    for i in 1:length(h.I_asympt)
        i1 = h.I_asympt[i]
        i2 = i1_l[i]
        i3 = i2_l[i]
        h.Fr[i1] = U - (U^2)*χ  + (U^2/2)*h.χch_asympt[i2] + 3*(U^2/2)*h.χsp_asympt[i2] - (U^2)*h.χpp_asympt[i3] #- U*λ[i1[1]] - U*λ[i1[2]]
    end
    for i in 1:length(h.I_r)
        i1 = h.I_r[i]
        h.Fr[i1] += -U*h.λr[i1[1]] + 1*(U^2)*χ
    end
    for i in 1:length(h.I_t)
        i1 = h.I_t[i]
        h.Fr[i1] += -U*h.λr[i1[2]] + 1*(U^2)*χ
    end
end

function update_χ!(λ, χ::AbstractArray, F::AbstractArray, χ₀::AbstractArray, β::Float64, indices)
    for i in indices
        if i[1] == i[2] 
            χ[i] = χ₀[i[1]]
        else
            χ[i] = 0.0
        end
        χ[i] -= χ₀[i[1]]*F[i]*χ₀[i[2]]/(β^2)
    end
    #TODO: absorb into sum
    for νk in 1:size(χ,2)
        λ[νk]  = (sum(χ[:,νk]) / (-χ₀[νk])) + 1
    end
    χs = sum(χ)/(β^2)
    return χs
end


function improve_χ_standalone!(χsp, χch, χ₀, χsp_asympt, χch_asympt, χpp_asympt, U::Float64, β::Float64, Nν_shell::Int, shift::Int)
    Nν_full = size(χch, 1)
    #TODO: this assumes -nν:nν-1
    Nν_c = size(χch, 1) - 2*Nν_shell
    n_iω   = trunc(Int,size(χch,3)/2)
    n_iν   = trunc(Int,Nν_full/2)

    # internal arrays
    I_core, I_corner, I_t, I_r = shell_indices(Nν_full, Nν_shell)
    I_all = sort(union(I_core, I_corner, I_r, I_t))
    I_asympt = sort(union(I_corner, I_r, I_t))

    Fsp = Array{ComplexF64,2}(undef, Nν_full, Nν_full)
    Fch = similar(Fsp)
    λsp = Array{ComplexF64, 1}(undef, Nν_full)
    λch = similar(λsp)

    for ωi in axes(χch,3) #(n_iω+1):(n_iω+1)#
        # setup 
        ind1_list, ind2_list= aux_indices(I_corner, ωi, n_iω, n_iν, shift)

        #println(size(χ₀))
        fill!(Fsp, 0.0)
        fill!(Fch, 0.0)
        for i in I_core
            δ_ννp = Float64(i[1] == i[2])
            Fsp[i] = - β^2 * (χsp[i,ωi] - δ_ννp*χ₀[i[1],ωi])/(χ₀[i[1],ωi]*χ₀[i[2],ωi])
            Fch[i] = - β^2 * (χch[i,ωi] - δ_ννp*χ₀[i[1],ωi])/(χ₀[i[1],ωi]*χ₀[i[2],ωi])
        end
        # SC
        Nit = 200
        χsp_old = 0.0
        χch_old = 0.0
        converged = false
        i = 0
        while !converged && (i < Nit)
            #TODO: while !converged
            χsp_n = update_χ!(λsp, view(χsp,:,:,ωi), Fsp, view(χ₀,:,ωi), β, I_asympt)
            χch_n = update_χ!(λch, view(χch,:,:,ωi), Fch, view(χ₀,:,ωi), β, I_asympt)
            update_Fsp!(Fsp, λsp, χsp_n, χch_asympt, χsp_asympt, χpp_asympt, U, I_corner, I_r, I_t, ind1_list, ind2_list_corner)
            update_Fch!(Fch, λch, χch_n, χch_asympt, χsp_asympt, χpp_asympt, U, I_corner, I_r, I_t, ind1_list, ind2_list_corner) 
            #TODO: check convergence
            if (abs(χch_old - χch_n) < atol) && (abs(χsp_old - χsp_n) < atol)
                converged = true
            else
                i += 1
                χch_old = χch_n
                χsp_old = χsp_n
            end
        end
    end
end

