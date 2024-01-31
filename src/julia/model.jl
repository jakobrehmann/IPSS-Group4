# Questions:
# 1) are the same # of agents activated in each iteration?
# 2) how exactly does randomness work...? Should include the rng into the network generation?
# 3) Is the Xoshiro rng the correct random number generator?
# 4) is it ok that seeds are just 1->100
# 5) Are all nodes full?

# first change infectious --> presymptomatic (I -> P)
# then change showingSymptoms -> Infectious 


# Import neccessary packages
using Pkg
Pkg.add("Agents")
Pkg.add("Random")
Pkg.add("Graphs")
Pkg.add("DataFrames")
Pkg.add("Statistics")
Pkg.add("CSV")
Pkg.add("Dates")


# Pkg.activate("src/julia/")
using Agents, Random, Graphs, DataFrames, Statistics, CSV, Dates

# Define Agent
@agent Person_Sim GraphAgent begin
    #id::Int
    #pos:Int
    health_status::Int # 0: Susceptible; 1: Exposed; 2: Presympotmatic; 3: Infectious; 9: Recovered
    days_presymptomatic::Int # counts days in presymptomatic state, starting with 1. If agent has other disease state: -1 
    inf_chance_for_iteration::Float64 # if susceptible person had contact with infectious person, then this variable saves the infection chance (including the reduction_factor). In all other cases: missing
end

function run_model(params)
    @time begin

        # sets output directory. If running on cluster, output folder is specified by start_multiple_sh. If run locally, a new folder will be created w/ current datetime 
        if ismissing(params[:output_folder])
            output_path = "data/" * replace(first(string(now()), 19), ":" => "")
            mkdir(output_path)

        else
            output_path = params[:output_folder]
        end

        # writes _info.csv with all relevant input parameters
        # TODO: when running on cluster, _info.csv gets overwritten by each seperate job.
        CSV.write(output_path * "/_info.csv", params)

        # for each network structure
        for network_structure in params[:network_structures]
            # for each base susceptiblity
            for base_susceptibility in params[:base_susceptibilities]
                # for each local_global_scenario 
                for local_global_scenario in params[:local_global_scenarios]
                    
                    # empty dictionary, which will be filled with respective stat (e.g. susceptible count) for each model run (all iterations, rows of matrix) for each seed (columns of matrix)
                    results = Dict(
                        # "shortestPath" => [],
                        # "clusteringCoefficient" => [],
                        "susceptible" => [],
                        "exposed" => [],
                        "infectious" => [],
                        "recovered" => [],
                        "infectionChance" => []
                    )

        

                    println("#######################")
                    println("Network: $(network_structure) --  Susceptibility: $(base_susceptibility)  -- Local/Global Scenario: $(local_global_scenario)")
                    println("#######################")

                    # loop through all seeds
                    for seed in 1:params[:seeds]

                        # Create network 
                        net = initializeNetwork(
                            params[:n_nodes],
                            network_structure,
                            params[:mean_degree]
                        )

                        # local_path_length_per_node = []
                        # local_clustering_coeff_per_node = []
                        # for i in 1:params[:n_nodes]
                        #     push!(local_path_length_per_node, mean(Graphs.dijkstra_shortest_paths(net,i).dists))
                        #     push!(local_clustering_coeff_per_node, Graphs.local_clustering_coefficient(net,i))

                        # end

                        # global_mean_path_length = [mean(local_path_length_per_node)]
                        # global_mean_clustering_coefficient = [mean(local_clustering_coeff_per_node)]

                        # println(string("seed: ", seed))
                        # println(string("global mean path length: ", global_mean_path_length))
                        # println(string("global mean clustering coefficient: ", global_mean_clustering_coefficient))
                        # println(string("is completely connected : ", length(connected_components(net))))


                        # push!(results["shortestPath"],global_mean_path_length)
                        # push!(results["clusteringCoefficient"],global_mean_clustering_coefficient)



                        # Create model
                        model = initialize(
                            net,
                            base_susceptibility,
                            params[:recovery_rate],
                            params[:n_nodes],
                            seed,
                            local_global_scenario,
                            params[:mean_degree],
                            params[:days_until_showing_symptoms]
                        )

                        # Step through all iterations. In each iteration:
                        #   1) agent_step function is applied to each agent
                        #   2) model_step function occurs at end of iteration
                        step!(model, agent_step!, model_step!, params[:iterations])

                        # model stats for particular seed are added as column to each results matrix. 
                        push!(results["susceptible"], model.hist_susceptible)
                        push!(results["exposed"], model.hist_exposed)
                        push!(results["infectious"], model.hist_presymptomatic + model.hist_infectious)
                        push!(results["recovered"], model.hist_recovered)
                        push!(results["infectionChance"], model.hist_infection_chance)
                    end


                    # prints each stat matrix in results dictionary to csv. 
                    for (result_type, result_matrix_all_seeds) in results
                        df = DataFrame()
                        seed_counter = 1
                        for results_for_single_seed in result_matrix_all_seeds
                            vector_title = "seed$(seed_counter)"
                            # if(typeof(results_for_single_seed)==Float64)
                            #     df[!,vector_title] = [results_for_single_seed]
                            # else
                            df[!, vector_title] = results_for_single_seed
                            # end
                            seed_counter += 1
                        end

                        output_file_name = "/$(network_structure)-$(base_susceptibility)-$(local_global_scenario)-$(result_type)-$(params[:days_until_showing_symptoms]).csv"
                        CSV.write(output_path * output_file_name, df)
                    end
                end
            end
        end
    end
