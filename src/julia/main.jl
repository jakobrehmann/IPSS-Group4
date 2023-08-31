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
            network_to_scenario_to_seed_to_data[network_structure][scenario] = Dict("degree" => [],"group" => [], "max_infections" => [], "max_infections_time"  => [], "cum_infections"  => [])
            infectious_avg = zeros(iterations)
            for seed in 1:seeds
                # create model
                model, infected_agents_group, infected_agents_degree = initialize(;
                    seed=seed,
                    n_nodes=n_nodes,
                    n_edges=n_edges,
                    n_infected_agents=n_infected_agents,
                    base_susceptibility=base_susceptibility,
                    hom_het=scenario,
                    network_structure=network_structure
                )

                println(infected_agents_group)
                println(infected_agents_degree)

                # run model for x iterations & extract vector w/ disease state counts per iteration
                plot, susc, susc_1, susc_2, exposed, infectious, infectious_1, infectious_2, recovered = runModelWithPlot(model, iterations)

                infectious_avg += infectious / seeds

                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["degree"], infected_agents_degree[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["group"], infected_agents_group[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["max_infections"], findmax(infectious)[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["max_infections_time"], findmax(infectious)[2])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["cum_infections"],  sum(infectious))
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


model, x, y = initialize(;
                          seed=1,
                          n_nodes=n_nodes,
                          n_edges=n_edges,
                          n_infected_agents=n_infected_agents,
                          base_susceptibility=base_susceptibility,
                          hom_het="homogenous",
                          network_structure="random"
                      )



x
y

model = initialize(;hom_het = "heterogenous")
figs, abmobs = abmexploration(model; agent_step!, ac = person_color, am = person_shape, as = 25, adata)
figs

