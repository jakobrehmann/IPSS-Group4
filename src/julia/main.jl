include("model.jl")
include("model_utils.jl")
include("viz.jl")


# PARAMS PER RUN
seeds = 500
iterations = 90
base_susceptibility = 0.1
n_nodes = 500
# p_edge = 0.0097
n_infected_agents = 1


# GLOBAL PARAMS
scenarios = ["homogenous", "heterogenous", "heterogenous_assortative"]
network_structures = ["random", "smallworld", "preferential"]

@time begin
    network_to_scenario_to_seed_to_data = Dict()
    for network_structure in network_structures
        network_to_scenario_to_seed_to_data[network_structure] = Dict()
        for scenario in scenarios
            network_to_scenario_to_seed_to_data[network_structure][scenario] = Dict("degree" => [], "group" => [], "max_infections" => [], "max_infections_time" => [], "cum_infections" => [])
            infectious_avg = zeros(iterations)

            # create model
            model, net = initialize(;
                seed=97234097,
                n_nodes=n_nodes,
                # p_edge=p_edge,
                # n_infected_agents=n_infected_agents,
                base_susceptibility=base_susceptibility,
                hom_het=scenario,
                network_structure=network_structure
            )

            for seed in 1:seeds

                println("#######################")
                println("Network: $(network_structure) --  Scenario: $(scenario) -- Seed: $(seed)")
                println("#######################")

                # infect a random group of agents
                # TODO: make sure the same agent isn't infected multiple times #TODO @jakobrehmann: Pls check my work + give feedbck
                i = 0

                infected_agents_group = []
                infected_agents_degree = []

                for agent in allagents(model)
                    agent.health_status = 0
                end

                while i < n_infected_agents
                    sick_person = random_agent(model) # does this use the seed?
                    if sick_person.health_status == 0
                        sick_person.health_status = 2
                        push!(infected_agents_group, sick_person.group)
                        push!(infected_agents_degree, degree(net, sick_person.pos))
                        i += 1
                    end
                end

                # run model for x iterations & extract vector w/ disease state counts per iteration
                plot, susc, susc_1, susc_2, exposed, infectious, infectious_1, infectious_2, recovered = runModelWithPlot(model, iterations)

                infectious_avg += infectious / seeds

                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["degree"], infected_agents_degree[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["group"], infected_agents_group[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["max_infections"], findmax(infectious)[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["max_infections_time"], findmax(infectious)[2])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["cum_infections"], sum(infectious))
            end
            network_to_scenario_to_seed_to_data[network_structure][scenario]["infections_avg"] = infectious_avg
        end

    end
end

labels_random = []
lines_random = []

network_structure = "random"
for scenario in scenarios
    push!(labels_random, "I ($(network_structure)-$(scenario))")
    push!(lines_random, network_to_scenario_to_seed_to_data[network_structure][scenario]["infections_avg"])
end

Plots.plot(1:iterations,
    lines_random / n_nodes * 100,
    labels=reshape(labels_random, (1, length(labels_random))),
    xlabel="time [t]",
    ylabel="proportion of population [%]",
    linewidth = 3, 
    guidefontsize = 12,
    tickfontsize = 12,
    legendfontsize = 12,
    )

    savefig("random.png")



labels_small = []
lines_small = []

network_structure = "smallworld"
for scenario in scenarios
    push!(labels_small, "I ($(network_structure)-$(scenario))")
    push!(lines_small, network_to_scenario_to_seed_to_data[network_structure][scenario]["infections_avg"])
end

Plots.plot(1:iterations,
    lines_small / n_nodes * 100,
    labels=reshape(labels_small, (1, length(labels_small))),
    xlabel="time [t]",
    ylabel="proportion of population [%]",
    linewidth = 3, 
    guidefontsize = 12,
    tickfontsize = 12,
    legendfontsize = 12,
    )


    savefig("smallworld.png")







labels_pref = []
lines_pref = []

network_structure = "preferential"
for scenario in scenarios
    push!(labels_pref, "I ($(network_structure)-$(scenario))")
    push!(lines_pref, network_to_scenario_to_seed_to_data[network_structure][scenario]["infections_avg"])
end

Plots.plot(1:iterations,
    lines_pref / n_nodes * 100,
    labels=reshape(labels_pref, (1, length(labels_pref))),
    xlabel="time [t]",
    ylabel="proportion of population [%]",
    linewidth = 3, 
    guidefontsize = 12,
    tickfontsize = 12,
    legendfontsize = 12,
    )


    savefig("preferential.png")





labels = []
lines = []
for network_structure in network_structures
    for scenario in scenarios
        push!(labels, "I ($(network_structure)-$(scenario))")
        push!(lines, network_to_scenario_to_seed_to_data[network_structure][scenario]["infections_avg"])
    end
end


Plots.plot(1:iterations,
    lines / n_nodes * 100,
    labels=reshape(labels, (1, length(labels))))


Plots.scatter(network_to_scenario_to_seed_to_data["random"]["heterogenous"]["degree"],network_to_scenario_to_seed_to_data["random"]["heterogenous"]["max_infections"])



# model, x, y = initialize(;
#                           seed=1,
#                           n_nodes=n_nodes,
#                           n_edges=n_edges,
#                           n_infected_agents=n_infected_agents,
#                           base_susceptibility=base_susceptibility,
#                           hom_het="homogenous",
#                           network_structure="random"
#                       )



# x
# y

# model = initialize(;hom_het = "heterogenous")
# figs, abmobs = abmexploration(model; agent_step!, ac = person_color, am = person_shape, as = 25, adata)
# figs


seeds = 500
iterations = 90
base_susceptibility = 0.1
n_nodes = 500
# p_edge = 0.0097
n_infected_agents = 1


model, net = initialize(;
    seed=97234097,
    n_nodes=n_nodes,
    # p_edge=p_edge,
    # n_infected_agents=n_infected_agents,
    base_susceptibility=base_susceptibility,
    hom_het="heterogenous_assortative",
    network_structure="smallworld")



figs, abmobs = abmexploration(model; agent_step!, ac=person_color, am=person_shape, as=25, adata)
figs