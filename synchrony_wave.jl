#__precompile()__

using Plots
using Images
using ImageView
using Distances


mutable struct Model
    width::Int
    height::Int
    current_epoch::Int
    max_epochs::Int
    threshold::Int
    refractory_period::Int
    array::Array{Int, 2}
    epochs_array::Array{Int, 2}
    array_list::Array{Array{Int, 2}}
    changeback_prob::AbstractFloat
    
    function Model(width::Int, height::Int, max_epochs::Int, threshold::Int, refractory_period::Int, changeback_prob::AbstractFloat)
        if changeback_prob < 0 || changeback_prob > 1
            throw("Changeback probability must be between 0 and 1")
        end
        return new(width, height, 0, max_epochs,threshold,refractory_period, zeros((width, height)), -1 * refractory_period * ones((width, height)), [], changeback_prob)
    end
end

mutable struct Point
    x::Int
    y::Int
end


function set_first_array!(model::Model, arr::Array{Int, 2})
    model.array = arr
end

function flip_points!(model::Model, point_list::Array{Point})
    for point in point_list
        model.array[point.x, point.y] = 1
    end
end

function left_edge(model::Model, xpos::Int, ypos::Int)
    if model.array[xpos, ypos] >0
        r = rand()
        if r < model.changeback_prob
            return 0
        else
            return 1
        end
    end
    if model.current_epoch - model.epochs_array[xpos, ypos] <model. refractory_period
        return 0
    end # don't change if above refractory period
    sum::Int = 0
    for y::Int in -1:1
        ycurr::Int = ypos + y
        sum += model.array[xpos, ycurr]
        sum += model.array[xpos+1, ycurr]
    end
    if sum >= model.threshold
        model.epochs_array[xpos, ypos] = model.current_epoch
        return 1
    else
        return 0
    end
end

function right_edge(model::Model, xpos::Int, ypos::Int)
    if model.array[xpos, ypos] > 0
        r = rand()
        if r < model.changeback_prob
            return 0
        else
            return 1
        end
    end
    if model.current_epoch - model.epochs_array[xpos, ypos] < model.refractory_period
        return 0
    end # don't change if above refractory period
    sum::Int = 0
    for y::Int in -1:1
        ycurr::Int = ypos + y
        sum += model.array[xpos, ycurr]
        sum += model.array[xpos-1, ycurr]
    end
    if sum >= model.threshold
        model.epochs_array[xpos, ypos] = model.current_epoch
        return 1
    else
        return 0
    end
end

function top_edge(model::Model, xpos::Int, ypos::Int)
    if model.array[xpos, ypos] > 0
        r = rand()
        if r < model.changeback_prob
            return 0
        else
            return 1
        end
    end
    if model.current_epoch - model.epochs_array[xpos, ypos] <model.refractory_period
        return 0
    end # don't change if above refractory period
    sum::Int = 0
    for x::Int in -1:1
        xcurr::Int = xpos + x
        sum += model.array[xcurr, ypos-1]
        sum += model.array[xcurr, ypos]
    end
    if sum >= model.threshold
        model.epochs_array[xpos, ypos] = model.current_epoch
        return 1
    else
        return 0
    end
end

function bottom_edge(model::Model, xpos::Int, ypos::Int)
    if model.array[xpos, ypos] > 0
        r = rand()
        if r < model.changeback_prob
            return 0
        else
            return 1
        end
    end
     if model.current_epoch - model.epochs_array[xpos, ypos] <model.refractory_period
        return 0
    end # don't change if above refractory period
    sum::Int = 0
    for x::Int in -1:1
        xcurr::Int = xpos + x
        sum += model.array[xcurr, ypos+1]
        sum += model.array[xcurr, ypos]
    end
    if sum >= model.threshold
        model.epochs_array[xpos, ypos] = model.current_epoch
        return 1
    else
        return 0 
    end
end

