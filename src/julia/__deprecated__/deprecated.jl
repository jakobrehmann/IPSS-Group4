# df
# # Seed Plots

# function calc_min_max(network, scenario)
#     x = collect(1:iterations)
#     y = network_to_scenario_to_seed_to_data[network][scenario]["infections_avg"]
#     ymin = network_to_scenario_to_seed_to_data[network][scenario]["infections_avg"] - network_to_scenario_to_seed_to_data[network][scenario]["sd"]
#     ymax = network_to_scenario_to_seed_to_data[network][scenario]["infections_avg"] + network_to_scenario_to_seed_to_data[network][scenario]["sd"]

#     return x, y, ymin, ymax
# end

# ##### New attempt

# xd = 1:iterations
# yd = 
# Plots.plot(1:iterations,network_to_scenario_to_seed_to_data["smallworld"]["homogenous"]["infectious_per_seed"], color = :blue, opacity = 0.1)
# Plots.plot!(1:iterations,network_to_scenario_to_seed_to_data["smallworld"]["heterogenous"]["infectious_per_seed"], color = :red, opacity = 0.1)
# Plots.plot!(1:iterations,network_to_scenario_to_seed_to_data["smallworld"]["heterogenous_assortative"]["infectious_per_seed"], color = :green, opacity = 0.1)

# Plots.plot!(1:iterations,network_to_scenario_to_seed_to_data["smallworld"]["homogenous"]["infections_avg"], color = :blue, linewidth = 3)
# Plots.plot!(1:iterations,network_to_scenario_to_seed_to_data["smallworld"]["heterogenous"]["infections_avg"], color = :red, linewidth = 3)
# Plots.plot!(1:iterations,network_to_scenario_to_seed_to_data["smallworld"]["heterogenous_assortative"]["infections_avg"], color = :green, linewidth = 3)


# network = "smallworld"
# x_hom, y_hom, ymin_hom, ymax_hom = calc_min_max(network, "homogenous")
# x_het, y_het, ymin_het, ymax_het = calc_min_max(network, "heterogenous")
# x_het_ass, y_het_ass, ymin_het_ass, ymax_het_ass = calc_min_max(network, "heterogenous_assortative")

# p = Gadfly.plot(layer(x=x_hom, y=y_hom, ymin=ymin_hom, ymax=ymax_hom, Geom.line, Geom.ribbon, Gadfly.Theme(lowlight_color = c->RGBA{Float32}(0, 0, 255, 0.01))))
# savefig("yyy.png")
# layer(x=x_het, y=y_het, ymin=ymin_het, ymax=ymax_het, Geom.line, Geom.ribbon, Gadfly.Theme(default_color=colorant"green",  lowlight_color = c->RGBA{Float32}(c.r, c.g, c.b, 0.01))),
# layer(x=x_het_ass, y=y_het_ass, ymin=ymin_het_ass, ymax=ymax_het_ass, Geom.line, Geom.ribbon,Gadfly.Theme(default_color=colorant"red", lowlight_color = c->RGBA{Float32}(c.r, c.g, c.b, 0.01))))
# # 

# p
# draw(SVG("test1.svg", 12cm, 6cm), p)




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