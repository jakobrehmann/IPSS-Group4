include("model.jl")

params = Dict(
    :seeds => 20,
    :iterations => 200,
    :base_susceptibilities => [0.1],
    :recovery_rate => 0.2,
    :n_nodes => 1000,
    :network_structures => ["smallworldreg","random"],
    :local_global_scenarios => ["base"],
    :mean_degree => 10,
    :days_until_showing_symptoms => 1,
    :output_folder => missing
)

run_model(params)

