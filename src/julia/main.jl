# Import neccessary packages
using Pkg
Pkg.activate(".")
using Agents, Random, Graphs, Plots, Makie, CairoMakie, GraphMakie, GraphIO, GLMakie, DataFrames
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
    days_infected::Int
    group::Int # 0:avg; 1: low-contact; 2: high-contact
end

# susceptible(p::Person_Sim) = p.health_status == 0
# exposed(p::Person_Sim) = p.health_status == 1
# infectious(p::Person_Sim) = p.health_status == 2
# recovered(p::Person_Sim) = p.health_status == 3

# creates ABM with default values (can be overwritten)
function initialize(;
    base_susceptibility = 0.1,
    infection_duration = 5,
    n_nodes = 100,
    n_edges = 200,
    n_infected_agents = 10,
    seed = 1234
)

    # Environment
    net = erdos_renyi(n_nodes,n_edges)    # input : nodes, edges # small world? watson 

    # create a space
    space = GraphSpace(net)
    # graphplot(net; curves = false)


    # define model properties
    properties = Dict(
        :base_susceptibility => base_susceptibility,
        :infection_duration => infection_duration,
    )

    # create random number generator
    rng = Random.Xoshiro(seed)

    # Model; unremovable = agents never leave the model
    model = UnremovableABM(
        Person_Sim, space;
            properties, rng, scheduler = Schedulers.Randomly() # TODO: investigate what scheduler does? 
        )
    
    # add agents to model
    for i in 1:n_nodes
        p = Person_Sim(i,1,base_susceptibility,0,0,0) # TODO: what does position of 1 mean?
        add_agent_single!(p,model)
    end

    # infect a random group of agents
    # TODO: make sure the same agent isn't infected multiple times 
    for i in 1:n_infected_agents
        sick_person = random_agent(model)
        sick_person.health_status = 2
    end

    #TODO: @Syd: impement heterogenous agents w/ different susceptiblities

    return model
end

# Agent Step Function: this transitions agents from one disease state to another
function agent_step!(person,model)
    # if infectious
    if person.health_status == 2 
        person.days_infected += 1
        if person.days_infected == model.infection_duration
            # person.days_infected = 0
            person.health_status = 3
        end
    end
    
    # if exposed
    if person.health_status == 1 # if exposed
        person.health_status = 2 # change to infectious
    end


    # TODO: @Syd 

    # if susceptible
    if person.health_status == 0
        # loop through every neighbor
        for neighbor in nearby_agents(person, model)
            # check if neighbor is infected
            if neighbor.health_status == 2 # Infected
                # if so, roll dice to see if susceptible agent gets infected
                if rand(model.rng) <= model.base_susceptibility
                    person.health_status = 1 # change to exposed
                end
            end
        end
    end
end

# prints details of model state in each iteration
function print_details(model)
    cnt_susc = 0
    cnt_exposed = 0
    cnt_infectious = 0
    cnt_recovered = 0
    for agent in allagents(model)
        if agent.health_status == 0
            cnt_susc += 1
        elseif agent.health_status == 1
            cnt_exposed += 1
        elseif agent.health_status == 2
            cnt_infectious += 1
        else
            cnt_recovered += 1
        end
    end
    
    println("susc: $(cnt_susc), exposed: $(cnt_exposed), infectious: $(cnt_infectious), recovered:$(cnt_recovered)", )
    return cnt_susc, cnt_exposed,cnt_infectious,cnt_recovered
end


n_nodes = 1000
n_infected_agents = 100
model = initialize(;n_nodes = n_nodes, n_edges = 1255, n_infected_agents = n_infected_agents)
cum_susc = []
cum_exposed = []
cum_infectious = []
cum_recovered = []

num_days = 30
for i in 1:num_days
    cnt_susc,cnt_exposed,cnt_infectious,cnt_recovered = print_details(model)
    push!(cum_susc,cnt_susc)
    push!(cum_exposed,cnt_exposed)
    push!(cum_infectious,cnt_infectious)
    push!(cum_recovered,cnt_recovered)
    step!(model, agent_step!)
end


graphplot(model.space.graph; curves = false)


# Creates SEIR Lineplot
Plots.plot(1:num_days,
[cum_susc cum_exposed cum_infectious cum_recovered]/n_nodes * 100,
 labels = ["S" "E" "I" "R"], 
 linewidth=3,
 linecolor = [:blue :orange :red :black],
 xlabel = "time [t]", 
 ylabel = "proportion of population [%]",
 guidefontsize = 17,
 tickfontsize = 17,
 legendfontsize = 17)

savefig("seir_plot.png") 



######## VIZ

model = initialize()


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
        return :triangle 
    elseif person.group == 2
        return :circle
    else
        return
    end
end


# static plot:
figure, _ = abmplot(model; ac = person_color, am = :circle, as = 10)
figure

# interactive plot: 
model = initialize()
figs, abmobs = abmexploration(model; agent_step!, ac = person_color, am = :circle, as = 25)
figs

# video
abmvideo("ourmodel.mp4", model, agent_step!; ac = person_color, am = :rect, as = 25, frames = 200, framerate = 30)


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