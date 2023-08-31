# Import neccessary packages
using Pkg
Pkg.activate(".")
using Agents, Random, Graphs, Plots, Makie, CairoMakie, GraphMakie, GraphIO, Colors, GLMakie, DataFrames
# pkg> add https://github.com/asgolovin/Agents.jl

include("model.jl")
include("model_utils.jl")
include("viz.jl")


# base_susceptibility = 0.5
# @time begin
#     for i in 1:900
#         model = initialize(;seed = i, n_nodes = n_nodes, n_edges = n_edges, n_infected_agents = n_infected_agents, base_susceptibility = base_susceptibility, hom_het = "heterogenous")
#         runModel(model, iterations)
#     end
# end


# RUN MULTIPLE times
susc_1_avg = [] 
susc_2_avg = []
exposed_avg = []
infectious_avg = []
infectious_1_avg = []
infectious_2_avg = []
recovered_avg = []
overall = []


# PARAMS
seed = 5
iterations = 30
base_susceptibility = 0.5
hom_het = "heterogenous"
n_nodes = 1000
n_edges = 1500
n_infected_agents = 100


@time begin
    for i in 1:seed
        # create model
        model = initialize(;
        seed = i,
         n_nodes = n_nodes,
          n_edges = n_edges,
           n_infected_agents = n_infected_agents,
            base_susceptibility = base_susceptibility, 
            hom_het = hom_het
            )
        
        # run model for x iterations & extract vector w/ disease state counts per iteration
        plot, susc, susc_1, susc_2, exposed, infectious, infectious_1, infectious_2, recovered  = runModelWithPlot(model, iterations)
        # savefig(plot, "seir_plot$(i).png") 
        push!(overall, infectious_1)
        push!(overall, infectious_2)
        if infectious_1_avg == [] 
            infectious_1_avg = infectious_1
            infectious_2_avg = infectious_2
        else
            infectious_1_avg += infectious_1
            infectious_2_avg += infectious_2
        end
    end
end

plot = Plots.plot(1:iterations,
overall/n_nodes * 100, linecolor = :gray,
legend = false,
xlabel = "time [t]", 
ylabel = "proportion of population [%]",
guidefontsize = 17,
tickfontsize = 17
)

Plots.plot!(1:iterations,
[infectious_1_avg, infectious_2_avg]/n_nodes * 100 / seed,
linewidth = 3
)

savefig("Infections_With_Seeds.png")


 ######## VIZ

# model = initialize(; hom_het = "heterogenous")

# adata = [(susceptible, count), (exposed, count), (infectious, count), (recovered, count)]

# # static plot:
# figure, _ = abmplot(model; ac = person_color, am = person_shape, as = 25)
# figure

# # interactive plot: 
# model = initialize(;hom_het = "heterogenous")
# figs, abmobs = abmexploration(model; agent_step!, ac = person_color, am = person_shape, as = 25, adata)
# figs

# # video
# model = initialize(;seed = 55, n_nodes = 100, n_edges = 150, n_infected_agents = 10, base_susceptibility = 0.5, hom_het = "heterogenous")
# abmvideo("ourmodel.mp4", model, agent_step!; ac = person_color, am = person_shape, as = 25, frames = 25, framerate = 5)


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