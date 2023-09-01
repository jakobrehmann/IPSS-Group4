include("model.jl")
include("model_utils.jl")
include("viz.jl")

using Statistics, Gadfly
############################################

# PARAMS PER RUN
seeds = 5
iterations = 100
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

            println("#######################")
            println("Network: $(network_structure) --  Scenario: $(scenario)")
            println("#######################")

            network_to_scenario_to_seed_to_data[network_structure][scenario] = Dict("degree" => [], "group" => [], "max_infections" => [], "max_infections_time" => [], "cum_infections" => [])
            infectious_avg = zeros(iterations)
            infectious_per_seed = []

            min_infections_per_timestep = 10000 * ones(iterations)
            max_infections_per_timestep = zeros(iterations)

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
                min_infections_per_timestep = min.(min_infections_per_timestep, infectious)
                max_infections_per_timestep = max.(max_infections_per_timestep, infectious)

                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["degree"], infected_agents_degree[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["group"], infected_agents_group[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["max_infections"], findmax(infectious)[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["max_infections_time"], findmax(infectious)[2])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["cum_infections"], sum(infectious))
                push!(infectious_per_seed, infectious)
            end
            network_to_scenario_to_seed_to_data[network_structure][scenario]["infections_avg"] = infectious_avg
            network_to_scenario_to_seed_to_data[network_structure][scenario]["sd"] = (max_infections_per_timestep - min_infections_per_timestep) / 4
            network_to_scenario_to_seed_to_data[network_structure][scenario]["infectious_per_seed"] = infectious_per_seed
        end

    end
end


# Seed Plots

function calc_min_max(network, scenario)
    x = collect(1:iterations)
    y = network_to_scenario_to_seed_to_data[network][scenario]["infections_avg"]
    ymin = network_to_scenario_to_seed_to_data[network][scenario]["infections_avg"] - network_to_scenario_to_seed_to_data[network][scenario]["sd"]
    ymax = network_to_scenario_to_seed_to_data[network][scenario]["infections_avg"] + network_to_scenario_to_seed_to_data[network][scenario]["sd"]

    return x, y, ymin, ymax
end

network = "smallworld"
x_hom, y_hom, ymin_hom, ymax_hom = calc_min_max(network, "homogenous")
x_het, y_het, ymin_het, ymax_het = calc_min_max(network, "heterogenous")
x_het_ass, y_het_ass, ymin_het_ass, ymax_het_ass = calc_min_max(network, "heterogenous_assortative")

Gadfly.plot(layer(x=x_hom, y=y_hom, ymin=ymin_hom, ymax=ymax_hom, Geom.line, Geom.ribbon, Gadfly.Theme(default_color=colorant"blue", lowlight_color = c->RGBA{Float32}(c.r, c.g, c.b, 0.01))),
layer(x=x_het, y=y_het, ymin=ymin_het, ymax=ymax_het, Geom.line, Geom.ribbon, Gadfly.Theme(default_color=colorant"green",  lowlight_color = c->RGBA{Float32}(c.r, c.g, c.b, 0.01))),
layer(x=x_het_ass, y=y_het_ass, ymin=ymin_het_ass, ymax=ymax_het_ass, Geom.line, Geom.ribbon,Gadfly.Theme(default_color=colorant"red", lowlight_color = c->RGBA{Float32}(c.r, c.g, c.b, 0.01))))
# 


|labels_random = []
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
    linewidth=3,
    guidefontsize=12,
    tickfontsize=12,
    legendfontsize=12,
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
    linewidth=3,
    guidefontsize=12,
    tickfontsize=12,
    legendfontsize=12,
    legendposition=:bottomright
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
    linewidth=3,
    guidefontsize=12,
    tickfontsize=12,
    legendfontsize=12,
    legendposition=:bottomright
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


Plots.scatter(network_to_scenario_to_seed_to_data["random"]["heterogenous"]["degree"], network_to_scenario_to_seed_to_data["random"]["heterogenous"]["max_infections"])



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







#
# seeds = 500
# iterations = 90
# base_susceptibility = 0.1
# n_nodes = 100
# # p_edge = 0.0097
# n_infected_agents = 1


# model, net = initialize(;
#     seed=9871,
#     n_nodes=n_nodes,
#     # p_edge=p_edge,
#     # n_infected_agents=n_infected_agents,
#     base_susceptibility=base_susceptibility,
#     hom_het="heterogenous_assortative",
#     network_structure="random"
# )

# mean(Graphs.degree(net))

# histogram(Graphs.degree(net), bins = 20, xlabel = "Value", ylabel = "Frequency", title = "Histogram")


# figs, abmobs = abmexploration(model; agent_step!, ac=person_color, am=person_shape, as=25)
# figs

# cnt1 = 0
# cnt0 = 0
# cnt2 = 0
# for agent in allagents(model)
#     if agent.group == 1
#         cnt1 += 1
#     elseif agent.group == 2
#         cnt2 += 1
#     else
#         cnt0 += 1
#     end
# end

