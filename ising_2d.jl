# simple two dimensional Ising model case!
using Plots
using PyPlot
using PyCall
@pyimport matplotlib.animation as pyanim

mutable struct IsingModel
    lattice::Array{Int, 2}
    current_epoch:: Int
    size::Int
    
    IsingModel(size::Int) = new(zeros(size,size), 0, size)
end

const log_models = true
#it's a wraparound lattice
function update_point(model::IsingModel, x::Int, y::Int)
    xminus = x-1
    if xminus <= 0
        xminus = model.size -1
    end
    xplus = x+1
    if xplus >model.size
        xplus = 1
    end
    yminus = y - 1
    if yminus <= 0
        yminus = model.size - 1
    end
    yplus = y + 1
    if yplus > model.size 
        yplus = 1
    end
    #wrap around!
    total = model.lattice[xminus, y] + model.lattice[xplus, y] + model.lattice[x, yminus] + model.lattice[x, yplus]
    if total > 0
        model.lattice[x,y] = 1
    end
    if total < 0
        model.lattice[x,y] = -1
    end
    # if nothing do the same
end


function step!(model::IsingModel)
    for i in 1:model.size
        for j in 1:model.size
            update_point(model, i,j)
        end
    end
    model.current_epoch +=1
end

function init_lattice(model::IsingModel,frac_pos::Float64)
    for i in 1:model.size
        for j in  1:model.size
            rn = rand()
            if rn <= frac_pos
                model.lattice[i,j] = 1
            else
                model.lattice[i,j] = -1
            end
        end
    end
end

frac_positive(model::IsingModel) = sum(filter((x -> (x > 0)), model.lattice)) / (model.size * model.size)
    

function run_model(lattice_size::Int, num_epochs::Int, frac_pos::Float64)
    model = IsingModel(lattice_size)
    init_lattice(model, frac_pos)
    logs = []
    for i in 1:num_epochs
        step!(model)
        log = copy(model.lattice)
        push!(logs, log)
        print(frac_positive(model))
        print("\n")
    end
    return logs, model
end


l,m = run_model(50, 20000, 0.5)
heatmap(m.lattice)

#animate logs!
function julia_animate()
    anim = @animate for i in 1:length(l)
        heatmap(l[i])
        end 
    gif(anim, "ising_anim.gif", fps=30)
end
julia_animate()


function python_anim()
    fig = figure("IsingFig", figsize = (5,5))
    
    function animate(i)
        return heatmap(l[i+1])
    end
    
    
    myanim = pyanim.FuncAnimation(fig, animate, frames=80, interval=20)
    myanim[:save]("Ising_test.mp4", bitrate=-1, extra_args=["-vcodec", "libx264", "-pix_fmt", "yuv420p"])
end

python_anim()