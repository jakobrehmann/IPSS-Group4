Work of Group 4 @ the [IPSS summer school](https://summerschool.infodemics.info/) in Lübeck. This repostories contains our exploratory work and models. One model has been built in python, one model has been built in Julia.
# Julia 
**main.jl** \
**model.jl** \
**model_utils.jl** \
**viz.jl:** Contains two functions: \
1. person_color: \
- Determines the color of the agent on the graph plot \
- Color depends on disease state \
- Susceptible = blue, exposed = orange, infected = red, recovered = black \
2. person_shape: \
- Determines the shape of the agent on the graph plot \
- Shape depends on the agent's group \
- Hom. risk reduction = rectangles, fearful (more extreme) risk reduction = cross, crazy (fewer) risk reduction = star
