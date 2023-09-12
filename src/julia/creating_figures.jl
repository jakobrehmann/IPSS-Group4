include("model.jl")
include("model_utils.jl")
include("viz.jl")

n_nodes = 250 

begin
    net = initializeNetwork(; n_nodes = n_nodes, network_structure = "smallworld")
    model = initialize(net;
    seed=5,
    n_nodes=n_nodes,
    base_susceptibility=0.1,
    hom_het="heterogenous_assortative"
    )

    sick_person = random_agent(model) # does this use the seed?
    sick_person.health_status = 2


# For the hetero-assortative network, the infections will typically die out before all are infected.
# Is that okay? 

    figure, _ = abmplot(model; ac = person_color2, am = person_shape, as = 25)
    figure


    # figs, abmobs = abmexploration(model; agent_step!, ac = person_color, am = person_shape, as = 25, adata)
    # figs

    abmvideo("ourmodel.mp4", model, agent_step!; 
    ac = person_color, am = person_shape, as = 15, frames = 150, framerate = 5,
    figure = (; resolution = (1600, 1600))) 

    # savefig(figure,"smallworld-heterogenous_assortative.png")

end

model = initialize(;hom_het = "heterogenous")
figs, abmobs = abmexploration(model; agent_step!, ac = person_color, am = person_shape, as = 25, adata)
figs

function person_color2(p)
    p = collect(p)[1]
    if p.group == 1
        return :purple
    else
        return :orange

    end
end

figure, _ = abmplot(model; ac = person_color2, am = person_shape, as = 25)
figure