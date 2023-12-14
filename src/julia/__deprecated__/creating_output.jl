

#Creates one CSV per scenario per network, and per risk (risky vs careful vs all) group
#Each CSV: Rows are iterations, columns are seeds
function generate_output_csv()
    for network_structure in network_structures
        for scenario in scenarios

            df = DataFrame()

            i = 1
            for vec in network_to_scenario_to_seed_to_data[network_structure][scenario]["infectious_per_seed"]
                tit = "seed$(i)"
                df[!,tit] = vec
                i+=1
            end

            CSV.write("$(network_structure)-$(scenario).csv", df)

            # group 1
            df_1 = DataFrame()
            i = 1
            for vec in network_to_scenario_to_seed_to_data[network_structure][scenario]["infectious_per_seed_1"]
                tit = "seed$(i)"
                df[!,tit] = vec
                i+=1
            end

            CSV.write("$(network_structure)-$(scenario)-group1.csv", df)

            # group 2
            df_2 = DataFrame()

            i = 1
            for vec in network_to_scenario_to_seed_to_data[network_structure][scenario]["infectious_per_seed_2"]
                tit = "seed$(i)"
                df[!,tit] = vec
                i+=1
            end

            CSV.write("$(network_structure)-$(scenario)-group2.csv", df)
        end
    end
end

#This function creates 3 line plots, one for each network.
#Each of the line plots contains 3 lines (# of infected agents over time), one for each scenario.
function generate_output_figures()
    ######
    file_name = "v1"

    for network in network_structures

        labels_random = []
        lines_random = []

        for scenario in scenarios
            push!(labels_random, "I ($(network)-$(scenario))")
            push!(lines_random, network_to_scenario_to_seed_to_data[network][scenario]["infections_avg"])
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

        savefig("$(network)-$(file_name).png")

    end
end