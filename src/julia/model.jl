# Import neccessary packages
using Pkg
Pkg.activate(".")
using Agents, Random, Graphs, Plots, Makie, CairoMakie, GraphMakie, GraphIO, Colors, GLMakie, DataFrames
# pkg> add https://github.com/asgolovin/Agents.jl

# Define Agent
@agent Person_Sim GraphAgent begin
    susceptibility::Float64 # between 0 (no chance of infection) and 1 (100% chance)
    health_status::Int# 0: Susceptible; 1: Exposed; 2: Infected; 3: Recovered
    days_infected::Int # TODO: Now that we're going for a recovery rate → Do we still need this?
    group::Int # 0:avg; 1: low-contact (fearful); 2: high-contact (crazy)
    group_reduction_factor::Float64 #Factor describing by how much contacts are reduced
end

type_susceptible(p::Person_Sim) = p.health_status == 0
type_exposed(p::Person_Sim) = p.health_status == 1
type_infectious(p::Person_Sim) = p.health_status == 2
type_recovered(p::Person_Sim) = p.health_status == 3

# creates ABM with default values (can be overwritten)
function initialize(;
    base_susceptibility=0.1,
    recovery_rate=0.2,
    infection_duration=5,
    n_nodes=100,
    # p_edge = 0.0097,
    # n_infected_agents = 10,
    seed=1234,
    hom_het="homogenous",
    assortative="fearful",
    frac_fearful=0.5,
    network_structure="random" #Options: "random", "smallworld"
)

    # Environment
    if network_structure == "random"
        net = erdos_renyi(n_nodes, 0.0097)    # input : nodes, edges # small world? watson # TODO: how to implement alternative network structure?
    elseif network_structure == "smallworld"
        net = newman_watts_strogatz(n_nodes, 10, 0.01) #expected degree k(1 + β) #TODO: This is very much work in progress → No decision on k, β has been made
    elseif network_structure == "preferential"
        net = barabasi_albert(n_nodes, 5)
    else
        throw(DomainError)
    end


    # create a space
    space = GraphSpace(net)
    # graphplot(net; curves = false)


    # define model properties
    properties = Dict(
        :base_susceptibility => base_susceptibility,
        :recovery_rate => recovery_rate,
        :infection_duration => infection_duration,
    )

    # create random number generator
    rng = Random.Xoshiro(seed)

    # Model; unremovable = agents never leave the model
    model = UnremovableABM(
        Person_Sim, space;
        properties, rng, scheduler=Schedulers.Randomly() # TODO: investigate what scheduler does? # @jakobrehmann: I belive you talked to Andre about this? If so, pls add a comment here
    )

    # add agents to model
    if hom_het == "homogenous"
        for i in 1:n_nodes
            p = Person_Sim(i, 1, base_susceptibility, 0, 0, 0, 0.9) # TODO: what does position of 1 mean? # Syd: I believe this means that the agent is placed on the node with id 1
            add_agent_single!(p, model)
        end
    elseif hom_het == "heterogenous"
        #First: Do the fearful people, second to last argument: 1 → fearful
        for i in 1:(n_nodes)*frac_fearful
            p = Person_Sim(i, 1, base_susceptibility, 0, 0, 1, 0.5)
            add_agent_single!(p, model)
        end
        #Now: To the crazy people, second to last argument : 2 → crazy
        for i in ((n_nodes)*frac_fearful+1):(n_nodes)
            p = Person_Sim(i, 1, base_susceptibility, 0, 0, 2, 1.5)
            add_agent_single!(p, model)
        end
    elseif hom_het == "heterogenous_assortative"
        if assortative == "fearful"
            original_group = 1
            new_group = 2
        elseif assortative == "crazy"
            original_group = 2
            new_group = 1
        end

        # {
        #     first_agent = random_agent(model)
        #     first_agent.group = new_group
        #     add_agent_single!(first_agent)
        #     empty_nearby_positions(first_agent)
        # }



        for i in 1:n_nodes
            p = Person_Sim(i, 1, base_susceptibility, 0, 0, original_group, 0.5) # TODO: what does position of 1 mean? # Syd: I believe this means that the agent is placed on the node with id 1
            add_agent_single!(p, model)
        end

        first_agent = random_agent(model)
        first_agent.group = new_group
        agents_p = Set()
        push!(agents_p, first_agent.id)
        all_neighbors = Set()
        no_remaining = n_nodes / 2 - 1
        people_added_to_group = 0
        while no_remaining > 0
            println("NUMBER REMAINING: $(no_remaining)")
            for agent in agents_p
                for neighbor in nearby_agents(getindex(model, agent), model)
                    if neighbor.group == original_group
                        neighbor.group = new_group
                        people_added_to_group += 1
                    end
                    push!(all_neighbors, neighbor.id)
                end
            end

            if people_added_to_group == 0
                first_agent = random_agent(model)
                while first_agent.group == new_group
                    first_agent = random_agent(model)
                end
                first_agent.group = new_group
                no_remaining -= 1
                agents_p = Set()
                push!(agents_p, first_agent.id)
            else
                no_remaining -= people_added_to_group
                people_added_to_group = 0
                agents_p = all_neighbors
            end
            all_neighbors = []
        end
    else
        throw(SystemError)
    end

    return model, net
end

# Agent Step Function: this transitions agents from one disease state to another
function agent_step!(person, model)
    # if infectious
    if person.health_status == 2
        if rand(model.rng) <= model.recovery_rate #Agents recover with a probability of recovery_rate
            person.health_status = 3
        end
    end

    # if exposed
    if person.health_status == 1 # if exposed
        person.health_status = 2 # change to infectious
    end

    # if susceptible
    if person.health_status == 0
        # loop through every neighbor
        for neighbor in nearby_agents(person, model)
            # check if neighbor is infected
            if neighbor.health_status == 2 # Infected
                # if so, roll dice to see if susceptible agent gets infected
                if rand(model.rng) <= (model.base_susceptibility * person.group_reduction_factor)
                    person.health_status = 1 # change to exposed
                end
            end
        end
    end
end