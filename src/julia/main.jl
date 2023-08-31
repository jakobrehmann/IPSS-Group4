include("model.jl")
include("model_utils.jl")
include("viz.jl")


# PARAMS PER RUN
seeds = 100
iterations = 30
base_susceptibility = 0.1
n_nodes = 1000
n_edges = 1000 * 10
n_infected_agents = 1


# GLOBAL PARAMS
scenarios = ["homogenous", "heterogenous"]
network_structures = ["random"]

@time begin
    network_to_scenario_to_seed_to_data = Dict()
    for network_structure in network_structures
        network_to_scenario_to_seed_to_data[network_structure] = Dict()
        for scenario in scenarios
            network_to_scenario_to_seed_to_data[network_structure][scenario] = Dict()
            infectious_avg = zeros(iterations)
            for seed in 1:seeds
                # create model
                model = initialize(;
                    seed=seed,
                    n_nodes=n_nodes,
                    n_edges=n_edges,
                    n_infected_agents=n_infected_agents,
                    base_susceptibility=base_susceptibility,
                    hom_het=scenario,
                    network_structure=network_structure
                )

                # run model for x iterations & extract vector w/ disease state counts per iteration
                plot, susc, susc_1, susc_2, exposed, infectious, infectious_1, infectious_2, recovered = runModelWithPlot(model, iterations)

                infectious_avg += infectious / seeds
            end
            network_to_scenario_to_seed_to_data[network_structure][scenario]["infections_avg"] = infectious_avg
        end

    end
end

labels = []
lines = []
for network_structure in network_structures
    for scenario in scenarios
        push!(labels, "I ($(network_structure)-$(scenario))")
        push!(lines, network_to_scenario_to_seed_to_data[network_structure][scenario]["infections_avg"])
    end
end


Plots.plot(1:iterations, lines / n_nodes * 100, labels=reshape(labels, (1, length(labels))))