end

# creates network with default values
function initializeNetwork(n_nodes, network_structure, mean_degree)
    if network_structure == "regular"
        net = Graphs.random_regular_graph(n_nodes, mean_degree)
    elseif network_structure == "random"
        net = erdos_renyi(n_nodes, mean_degree / n_nodes)
    elseif network_structure == "smallworld"
        net = newman_watts_strogatz(n_nodes, mean_degree, 0.01)
    elseif network_structure == "smallworldreg"
        net = newman_watts_strogatz(n_nodes, mean_degree, 0.0) #expected degree k(1 + β) (k = second param, β = third param)
    elseif network_structure == "preferential"
        net = barabasi_albert(n_nodes, 5) #TODO: how to make k depend on mean_degree
    else
        throw(DomainError)
    end
    return net
end

# creates ABM
function initialize(net,
    base_susceptibility, # chance of infection between 0.0 (no chance) and 1.0 (100% chance), given virus contact
    recovery_rate, # for infected agents (presympotmatic & infectious), chance that they will recover, between 0.0 and 1.0
    n_nodes, # number of nodes in network
    seed, # random seed
    local_global_scenario, # scenario for determining factor for reducing infection chance
    mean_degree, # mean degree for network 
    days_until_showing_symptoms # number of days agent is presymptomatic. If 0, agent will go straight from exposed to infectious, skipping presymptomatic stage
)

    # create a space
    space = GraphSpace(net)

    # define model properties
    properties = Dict(
        :base_susceptibility => base_susceptibility,
        :recovery_rate => recovery_rate,
        :local_global_scenario => local_global_scenario,
        :mean_degree => mean_degree,
        :days_until_showing_symptoms => days_until_showing_symptoms,
        :n_nodes => n_nodes,

        # proportion of agents who are infectious (detectable). This is used to calculate reduction factor for "global" scenario. 
        :prop_agents_infectious => 0.,

        # used to calculate the average infection chance per iteration --> used for model count: *infectionChance.csv
        :cnt_potential_infections_for_it => 0.0,
        :sum_infection_prob_for_it => 0.0,
        :hist_infection_chance => [],

        # current count for each disease state
        :cnt_susceptible => 0,
        :cnt_exposed => 0,
        :cnt_presymptomatic => 0,
        :cnt_infectious => 0,
        :cnt_recovered => 0,

        #history of count for each iteration
        :hist_susceptible => [],
        :hist_exposed => [],
        :hist_presymptomatic => [],
        :hist_infectious => [],
        :hist_recovered => []
    )

    # create random number generator
    rng = Random.Xoshiro(seed)

    # scheduler for order in which agents are activated for agent-step function: Recovered -> Infectious -> Presymptomatic -> Exposed -> Susceptible
    scheduler = Schedulers.ByProperty(RIES_scheduler)

    # Model; unremovable = agents never leave the model
    model = UnremovableABM(
        Person_Sim, space;
        properties, rng, scheduler=scheduler
    )

    # add agents to model
    for id in 1:n_nodes
        p = Person_Sim(id, 1, 0, -1, NaN64)
        add_agent_single!(p, model)
    end

    # Infect a single random agent
    sick_person = random_agent(model) # TODO: does this use the seed?
    sick_person.health_status = 2
    sick_person.days_presymptomatic = 1 # TODO: is this right?

    # set initial values for cnt_DISEASE_STATE
    for agent in allagents(model)
        if agent.health_status == 0
            model.cnt_susceptible += 1
        elseif agent.health_status == 1
            model.cnt_exposed += 1
        elseif agent.health_status == 2
            model.cnt_presymptomatic += 1
        elseif agent.health_status == 3
            model.cnt_infectious += 1
        elseif agent.health_status == 9
            model.cnt_recovered += 1
        else
            throw(DomainError)
        end
    end

    # push cnts to first entry in history of each disease states
    push_state_count_to_history!(model)

    return model
