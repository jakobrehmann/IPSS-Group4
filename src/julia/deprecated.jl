
# plot = Plots.plot(1:iterations,
# overall/n_nodes * 100, linecolor = :gray,
# legend = false,
# xlabel = "time [t]", 
# ylabel = "proportion of population [%]",
# guidefontsize = 17,
# tickfontsize = 17
# )

# Plots.plot!(1:iterations,
# [infectious_1_avg, infectious_2_avg]/n_nodes * 100 / seed,
# linewidth = 3
# )

# savefig("Infections_With_Seeds.png")


 ######## VIZ

# model = initialize(; hom_het = "heterogenous")



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


# base_susceptibility = 0.5
# @time begin
#     for i in 1:900
#         model = initialize(;seed = i, n_nodes = n_nodes, n_edges = n_edges, n_infected_agents = n_infected_agents, base_susceptibility = base_susceptibility, hom_het = "heterogenous")
#         runModel(model, iterations)
#     end
# end


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