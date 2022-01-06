var documenterSearchIndex = {"docs":
[{"location":"#Documentation-for-BSE_SC.jl","page":"Home","title":"Documentation for BSE_SC.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#Index","page":"Home","title":"Index","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [BSE_SC]\nPages   = [\"build_chi_asympt.jl\", \"helpers.jl\", \"IO.jl\", \"ladderDGA_core.jl\"]","category":"page"},{"location":"#BSE_SC.calc_λ0_impr-Tuple{Symbol, AbstractVector{Int64}, AbstractArray{ComplexF64, 3}, AbstractArray{ComplexF64, 3}, Matrix{ComplexF64}, AbstractMatrix{ComplexF64}, AbstractVector{ComplexF64}, Float64, Float64, BSE_Asym_Helper}","page":"Home","title":"BSE_SC.calc_λ0_impr","text":"calc_λ0_impr(type::Symbol, ωgrid::AbstractVector{Int},\n             F::AbstractArray{ComplexF64,3}, χ₀::AbstractArray{ComplexF64,3}, \n             χ₀_asym::Array{ComplexF64,2}, γ::AbstractArray{ComplexF64,2}, \n             χ::AbstractArray{ComplexF64,1},\n             U::Float64, β::Float64, h::BSE_Asym_Helper)\n\nCalculates improved version of λ₀ = χ₀ ⋆ F. TODO: finish documenation and tests.\n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.calc_χλ_impr-Tuple{Symbol, Int64, AbstractMatrix{ComplexF64}, AbstractVector{ComplexF64}, Float64, Float64, ComplexF64, BSE_Asym_Helper}","page":"Home","title":"BSE_SC.calc_χλ_impr","text":"calc_χλ(type::Symbol, ωn::Int, χ::AbstractArray{ComplexF64,2}, χ₀::AbstractArray{ComplexF64,1}, U::Float64, β::Float64, χ₀_asym::Float64, h::BSE_Asym_Helper)\n\nCalculates the physical susceptibility χ and triangular vertex λ in a given channel type=:sp or type=:ch using knowledge about the asymptotics of the full vertex and tails of the Green's function. χ₀_asym is the ω dependent asymptotic tail of χ₀ and can be calculated with  χ₀_shell_sum.\n\nTODO: optimize     - test for useless allocations     - define subroutine version, for map over ωn\n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.improve_χ!-Tuple{Symbol, Int64, AbstractMatrix{ComplexF64}, AbstractVector{ComplexF64}, Float64, Float64, BSE_SC_Helper}","page":"Home","title":"BSE_SC.improve_χ!","text":"improve_χ!(type::Symbol, ωi::Int, χr, χ₀, U, β, h::BSE_SC_Helper; \n           Nit=200, atol=1e-9)\n\nImproves asymptotics of χr, given a channel type = :sp or :ch, using Eq. 12a 12b  from DOI: 10.1103/PhysRevB.97.235.140 ωn specifies the index of the Matsubara frequency to use. χ₀ is the bubble term, U and β Hubbard-U and temperature. h is a helper struct, see BSE_SC_Helper. Additionally one can specify convergence parameters: Nit:  maximum number of iterations atol: minimum change between total sum over χ between iterations. \n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.BSE_Asym_Helper","page":"Home","title":"BSE_SC.BSE_Asym_Helper","text":"BSE_Asym_Helper\n\nHelper struct for efficient solution of the self consistency. For an example see also setup.\n\nFields\n\nχsp_asympt : ω-asymptotic for the susceptibility in the spin-ph channel\nχch_asympt : ω-asymptotic for the susceptibility in the charge-ph channel\nχpp_asympt : ω-asymptotic for the susceptibility in the pp channel\nNν_shell   : Number of Fermionic frequencies used for asymptotic extension.\nI_core     : Indices for the core (non-asymptotic) region.\nI_asympt   : Indices for the asymptotic region (union of Icorner, It, I_r).\nind1_list  : ν-ν' indices in χsp_asympt and χch_asympt for all I_asympt\nind2_list  : ν+ν'+ω indices in χpp_asympt for all I_asympt\nshift      : 1 or 0 depending on wheter the ν-frequencies are shfited by -ω/2\n\n\n\n\n\n","category":"type"},{"location":"#BSE_SC.BSE_SC_Helper","page":"Home","title":"BSE_SC.BSE_SC_Helper","text":"BSE_SC_Helper\n\nHelper struct for efficient solution of the self consistency. For an example see also setup.\n\nFields\n\nχsp_asympt : ω-asymptotic for the susceptibility in the spin-ph channel\nχch_asympt : ω-asymptotic for the susceptibility in the charge-ph channel\nχpp_asympt : ω-asymptotic for the susceptibility in the pp channel\nFr         : Temporary storage for the full vertex. Used internally to avoid repeated mallocs.\nλr         : Temporary storage for the fermion-boson-vertex. Used internally to avoid repeated mallocs.\nNν_shell   : Number of Fermionic frequencies used for asymptotic extension.\nI_core     : Indices for the core (non-asymptotic) region.\nI_corner   : Indices for the corner (ν AND ν' outside core) region.\nI_t        : Indices for the core (ν outside core) region.\nI_r        : Indices for the core (ν' outside core) region.\nI_asympt   : Indices for the asymptotic region (union of Icorner, It, I_r).\nind1_list  : ν-ν' indices in χsp_asympt and χch_asympt for all I_asympt\nind2_list  : ν+ν'+ω indices in χpp_asympt for all I_asympt\nshift      : 1 or 0 depending on wheter the ν-frequencies are shfited by -ω/2\n\n\n\n\n\n","category":"type"},{"location":"#BSE_SC.aux_indices-Tuple{Vector{CartesianIndex{2}}, Int64, Int64, Int64, Int64}","page":"Home","title":"BSE_SC.aux_indices","text":"aux_indices(ind_lst::Vector{CartesianIndex{2}}, ωi::Int, n_iω::Int, n_iν::Int, shift::Int)\n\nConstructs two index lists, one for ν-ν' and one for ν+ν'+ω, from input index list ind_lst. These lists are used by improve_χ! interally.\n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.shell_indices-Tuple{Int64, Int64}","page":"Home","title":"BSE_SC.shell_indices","text":"shell_indices(Nν_full::Int, Nν_shell::Int)\n\nConstructs 4 sets of indices for a square array of size Nν_full with a shell Nν_shell entries on each  side in which asymptotic behaviour is assumed. Returns I_core, I_corner, I_top_bottom, I_left_right with indices of the corresponding regions.\n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.χ₀_shell_sum-Tuple{OffsetArrays.OffsetMatrix{ComplexF64, AA} where AA<:AbstractMatrix{ComplexF64}, Int64, Float64, Float64, Float64, Float64}","page":"Home","title":"BSE_SC.χ₀_shell_sum","text":"χ₀_shell_sum(core::OffsetMatrix{ComplexF64}, ωn::Union{Int,AbstractVector{Int}}, c2::Float64, c3::Float64)\n\nCalculates the asymptotic sum of ∑ₙ,ₗ χ₀(iωₘ,iνₙ,iνₗ') with n,l from n_iν to ∞. This is done by using the known first three tail coefficients of the Green's function in iνₙ and expanding around n → ∞. ωn can either be a single Matsubara index or an array of indices.  The core region is precalculated using χ₀_shell_sum_core.\n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.χ₀_shell_sum_core-Tuple{Float64, AbstractVector{Int64}, Int64, Int64}","page":"Home","title":"BSE_SC.χ₀_shell_sum_core","text":"χ₀_shell_sum_core(β::Float64, ω_ind_grid::AbstractVector{Int}, n_iν::Int, shift::Int)\n\nCalculates the core region for use in χ₀_shell_sum.\n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.read_gImp-Tuple{String}","page":"Home","title":"BSE_SC.read_gImp","text":"read_gImp(input_file::String)\n\nRead impurity Green's function from JLD2 file at path input_file.\n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.setup-Tuple{String, Int64}","page":"Home","title":"BSE_SC.setup","text":"setup(input_file::String, N_shell::Int)\n\nSetup calculation for data from file. This is used for testing from precomputed data. The file is expected to contain the following fields: β, U, gImp, grid_nBose, grid_nFermi, grid_shift, χDMFTsp, χDMFTch, χ_sp_asympt, χ_ch_asympt, χ_pp_asympt.\n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.OneToIndex_to_Freq-NTuple{5, Int64}","page":"Home","title":"BSE_SC.OneToIndex_to_Freq","text":"OneToIndex_to_Freq(ωi::Int, νi::Int, n_iω::Int, n_iν::Int, shift::Int)\n\nTranslates Julia array indices for bosonic and fermionic axis (i.e. ωi ∈ [1,2n_iω+1], νi ∈ [1,2n_iν]) to  Matsubara index (i.e. ωn ∈ [-n_iω,n_iω], νn ∈ [-n_iν -shiftωn/2, n_iν -shiftωn/2]). shift is used to center the non-asymptotic core of the vertex related functions in the center of the array.\n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.calc_χ₀-Tuple{OffsetArrays.OffsetArray, Float64, Int64, Int64, Int64}","page":"Home","title":"BSE_SC.calc_χ₀","text":"calc_χ₀(Gνω::OffsetArray, β::Float64, n_iω::Int, n_iν::Int, shift::Int)\n\nCalculates the bubble term χ₀ from a given Green's function Gνω. This is mainly used for standalone testing and should generally be calculated independenty in the method using this package.\n\n\n\n\n\n","category":"method"},{"location":"#BSE_SC.ωn_to_ωi-Tuple{Int64}","page":"Home","title":"BSE_SC.ωn_to_ωi","text":"ωn_to_ωi(ωn::Int)\n\nTranslates Matsubara index (i.e. n ∈ [-N,N]) to Julia array index (i.e. i ∈ [1,2N+1]), assuming symmetry around 0!\n\n\n\n\n\n","category":"method"}]
}
