# Import neccessary packages
using Pkg
Pkg.activate("src/julia/")
using Agents, Random, Graphs, Plots, Makie, CairoMakie, GraphMakie, GraphIO, Colors, GLMakie, DataFrames, Statistics, CSV, Dates
# pkg> add https://github.com/asgolovin/Agents.jl

# Define Agent
@agent Person_Sim GraphAgent begin
    susceptibility::Float64 # between 0 (no chance of infection) and 1 (100% chance)
    health_status::Int# 0: Susceptible; 1: Exposed; 2: Infected; 3: Recovered
    days_infected::Int# 0 on day of infection; missing when not infected.
    group::Int # 0:avg; 1: low-contact (fearful); 2: high-contact (crazy)
    group_reduction_factor::Float64 #Factor describing by how much contacts are reduced
    inf_chance_for_iteration::Float64
end

type_susceptible(p::Person_Sim) = p.health_status == 0
type_exposed(p::Person_Sim) = p.health_status == 1
type_infectious(p::Person_Sim) = p.health_status == 2
type_recovered(p::Person_Sim) = p.health_status == 3

# creates network with default values
function initializeNetwork(;
    n_nodes=1000,
    network_structure="random", #Options: "random", "smallworld",
    mean_degree=10
)

    if network_structure == "grid"
        dim = sqrt(n_nodes)
        if (isinteger(dim))
            net = Graphs.grid([trunc(Int, dim), trunc(Int, dim)])
        else
            throw(DomainError)
        end
    elseif network_structure == "regular"
        net = Graphs.random_regular_graph(n_nodes, mean_degree)
    elseif network_structure == "random"
        net = erdos_renyi(n_nodes, mean_degree / n_nodes)
    elseif network_structure == "smallworld"
        net = newman_watts_strogatz(n_nodes, mean_degree, 0.01) #expected degree k(1 + β) (k = second param, β = third param)
    elseif network_structure == "preferential"
        net = barabasi_albert(n_nodes, 5) #TODO: how to make k depend on mean_degree
    else
        throw(DomainError)
    end
    return net
end


# creates ABM with default values (can be overwritten)
function initialize(net;
    base_susceptibility=0.1,
    recovery_rate=0.2,
    infection_duration=5,
    n_nodes=1000,
    seed=46872,
    local_global_scenario="base",
    mean_degree=-1,
    days_until_showing_symptoms=0
)

    # create a space
    space = GraphSpace(net)

    # define model properties
    properties = Dict(
        :base_susceptibility => base_susceptibility,
        :recovery_rate => recovery_rate,
        :infection_duration => infection_duration,
        :prop_agents_infected => missing,
        :local_global_scenario => local_global_scenario,
        :cnt_potential_infections_for_it => missing,
        :sum_infection_prob_for_it => missing,
        :mean_degree => mean_degree,
        :days_until_showing_symptoms => days_until_showing_symptoms
    )

    # create random number generator
    rng = Random.Xoshiro(seed)

    # Model; unremovable = agents never leave the model
    model = UnremovableABM(
        Person_Sim, space;
        properties, rng, scheduler=Schedulers.ByProperty(:health_status) # explain
    )

    # add agents to model - HOMOGENOUS
    for i in 1:n_nodes
        p = Person_Sim(i, 1, base_susceptibility, 0, -1, 0, 1.0, NaN64)
        add_agent_single!(p, model)
    end
    return model
end



# Agent Step Function: this transitions agents from one disease state to another
function agent_step!(person, model)

    # if infectious
    if person.health_status == 2
        if rand(model.rng) <= model.recovery_rate #Agents recover with a probability of recovery_rate
            person.health_status = 3
            person.days_infected = -1
        else
            person.days_infected += 1
        end
    end

    # if exposed
    if person.health_status == 1 # if exposed
        person.health_status = 2 # change to infectious
        person.days_infected = 0
    end

    # if susceptible
    if person.health_status == 0
        # loop through every neighbor
        cnt_inf_neighbors, cnt_symptomatic_neighbors, cnt_tot_neighbors = countNeighborsN(person, model; min_days_infected=model.days_until_showing_symptoms)

        if (cnt_inf_neighbors > 0)
            inf_chance = calc_infection_chance(model, person, cnt_inf_neighbors, cnt_symptomatic_neighbors, cnt_tot_neighbors)

            # roll dice to see if susceptible agent gets infected
            if rand(model.rng) < inf_chance
                person.health_status = 1 # change to exposed
            end

            model.cnt_potential_infections_for_it += 1.0
            model.sum_infection_prob_for_it += inf_chance
        end

    end
end


function calc_infection_chance(model, person, cnt_inf_neighbors, cnt_symptomatic_neighbors, cnt_tot_neighbors)
    if (ismissing(model.prop_agents_infected) || ismissing(model.sum_infection_prob_for_it) || ismissing(model.cnt_potential_infections_for_it))
        throw(DomainError)
    end


    if model.local_global_scenario == "base"

        red_factor = 1

    elseif model.local_global_scenario == "global"

        red_factor = exp(-model.prop_agents_infected * model.mean_degree)

    elseif model.local_global_scenario == "local1"

        red_factor = exp(-cnt_symptomatic_neighbors)

    elseif model.local_global_scenario == "local2"
        _, cnt_symptomatic_neighbors1_and_2, cnt_tot_neighbors1_and_2 = countNeighborsN(person, model; radius=2, min_days_infected=model.days_until_showing_symptoms)
        cnt_symptomatic_neighbors2 = cnt_symptomatic_neighbors1_and_2 - cnt_symptomatic_neighbors
        cnt_tot_neighbors2 = cnt_tot_neighbors1_and_2 - cnt_tot_neighbors
        red_factor = exp(-cnt_symptomatic_neighbors2 / cnt_tot_neighbors2 * model.mean_degree)
    elseif model.local_global_scenario == "local1_and_2"
        _, cnt_symptomatic_neighbors1_and_2, cnt_tot_neighbors1_and_2 = countNeighborsN(person, model; radius=2, min_days_infected=model.days_until_showing_symptoms)
        red_factor = exp(-cnt_symptomatic_neighbors1_and_2 / cnt_tot_neighbors1_and_2 * model.mean_degree)
    else 
        throw(DomainError)
    end

    # inf_chance
    inf_chance = 1 - (1 - model.base_susceptibility * red_factor)^cnt_inf_neighbors

    return inf_chance
end

function countNeighborsN(person, model; radius=1, min_days_infected=0)
    cnt_inf_neighbors = 0
    cnt_symptomatic_neighbors = 0
    cnt_tot_neighbors = 0

    for neighbor in nearby_agents(person, model, radius)
        cnt_tot_neighbors += 1
        # check if neighbor is infected
        if neighbor.health_status == 2
            cnt_inf_neighbors += 1

            if neighbor.days_infected >= min_days_infected
                cnt_symptomatic_neighbors += 1
            end

        end
    end

    return cnt_inf_neighbors, cnt_symptomatic_neighbors, cnt_tot_neighbors
end
