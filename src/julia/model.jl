# Import neccessary packages
using Pkg
Pkg.activate(".")
using Agents, Random, Graphs, Plots, Makie, CairoMakie, GraphMakie, GraphIO, Colors, GLMakie, DataFrames, Statistics, CSV
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

# creates network with default values
function initializeNetwork(;
    n_nodes = 1000,
    network_structure="random" #Options: "random", "smallworld"
)

    if network_structure == "random"
        net = erdos_renyi(n_nodes, 10/ n_nodes)   
    elseif network_structure == "smallworld"
        net = newman_watts_strogatz(n_nodes, 10, 0.01) #expected degree k(1 + β) (k = second param, β = third param)
    elseif network_structure == "preferential"
        net = barabasi_albert(n_nodes, 5) 
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
    hom_het="homogenous",
    assortative="fearful",
    frac_fearful=0.5
)



    # create a space
    space = GraphSpace(net)


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
        properties, rng, scheduler=Schedulers.Randomly() # explain
    )

    # add agents to model
    if hom_het == "homogenous"
        for i in 1:n_nodes
            p = Person_Sim(i, 1, base_susceptibility, 0, 0, 0, 1.0) # JR: Changed from 0.9
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
        if assortative == "fearful" # 
            original_group = 2 
            original_group_factor = 1.5
            new_group = 1 # fearful → 1
            new_group_factor = 0.5 # fearful 
        elseif assortative == "crazy"
            original_group = 1
            original_group_factor = 0.5
            new_group = 2
            new_group_factor = 1.5

        end

        first_agent = Person_Sim(1, 1, base_susceptibility, 0, 0, new_group, new_group_factor)
        add_agent_single!(first_agent, model)
        no_remaining = n_nodes / 2 - 1
        agent_counter = 2

        r = 1 #search neighbordhood radius
        #agents are placed on neighboring nodes of initial agent → radius of neighborhood is incrementally increased
        while (no_remaining > 0)
            neighbors = collect(empty_nearby_positions(first_agent, model, r))

            #Only occurs if there are no more empty positions in the neighborhood (might occur if network isn't conntected) #TODO: check if text in () holds true for code
            while length(neighbors) == 0 && no_remaining > 0
                empty_pos = collect(Agents.empty_positions(model))

                if length(empty_pos) == 0 #TODO: check if this is necessary
                    @goto escape_label
                end
                
                #choose a random position for which the neighborhood search is started again
                pos = rand(empty_pos)

                first_agent = Person_Sim(agent_counter, pos , base_susceptibility, 0, 0, new_group, new_group_factor)
                add_agent_pos!(first_agent, model) #agent is not placed on a random position, but rather placed on node pos
                agent_counter += 1
                no_remaining -= 1
                r = 1
                neighbors = collect(empty_nearby_positions(first_agent, model, r))
            end

            #adds agents to all empty spaces in neighborhood
            for neighbor_pos in neighbors
                p = Person_Sim(agent_counter, neighbor_pos, base_susceptibility, 0, 0, new_group, new_group_factor)
                add_agent_pos!(p, model) #again, agents not placed on random node, but rather on node pos
                agent_counter += 1
                no_remaining -= 1
                # If there's no more agents to be placed, then escape the nested loop
                if no_remaining == 0
                    @goto escape_label
                end
            end
            r += 1
        end
        @label escape_label

        #fill remaining positions with other group
        for agent_pos in collect(empty_positions(model))
            p = Person_Sim(agent_counter, agent_pos, base_susceptibility, 0, 0, original_group,original_group_factor)
            add_agent_pos!(p, model)
            agent_counter += 1
        end
    else
        throw(SystemError)
    end
    return model
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