end

# model state occurs at end of each iteration, after agent_step is applied to all agents
function model_step!(model)

    # push disease state counts for current (ending) iteration to respective history. 
    push_state_count_to_history!(model)

    # reset potential infection counter and infection probability summation to 0.0, so it can be used in following iteration
    model.cnt_potential_infections_for_it = 0.0
    model.sum_infection_prob_for_it = 0.0

    # count number of agents who are currently infectious (detectable), to be used in "global" stategy for calculating infection chance in following iteration
    model.prop_agents_infectious = model.cnt_infectious / model.n_nodes

end

# updates disease state histories with disease state counts for current iteration
function push_state_count_to_history!(model)
    push!(model.hist_susceptible, model.cnt_susceptible)
    push!(model.hist_exposed, model.cnt_exposed)
    push!(model.hist_presymptomatic, model.cnt_presymptomatic)
    push!(model.hist_infectious, model.cnt_infectious)
    push!(model.hist_recovered, model.cnt_recovered)
    push!(model.hist_infection_chance, model.sum_infection_prob_for_it / model.cnt_potential_infections_for_it)
end


# Agent Step Function: this transitions agents from one disease state to another
function agent_step!(person, model)
    
    # if showing symptoms 
    if person.health_status == 3
        if rand(model.rng) <= model.recovery_rate #Agents recover with a probability of recovery_rate
            person.health_status = 9
            model.cnt_infectious -= 1
            model.cnt_recovered += 1
        end
    end

    # if presympotmatic
    if person.health_status == 2
        # P -> R
        if rand(model.rng) <= model.recovery_rate #Agents recover with a probability of recovery_rate
            person.health_status = 9
            person.days_presymptomatic = -1
            model.cnt_presymptomatic -= 1
            model.cnt_recovered += 1
            # P -> I
        elseif person.days_presymptomatic == model.days_until_showing_symptoms
            person.health_status = 3
            person.days_presymptomatic = -1
            model.cnt_presymptomatic -= 1
            model.cnt_infectious += 1
        else
            person.days_presymptomatic += 1
        end
    end

    # if exposed
    if person.health_status == 1 
        # E -> P
        if model.days_until_showing_symptoms > 0
            person.health_status = 2 # change to presympotmatic
            person.days_presymptomatic = 1
            model.cnt_exposed -= 1
            model.cnt_presymptomatic += 1
        # E -> I (if lag is 0.0, then we skip the presympotmatic phase)
        elseif model.days_until_showing_symptoms == 0
            person.health_status = 3 # change to infectious
            model.cnt_exposed -= 1
            model.cnt_infectious += 1
        else
            throw(DomainError)
        end
        
    end

    # if susceptible
    if person.health_status == 0
        # loop through all neighbors:
        # cnt_inf_neighbors = all infectious neigbors = PRESYMPTOMATIC + INFECTIOUS. --> Used for calculating chance of infeciton.
        # cnt_symptomatic_neighbors = INFECTIOUS (only detectable neighbors) --> used reduction_factor in local scenarios. 
        # TODO: can we change infectious name to detectable?!?! Because presymptomatic agents are also infectious!!!
        cnt_inf_neighbors, cnt_symptomatic_neighbors, cnt_tot_neighbors = countNeighborsN(person, model)

        # only calculate chance of infection, if you have infectious (PRESYMPTOMATIC + INFECTIOUS)
        if (cnt_inf_neighbors > 0)

            # calculate infection chance
            inf_chance = calc_infection_chance(model, person, cnt_inf_neighbors, cnt_symptomatic_neighbors, cnt_tot_neighbors)

            # roll dice to see if susceptible agent gets infected
            if rand(model.rng) < inf_chance
                person.health_status = 1 # change to exposed
                model.cnt_exposed += 1
                model.cnt_susceptible -= 1
            end

            # add every potential infection (whether or not the person actually got infected) to stats
            model.cnt_potential_infections_for_it += 1.0
            model.sum_infection_prob_for_it += inf_chance
        end

    end
