include("model.jl")
include("model_utils.jl")
include("viz.jl")
include("creating_output.jl")

# PARAMS PER RUN
seeds = 10
iterations = 200
base_susceptibility = 0.1
n_nodes = 1000
n_infected_agents = 1

# GLOBAL PARAMS
scenarios = ["homogenous", "heterogenous", "heterogenous_assortative"]
network_structures = ["random","smallworld", "preferential"]

@time begin
    # instantiate structure to save data
    network_to_scenario_to_seed_to_data = Dict()
    # for each network structure
    for network_structure in network_structures
        network_to_scenario_to_seed_to_data[network_structure] = Dict()

        # initialize network, so that it is the same for each scenario. 
        net = initializeNetwork(; n_nodes = n_nodes, network_structure = network_structure)

        # for each scenario 
        for scenario in scenarios
            network_to_scenario_to_seed_to_data[network_structure][scenario] = Dict("degree" => [], "group" => [], "max_infections" => [], "max_infections_time" => [], "cum_infections" => [])
            infectious_avg = zeros(iterations)
        
            infectious_per_seed = []
            infectious_per_seed_1 = []
            infectious_per_seed_2 = []

            min_infections_per_timestep = 10000 * ones(iterations)
        
            max_infections_per_timestep = zeros(iterations)
        

            # create model
            model = initialize(net;
                seed=3,
                n_nodes=n_nodes,
                base_susceptibility=base_susceptibility,
                hom_het=scenario
            )

            println("#######################")
            println("Network: $(network_structure) --  Scenario: $(scenario)")
            println("Mean Degree $(mean(Graphs.degree(net)))")
            println("#######################")
# 

            for seed in 1:seeds

                # Randomly choose patient zero and save their group
                infected_agents_group = []
                infected_agents_degree = []

                for agent in allagents(model)
                    agent.health_status = 0
                end


                # Infects a different agent for every seed
                i = 0
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
            

                #Computation of average of infections over seeds
                infectious_avg += infectious / seeds
                #For an approximation of the standard deviation, the min/max across seeds are computed
                min_infections_per_timestep = min.(min_infections_per_timestep, infectious) 
                max_infections_per_timestep = max.(max_infections_per_timestep, infectious)

                #Save attributes for initially infected agent
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["degree"], infected_agents_degree[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["group"], infected_agents_group[1])
                #Save peak and timing of peak of infection curve
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["max_infections"], findmax(infectious)[1])
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["max_infections_time"], findmax(infectious)[2])
                #Save cumultative number of infections
                push!(network_to_scenario_to_seed_to_data[network_structure][scenario]["cum_infections"], sum(infectious))
                #Save no. of infectious people per iteration for every individual seed
                push!(infectious_per_seed, infectious)
                push!(infectious_per_seed_1, infectious_1)
                push!(infectious_per_seed_2, infectious_2)
            end
            
            #Add average of infections over seeds to nested dictionary
            network_to_scenario_to_seed_to_data[network_structure][scenario]["infections_avg"] = infectious_avg
            #Compute + add standard deviation of infections over seeds to nested dictionary
            network_to_scenario_to_seed_to_data[network_structure][scenario]["sd"] = (max_infections_per_timestep - min_infections_per_timestep) / 4
            #Add no. of infectious people per iteration to nested dictionary
            network_to_scenario_to_seed_to_data[network_structure][scenario]["infectious_per_seed"] = infectious_per_seed
            network_to_scenario_to_seed_to_data[network_structure][scenario]["infectious_per_seed_1"] = infectious_per_seed_1
            network_to_scenario_to_seed_to_data[network_structure][scenario]["infectious_per_seed_2"] = infectious_per_seed_2
        end
    end
end






