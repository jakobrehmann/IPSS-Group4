# Import neccessary packages
using Pkg
Pkg.activate(".")
using Agents, Random, Graphs, Plots, Makie, CairoMakie, GraphMakie, GraphIO, Colors, GLMakie, DataFrames
# pkg> add https://github.com/asgolovin/Agents.jl

#TODO: @jakob: 
# How to create a visualization? 
# Option 1) using anastasia's packages
# Option 2) create static images of each state using Graph.gl, and put together as gif/video (using ffmpeg)
# Option 3) export each iteration as csv, and import to gephi

# Define Agent
@agent Person_Sim GraphAgent begin
    susceptibility::Float64 # between 0 (no chance of infection) and 1 (100% chance)
    health_status::Int# 0: Susceptible; 1: Exposed; 2: Infected; 3: Recovered
    days_infected::Int # TODO: Now that we're going for a recovery rate → Do we still need this?
    group::Int # 0:avg; 1: low-contact (fearful); 2: high-contact (crazy)
    group_reduction_factor::Float64 #Factor describing by how much contacts are reduced
end

# susceptible(p::Person_Sim) = p.health_status == 0
# exposed(p::Person_Sim) = p.health_status == 1
# infectious(p::Person_Sim) = p.health_status == 2
# recovered(p::Person_Sim) = p.health_status == 3

# creates ABM with default values (can be overwritten)
function initialize(;
    base_susceptibility = 0.1,
    recovery_rate = 0.2,
    infection_duration = 5,
    n_nodes = 100,
    n_edges = 200,
    n_infected_agents = 10,
    seed = 1234,
    hom_het = "homogenous",
    frac_fearful = 0.5,
    network_structure = "random" #Options: "random", "smallworld"
)

    # Environment
    if network_structure == "random"
        net = erdos_renyi(n_nodes,n_edges)    # input : nodes, edges # small world? watson # TODO: how to implement alternative network structure?
    elseif network_structure == "smallworld"
        net = newman_watts_strogatz(n_nodes, k, β) #expected degree k(1 + β) #TODO: This is very much work in progress → No decision on k, β has been made
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
            properties, rng, scheduler = Schedulers.Randomly() # TODO: investigate what scheduler does? # @jakobrehmann: I belive you talked to Andre about this? If so, pls add a comment here
        )
    
    # add agents to model
    if hom_het == "homogenous"
        for i in 1:n_nodes
            p = Person_Sim(i,1,base_susceptibility,0,0,0,0.9) # TODO: what does position of 1 mean? # Syd: I believe this means that the agent is placed on the node with id 1
            add_agent_single!(p,model) 
        end
    elseif hom_het == "heterogenous"
        #First: Do the fearful people, second to last argument: 1 → fearful
        for i in 1:(n_nodes)*frac_fearful
            p = Person_Sim(i,1,base_susceptibility,0,0,1,0.85) 
            add_agent_single!(p,model)
        end
        #Now: To the crazy people, second to last argument : 2 → crazy
        for i in ((n_nodes)*frac_fearful+1):(n_nodes)
            p = Person_Sim(i,1,base_susceptibility,0,0,2,0.95) 
            add_agent_single!(p,model)
        end
    end

    # infect a random group of agents
    # TODO: make sure the same agent isn't infected multiple times #TODO @jakobrehmann: Pls check my work + give feedbck
    i = 0 
    while i < n_infected_agents
        sick_person = random_agent(model)
        if sick_person.health_status == 0
          sick_person.health_status = 2
          i +=1
        end
    end

    return model
end

# Agent Step Function: this transitions agents from one disease state to another
function agent_step!(person,model)
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