end


# calculate infection chance 
function calc_infection_chance(model, person, cnt_inf_neighbors, cnt_symptomatic_neighbors, cnt_tot_neighbors)
    
    # needed for global strategy. 
    if ismissing(model.prop_agents_infectious)
        throw(DomainError)
    end


    # calculate reduction factor
    # if base, no reduction. 
    if model.local_global_scenario == "base"

        red_factor = 1

    # if global, the overall INFECTIOUS rate for entire network is used to calculate reduction factor
    # to be comparable to local1, we normalize between (1, mean_degree)
    elseif model.local_global_scenario == "global"

        red_factor = exp(-model.prop_agents_infectious * model.mean_degree)

    # for local1, red_factor is calculated based on number of INFECTIOUS neigbors
    elseif model.local_global_scenario == "local1"

        red_factor = exp(-cnt_symptomatic_neighbors)

    # for local2, red_factor is calculated based on number of INFECTIOUS neigbors's neihbors (no direct neighbors included)
    # to be comparable to local1, we normalize between (1, mean_degree)
    elseif model.local_global_scenario == "local2"
        _, cnt_symptomatic_neighbors1_and_2, cnt_tot_neighbors1_and_2 = countNeighborsN(person, model; radius=2)
        cnt_symptomatic_neighbors2 = cnt_symptomatic_neighbors1_and_2 - cnt_symptomatic_neighbors
        cnt_tot_neighbors2 = cnt_tot_neighbors1_and_2 - cnt_tot_neighbors
        red_factor = exp(-cnt_symptomatic_neighbors2 / cnt_tot_neighbors2 * model.mean_degree)
    # for local1_and_2, red_factor is calculated based on number of INFECTIOUS neighbors and neigbors's neihbors
    # to be comparable to local1, we normalize between (1, mean_degree)
    elseif model.local_global_scenario == "local1_and_2"
        _, cnt_symptomatic_neighbors1_and_2, cnt_tot_neighbors1_and_2 = countNeighborsN(person, model; radius=2)
        red_factor = exp(-cnt_symptomatic_neighbors1_and_2 / cnt_tot_neighbors1_and_2 * model.mean_degree)
    elseif model.local_global_scenario == "global_local1"

        red_factor = exp(-model.prop_agents_infectious * model.mean_degree - cnt_symptomatic_neighbors)

    elseif model.local_global_scenario == "global_local1_and_2"
        _, cnt_symptomatic_neighbors1_and_2, cnt_tot_neighbors1_and_2 = countNeighborsN(person, model; radius=2)
        red_factor = exp(-model.prop_agents_infectious * model.mean_degree -cnt_symptomatic_neighbors1_and_2 / cnt_tot_neighbors1_and_2 * model.mean_degree)
    else
        throw(DomainError)
    end

    # infection chance depends on the base_susceptibility and the reduction factor, as well as the number of infectious neighbors (PRESYMPTOMATIC and INFECTIOUS)
    inf_chance = 1 - (1 - model.base_susceptibility * red_factor)^cnt_inf_neighbors

    return inf_chance
end

# count
function countNeighborsN(person, model; radius=1)
    cnt_inf_neighbors = 0
    cnt_symptomatic_neighbors = 0
    cnt_tot_neighbors = 0

    for neighbor in nearby_agents(person, model, radius)
        cnt_tot_neighbors += 1
        # if neighbor is infected, but not showing symptoms, add to count of infected neigbors
        if neighbor.health_status == 2
            cnt_inf_neighbors += 1
            # if neigbor is infected and symptomic, add to both counts!
        elseif neighbor.health_status == 3
            cnt_inf_neighbors += 1
            cnt_symptomatic_neighbors += 1
        end
    end

    return cnt_inf_neighbors, cnt_symptomatic_neighbors, cnt_tot_neighbors
end

# activates agents in following order: Recovered -> Infectious -> Presymptomatic -> Exposed -> Susceptible 
function RIES_scheduler(agent)
    return -agent.health_status
end