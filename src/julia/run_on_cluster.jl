include("model.jl")

params = Dict(
    :seeds => 100,
    :iterations => 200,
    :base_susceptibilities => [parse(Float64, ARGS[1])],
    :recovery_rate => 0.2,
    :n_nodes => 100,
    :network_structures => ["regular", "smallworld", "random", "preferential"],
    :local_global_scenarios => ["base", "local1", "local2", "local1_and_2", "global"],
    :mean_degree => 10,
    :days_until_showing_symptoms => parse(Int64, ARGS[2]),
    :output_folder => ARGS[3]
)

run_model(params)