# prints details of model state in each iteration
function print_details(model)
    cnt_susc_01 = 0
    cnt_susc_2 = 0
    cnt_exposed = 0
    cnt_infectious = 0
    cnt_recovered = 0
    for agent in allagents(model)
        if agent.group == 0 || agent.group == 1 #fearful people
            if agent.health_status == 0
                cnt_susc_01 += 1
            end
        else 
            if agent.health_status == 0 #crazy people
                cnt_susc_2 += 1
            end
        end
        if agent.health_status == 1
            cnt_exposed += 1
        elseif agent.health_status == 2
            cnt_infectious += 1
        elseif agent.health_status == 3
            cnt_recovered += 1
        end
    end
    
    println("susc group 01: $(cnt_susc_01),susc group 2: $(cnt_susc_2), exposed: $(cnt_exposed), infectious: $(cnt_infectious), recovered:$(cnt_recovered)", )
    return cnt_susc_01, cnt_susc_2, cnt_exposed,cnt_infectious,cnt_recovered
end


n_nodes = 10
n_infected_agents = 4
n_edges = 10
model = initialize(;n_nodes = n_nodes, n_edges = n_edges, n_infected_agents = n_infected_agents, hom_het = "heterogenous", frac_fearful = 0.5, network_structure = "random")
cum_susc_01 = []
cum_susc_2 = []
cum_exposed = []
cum_infectious = []
cum_recovered = []

num_days = 30
for i in 1:num_days
    cnt_susc_01,cnt_susc_2,cnt_exposed,cnt_infectious,cnt_recovered = print_details(model)
    push!(cum_susc_01,cnt_susc_01)
    push!(cum_susc_2,cnt_susc_2)
    push!(cum_exposed,cnt_exposed)
    push!(cum_infectious,cnt_infectious)
    push!(cum_recovered,cnt_recovered)
    step!(model, agent_step!)
end


plot_labels = ["S" "E" "I" "R"]
plot_lines = [cum_susc_01 cum_exposed cum_infectious cum_recovered]
plot_linecolor = [:blue :orange :red :black]

plot_labels = ["S_fearful" "S_crazy" "E" "I" "R"]
plot_lines = [cum_susc_01 cum_susc_2 cum_exposed cum_infectious cum_recovered]
plot_linecolor = [:blue :lightblue :orange :red :black]

Plots.plot(1:num_days,
plot_lines/n_nodes * 100,
 labels = plot_labels, 
 linewidth=3,
 linecolor = plot_linecolor,
 xlabel = "time [t]", 
 ylabel = "proportion of population [%]",
 guidefontsize = 17,
 tickfontsize = 17,
 legendfontsize = 17)

 savefig("seir_plot.png") 



######## VIZ

model = initialize(; hom_het = "heterogenous")


function person_color(p)
   
    person = collect(p)[1]
    if person.health_status == 0
        return :blue
    elseif person.health_status == 1
       return :orange 
    elseif person.health_status == 2
       return :red 
    else
       return :black 
   end
end

function person_shape(p)
    person = collect(p)[1]
    if person.group == 0
        return :rect 
    elseif person.group == 1 
        return :rect 
    elseif person.group == 2
        return :circle
    else
        return
    end
end


# static plot:
figure, _ = abmplot(model; ac = person_color, am = person_shape, as = 25)
figure

# interactive plot: 
model = initialize(hom_het = "heterogenous")
figs, abmobs = abmexploration(model; agent_step!, ac = person_color, am = person_shape, as = 25)
figs

# video
abmvideo("ourmodel.mp4", model, agent_step!; ac = person_color, am = person_shape, as = 25, frames = 200, framerate = 30)


# DEPRECATED 

# graphplotkwargs = (
    # layout = Shell(), # node positions
#     arrow_show = false, # hide directions of graph edges
#     edge_color = :blue, # change edge colors and widths with own functions
#     edge_width = 3,
#     edge_plottype = :linesegments # needed for tapered edge widths
# )


# ids = []
# disease_status = []

# for agent in allagents(model)
#     push!(ids, agent.id)
#     push!(disease_status, agent.health_status)
# end