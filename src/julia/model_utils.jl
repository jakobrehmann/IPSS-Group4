# collect details of model state in each iteration
function count_agents_per_disease_state(model)
    # each vector contains susc/exposed/... cnt for [normal, fearful, crazy]
    cnt_susc = [0,0,0]
    cnt_exposed = [0,0,0]
    cnt_infectious = [0,0,0]
    cnt_recovered = [0,0,0]
    for agent in allagents(model)
        if agent.health_status == 0
            cnt_susc[agent.group + 1] += 1
        elseif agent.health_status == 1
            cnt_exposed[agent.group + 1] += 1
        elseif agent.health_status == 2
            cnt_infectious[agent.group + 1] += 1
        elseif agent.health_status == 3
            cnt_recovered[agent.group + 1] += 1
        end
    end
    
    # println("susc group 01: $(cnt_susc_01),susc group 2: $(cnt_susc_2), exposed: $(cnt_exposed), infectious: $(cnt_infectious), recovered:$(cnt_recovered)", )
    return cnt_susc, cnt_exposed,cnt_infectious,cnt_recovered
end

function runModel(model, iterations)
    for i in 1:iterations
        step!(model, agent_step!)
    end
end

function runModelWithPlot(model, iterations)
    cum_susc = []
    cum_susc_1 = []
    cum_susc_2 = []
    cum_exposed = []
    cum_infectious = []
    cum_infectious_1 = []
    cum_infectious_2 = [] 
    cum_recovered = []

    for i in 1:iterations
        cnt_susc,cnt_exposed,cnt_infectious,cnt_recovered = count_agents_per_disease_state(model)
        push!(cum_susc,sum(cnt_susc))
        push!(cum_susc_1,cnt_susc[2])
        push!(cum_susc_2,cnt_susc[3])
        push!(cum_exposed,sum(cnt_exposed))
        push!(cum_infectious,sum(cnt_infectious))
        push!(cum_infectious_1,cnt_infectious[2])
        push!(cum_infectious_2,cnt_infectious[3])
        push!(cum_recovered,sum(cnt_recovered))
        step!(model, agent_step!)
    end


    plot_labels = ["S" "E" "I" "R"]
    plot_lines = [cum_susc_1 cum_exposed cum_infectious cum_recovered]
    plot_linecolor = [:blue :orange :red :black]

    if sum(cum_susc_2) > 0
        plot_labels = ["S_fearful" "S_crazy" "E" "I" "R"]
        plot_lines = [cum_susc_1 cum_susc_2 cum_exposed cum_infectious cum_recovered]
        plot_linecolor = [:blue :lightblue :orange :red :black]
    end

    plot = Plots.plot(1:iterations,
        plot_lines/n_nodes * 100,
        labels = plot_labels, 
        linewidth=3,
        linecolor = plot_linecolor,
        xlabel = "time [t]", 
        ylabel = "proportion of population [%]",
        guidefontsize = 17,
        tickfontsize = 17,
        legendfontsize = 17,
        legend=:outertopright)

    return plot, cum_susc, cum_susc_1, cum_susc_2, cum_exposed, cum_infectious, cum_infectious_1, cum_infectious_2, cum_recovered
end