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
function improve_χ!(χsp, χch, χ₀, χsp_asympt, χch_asympt, χpp_asympt, Fsp, Fch, λsp, λch, U::Float64, β::Float64, Nν_shell::Int, shift::Int, I_core, I_corner, I_t, I_r, I_all, I_asympt, ind1_list_corner, ind2_list_corner)
    n_iω   = trunc(Int,size(χch,3)/2)
    n_iν   = trunc(Int,size(χch,1)/2)

    for ωi in axes(χch,3)
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
            χsp_n = update_χ!(λsp, view(χsp,:,:,ωi), Fsp, view(χ₀,:,ωi), β, I_aympt)
            χch_n = update_χ!(λch, view(χch,:,:,ωi), Fch, view(χ₀,:,ωi), β, I_aympt)
            update_Fsp!(Fsp, λsp, χsp_n, χch_asympt, χsp_asympt, χpp_asympt, U, I_corner, I_r, I_t, ind1_list_corner, ind2_list_corner)
            update_Fch!(Fch, λch, χch_n, χch_asympt, χsp_asympt, χpp_asympt, U, I_corner, I_r, I_t, ind1_list_corner, ind2_list_corner) 
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


function improve_χ_standalone!(χsp, χch, χ₀, χsp_asympt, χch_asympt, χpp_asympt, U::Float64, β::Float64, Nν_shell::Int, shift::Int)
    Nν_full = size(χch, 1)
    #TODO: this assumes -nν:nν-1
    Nν_c = size(χch, 1) - 2*Nν_shell
    n_iω   = trunc(Int,size(χch,3)/2)
    n_iν   = trunc(Int,Nν_full/2)

    # internal arrays
    I_core, I_corner, I_t, I_r = shell_indices(Nν_full, Nν_shell)
    I_all = sort(union(I_core, I_corner, I_r, I_t))
    I_aympt = sort(union(I_corner, I_r, I_t))

    Fsp = Array{ComplexF64,2}(undef, Nν_full, Nν_full)
    Fch = similar(Fsp)
    λsp = Array{ComplexF64, 1}(undef, Nν_full)
    λch = similar(λsp)

    for ωi in axes(χch,3) #(n_iω+1):(n_iω+1)#
        print(ωi )
        flush(stdout)
        # setup 
        ind1_list_corner, ind2_list_corner = aux_indices(I_corner, ωi, n_iω, n_iν, shift)

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
            χsp_n = update_χ!(λsp, view(χsp,:,:,ωi), Fsp, view(χ₀,:,ωi), β, I_aympt)
            χch_n = update_χ!(λch, view(χch,:,:,ωi), Fch, view(χ₀,:,ωi), β, I_aympt)
            update_Fsp!(Fsp, λsp, χsp_n, χch_asympt, χsp_asympt, χpp_asympt, U, I_corner, I_r, I_t, ind1_list_corner, ind2_list_corner)
            update_Fch!(Fch, λch, χch_n, χch_asympt, χsp_asympt, χpp_asympt, U, I_corner, I_r, I_t, ind1_list_corner, ind2_list_corner) 
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

function update_Fsp!(F, λ, χ, χch_asympt, χsp_asympt, χpp_asympt, U::Float64, I_corner, I_r, I_t, ind1_list_corner, ind2_list_corner)
    for i in 1:length(I_corner)
        i1 = I_corner[i]
        i2 = ind1_list_corner[i]
        i3 = ind2_list_corner[i]
        F[i1] = -U + (U^2/2)*χch_asympt[i2] - (U^2/2)*χsp_asympt[i2] + (U^2)*χpp_asympt[i3] - (U^2)*χ # + U*λ[i1[1]]  + U*λ[i1[2]]
    end
    for i in 1:length(I_r)
        i1 = I_r[i]
        F[i1] = -U  + U*λ[i1[1]]
    end
    for i in 1:length(I_t)
        i1 = I_t[i]
        F[i1] = -U  + U*λ[i1[2]]
    end
end

function update_Fch!(F, λ, χ, χch_asympt, χsp_asympt, χpp_asympt, U::Float64, I_corner, I_r, I_t, ind1_list_corner, ind2_list_corner)
    for i in 1:length(I_corner)
        i1 = I_corner[i]
        i2 = ind1_list_corner[i]
        i3 = ind2_list_corner[i]
        F[i1] = U + (U^2/2)*χch_asympt[i2] + 3*(U^2/2)*χsp_asympt[i2] - (U^2)*χpp_asympt[i3] - (U^2)*χ #- U*λ[i1[1]] - U*λ[i1[2]]
    end
    for i in 1:length(I_r)
        i1 = I_r[i]
        F[i1] = U  - U*λ[i1[1]]
    end
    for i in 1:length(I_t)
        i1 = I_t[i]
        F[i1] = U  - U*λ[i1[2]]
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