function check_square(model::Model,xpos::Int, ypos::Int)
    # count number of active around # don't change if above refractory period
    # flip back with some stochasticity
    if model.array[xpos, ypos] > 0
        r = rand()
        if r < model.changeback_prob
            return 0
        else
            return 1
        end
    end
    if model.current_epoch - model.epochs_array[xpos, ypos] <model.refractory_period
        return 0
    end
    sum::Int = 0
    for x::Int in -1:1
        for y::Int in -1:1
            currx::Int = xpos + x
            curry::Int = ypos + y
            sum += model.array[currx, curry]
        end
    end
    if sum >= model.threshold
        model.epochs_array[xpos, ypos] = model.current_epoch
        return 1
    else
        return 0
    end
end


function step!(model::Model)
    if model.current_epoch > model.max_epochs
        print("Maximum number of epochs reached!")
        return model
    end
    # now iterate through all of the points
    # copy the current arr to change
    arr = copy(model.array)
    # actually I should perhaps try implementing this on a torus... except the obvious fact that bees or whatever
    # don't exist on a torus... there are edge effects in nature
    # first all the top xs
    for y::Int in 2:model.height -1
        arr[1,y] = left_edge(model, 1, y)
        arr[model.width, y] = right_edge(model, model.width, y)
    end
    for x::Int in 2:model.width -1
        arr[x,1] = bottom_edge(model, x, 1)
        arr[x, model.height] = top_edge(model, x, model.height)
    end
    
        
    for x::Int in 2:model.width-1
        for y::Int in 2:model.height-1
            arr[x,y] = check_square(model, x,y)
        end
    end
    model.array = arr
    model.current_epoch +=1
    push!(model.array_list, arr) # add the model to the array list... and hope this works
    # if I can get anything cool out of this, it will be worthwhile!
    #print(model.epochs_array)
end


function set_circle_on(model::Model, xcenter::Int, ycenter::Int, radius::Int)
    arr = copy(model.array) # only do this once... it doens't really hurt
    r = radius
    w = model.width
    h = model.height
    
    for x in xcenter-r:xcenter+r
        if x >0 && x <=w
            for y in ycenter-r:ycenter+r
                if y > 0 && y <=w
                    dist = euclidean([x,y], [xcenter, ycenter])
                    if dist <= radius
                        arr[x,y] = 1
                    end
                end
            end
        end
    end
    return arr            
end

function run_model(width::Int, height::Int, max_epochs::Int,threshold::Int, refractory_period::Int,save_name,animate=true)
    model = Model(width, height, max_epochs, threshold, refractory_period)
    run_model(model,save_name,animate)
end

function run_model(model::Model,save_name, animate=true)
    for i in 1:model.max_epochs
        step!(model)
        #print(model.array)
    end
    
    # animate
    if animate == true
        splits = split(save_name, '.')
        if !(splits[length(splits)] in ["gif","mp4"])
            save_name *= ".mp4"
        end
        anim = @animate for i in 1:length(model.array_list)
            heatmap(model.array_list[i], c=:ice)
        end
        gif(anim, "synchrony.mp4", fps=30)
    end
end

function run_model(model::Model,xcenter, ycenter, radius,save_name, animate=true)
    model.array = set_circle_on(model, xcenter, ycenter, radius)
    for i in 1:model.max_epochs
        step!(model)
        #print(model.array)
    end
    
    # animate
    if animate == true
        splits = split(save_name, '.')
        if !(splits[length(splits)] in ["gif","mp4"])
            save_name *= ".mp4"
        end
        anim = @animate for i in 1:length(model.array_list)
            heatmap(model.array_list[i], c=:ice)
        end
        gif(anim, save_name, fps=30)
    end
end

function run_models()
    for i in 1:10
        print("Running model: " * string(i))
        width = 50
        height = 50
        num_epochs = 500
        threshold = 2
        refractory_period = 5
        changeback_prob = 0.7
        model::Model = Model(width, height, num_epochs, threshold, refractory_period, changeback_prob)
        sname = "wave_" * string(width) * "_" * string(height) * "_" * string(threshold) * "_" * string(refractory_period) * "_" * string(changeback_prob) * "_" * string(i) * ".mp4"
        run_model(model, 25,25,2,sname, true)
        #model = 0
    end
end
print("Done!")
pwd()