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
        return cnt_susc, cnt_exposed,cnt_infectious,cnt_recovered
end

function runModel(model, iterations)
    for _ in 1:iterations
        step!(model, agent_step!)
    end
end

function runModelWithPlot(model, iterations)
    cum_susc = []
    cum_exposed = []
    cum_infectious = []
    cum_recovered = []

    for _ in 1:iterations
        cnt_susc,cnt_exposed,cnt_infectious,cnt_recovered = count_agents_per_disease_state(model)
        push!(cum_susc,sum(cnt_susc))
        push!(cum_exposed,sum(cnt_exposed))
        push!(cum_infectious,sum(cnt_infectious))
        push!(cum_recovered,sum(cnt_recovered))
        step!(model, agent_step!)
    end

    return cum_susc, cum_exposed, cum_infectious, cum_recovered
end