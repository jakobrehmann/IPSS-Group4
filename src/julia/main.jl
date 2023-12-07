include("model.jl")
include("model_utils.jl")
include("viz.jl")
include("creating_output.jl")

using Dates

# 1) write out avg infection prob
# 2) try to make global calculation more efficient --> needed for more nodes --> barabasi_albert


# base -> red = 1
# global_only = local is off; global between 0.0 and 1.0 (11x)
# global is off; local between 0.0 and 1.0 (11x)
# 


# PARAMS PER RUN
begin
    params = Dict(
        :seeds => 100,
        :iterations => 100,
        :base_susceptibilities => [0.1:0.1:0.9;],
        :n_nodes => 1000, # 1000
        :n_infected_agents => 1,
        # :scenarios => ["homogenous"],
        :network_structures => ["regular", "smallworld"], #"random","preferential"], # ["regular","smallworld"], #
        :local_global_weights => vcat(["base"],[0.0:0.1:1.0;]), # potentially 0.025 / 0.01
        :local_global_scenarios => ["local", "global"]
    )
end


@time begin
    output_path = "data/" * replace(first(string(now()), 19), ":" => "")
    mkdir(output_path)

    CSV.write(output_path * "/_info.csv", params)

    # for each network structure
    for network_structure in params[:network_structures]
        # initialize network, so that it is the same for each scenario. 
        net = initializeNetwork(; n_nodes=params[:n_nodes], network_structure=network_structure)

        # for each local_global_scenario 
        for base_susceptibility in params[:base_susceptibilities]
            for local_global_scenario in params[:local_global_scenarios]
                for local_global_weight in params[:local_global_weights]
                    results = Dict(
                        "susceptible" => [],
                        "exposed" => [],
                        "infectious" => [],
                        "recovered" => [],
                        "infectionChance" => []
                    )

                
                    if local_global_scenario == "local"
                        local_weight = local_global_weight
                        global_weight = 0.0
                    elseif local_global_scenario == "global"
                        local_weight = 0.0
                        global_weight = local_global_weight
                    else
                        throw(DomainError)
                    end

                    # create model
                    model = initialize(net;
                        seed=3,
                        n_nodes=params[:n_nodes],
                        base_susceptibility=base_susceptibility,
                        hom_het="homogenous",
                        local_weight = local_weight,
                        global_weight= global_weight,
                    )

                    println("#######################")
                    println("Network: $(network_structure) --  Susceptibility: $(base_susceptibility)  -- Local/Global Weight: $(local_global_scenario)$(local_global_weight)")
                    println("Mean Degree $(mean(Graphs.degree(net)))")
                    println("#######################")

                    for seed in 1:params[:seeds]

                        for agent in allagents(model)
                            agent.health_status = 0
                        end


                        # Infects a different agent for every seed
                        i = 0
                        while i < params[:n_infected_agents]
                            sick_person = random_agent(model) # does this use the seed?
                            if sick_person.health_status == 0
                                sick_person.health_status = 2
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

                        cnt_susc, cnt_exposed, cnt_infectious, cnt_recovered = count_agents_per_disease_state(model)
                        push!(cum_susc, sum(cnt_susc))
                        push!(cum_exposed, sum(cnt_exposed))
                        push!(cum_infectious, sum(cnt_infectious))
                        push!(cum_recovered, sum(cnt_recovered))
                        push!(cum_infection_chance, NaN64)


                        for _ in 1:params[:iterations]
                            # pre-step initialization
                            model.prop_agents_infected = sum(cnt_infectious) / params[:n_nodes]
                            model.cnt_potential_infections_for_it = 0.0
                            model.sum_infection_prob_for_it = 0.0
                            #iteration
                            step!(model, agent_step!)
                            # post-step processing
                            cnt_susc, cnt_exposed, cnt_infectious, cnt_recovered = count_agents_per_disease_state(model)
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

                        output_file_name = "/$(network_structure)-$(base_susceptibility)-$(local_global_scenario)_$(local_global_weight)-$(k).csv"
                        CSV.write(output_path * output_file_name, df)
                    end
                end
            end
        end
    end
end