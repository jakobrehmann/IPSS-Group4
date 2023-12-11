include("model.jl")
include("model_utils.jl")
include("viz.jl")
include("creating_output.jl")

# TODOS:
# look at order of phase transitions
# think about running on cluster

# Sensitivity Analysis
# network structs
# recovery rates



# PARAMS PER RUN
# begin
#     params = Dict(
#         :seeds => 100,
#         :iterations => 200,
#         :base_susceptibilities => [0.1:0.1:0.3;],
#         :n_nodes => 1000,
#         :n_infected_agents => 1,
#         :network_structures => ["regular", "smallworld", "random", "preferential"],
#         :local_global_scenarios => ["base", "local1", "local2", "local1_and_2", "global"],
#         :mean_degree => 10,
#         :days_until_showing_symptoms => 0
#     )
# end

begin
    params = Dict(
        :seeds => 100,
        :iterations => 200,
        :base_susceptibilities => [0.1,0.2,0.3],
        :n_nodes => 1000,
        :n_infected_agents => 1,
        :network_structures => ["smallworld"],
        :local_global_scenarios => ["global","base","local1","local2","local1_and_2"],
        :mean_degree => 10,
        :days_until_showing_symptoms => 0
    )
end


@time begin
    output_path = "data/" * replace(first(string(now()), 19), ":" => "")
    mkdir(output_path)

    CSV.write(output_path * "/_info.csv", params)

    # for each network structure
    for network_structure in params[:network_structures]
        # initialize network, so that it is the same for each scenario. 
        # net = initializeNetwork(; n_nodes=params[:n_nodes], network_structure=network_structure, mean_degree = params[:mean_degree])

        # for each local_global_scenario 
        for base_susceptibility in params[:base_susceptibilities]
            for local_global_scenario in params[:local_global_scenarios]
                results = Dict(
                    "susceptible" => [],
                    "exposed" => [],
                    "infectious" => [],
                    "recovered" => [],
                    "infectionChance" => []
                )

                # create model

                println()
                println("#######################")
                println("Network: $(network_structure) --  Susceptibility: $(base_susceptibility)  -- Local/Global Scenario: $(local_global_scenario)")

                println("#######################")
                print("Mean Degree :")

                for seed in 1:params[:seeds]

                    net = initializeNetwork(; n_nodes=params[:n_nodes], network_structure=network_structure, mean_degree=params[:mean_degree])
                    # print("$(mean(Graphs.degree(net))); ")
                    

                    model = initialize(net;
                        seed=seed,
                        n_nodes=params[:n_nodes],
                        base_susceptibility=base_susceptibility,
                        local_global_scenario=local_global_scenario,
                        mean_degree=params[:mean_degree],
                        days_until_showing_symptoms=params[:days_until_showing_symptoms]
                    )


                    for agent in allagents(model)
                        agent.health_status = 0
                        agent.days_infected = -1
                    end


                    # Infects a different agent for every seed
                    i = 0
                    while i < params[:n_infected_agents]
                        sick_person = random_agent(model) # does this use the seed?
                        if sick_person.health_status == 0
                            sick_person.health_status = 2
                            sick_person.days_infected = 0
                            i += 1
                        end
                    end

                    # MEAT OF THE SOFTWARE
                    # susc, exposed, infectious, recovered = runModelWithPlot(model, params[:iterations])

                    cum_susc = []
                    cum_exposed = []
                    cum_infectious = []
                    cum_recovered = []
                    cum_infection_chance = []

                    cnt_susc, cnt_exposed, cnt_infectious, cnt_infectious_showingSymptoms, cnt_recovered = count_agents_per_disease_state(model)
                    push!(cum_susc, sum(cnt_susc))
                    push!(cum_exposed, sum(cnt_exposed))
                    push!(cum_infectious, sum(cnt_infectious))
                    push!(cum_recovered, sum(cnt_recovered))
                    push!(cum_infection_chance, NaN64)


                    for _ in 1:params[:iterations]
                        # pre-step initialization
                        model.prop_agents_infected = sum(cnt_infectious_showingSymptoms) / params[:n_nodes]
                        model.cnt_potential_infections_for_it = 0.0
                        model.sum_infection_prob_for_it = 0.0
                        #iteration
                        step!(model, agent_step!)
                        # e -> i
                        # s -> e
                        # i -> showingSymtoms / recovered

                        # post-step processing
                        cnt_susc, cnt_exposed, cnt_infectious, cnt_infectious_showingSymptoms, cnt_recovered = count_agents_per_disease_state(model)
                        push!(cum_susc, sum(cnt_susc))
                        push!(cum_exposed, sum(cnt_exposed))
                        push!(cum_infectious, sum(cnt_infectious))
                        push!(cum_recovered, sum(cnt_recovered))
                        push!(cum_infection_chance, model.sum_infection_prob_for_it / model.cnt_potential_infections_for_it)
                    end

                    push!(results["susceptible"], cum_susc)
                    push!(results["exposed"], cum_exposed)
                    push!(results["infectious"], cum_infectious)
                    push!(results["recovered"], cum_recovered)
                    push!(results["infectionChance"], cum_infection_chance)
                end


                ### PRINT RESULTS
                for (k, v) in results
                    df = DataFrame()
                    i = 1
                    for vec in v
                        tit = "seed$(i)"
                        df[!, tit] = vec
                        i += 1
                    end

                    output_file_name = "/$(network_structure)-$(base_susceptibility)-$(local_global_scenario)-$(k).csv"
                    CSV.write(output_path * output_file_name, df)
                end
            end
        end
    end
end