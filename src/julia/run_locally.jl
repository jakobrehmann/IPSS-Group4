include("model.jl")

params = Dict(
    :seeds => 100,
    :iterations => 200,
    :base_susceptibilities => [0.1:0.05:0.3;],
    :recovery_rate => 0.2,
    :n_nodes => 1000,
    :network_structures => ["regular", "smallworld", "random", "preferential"],
    :local_global_scenarios => ["base", "local1", "local2", "local1_and_2", "global"],
    :mean_degree => 10,
    :days_until_showing_symptoms => 1,
    :output_folder => missing
)

run_model(params)

