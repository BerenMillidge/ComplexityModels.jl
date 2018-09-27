# inspired by this paper:
#Synchronization:  The Key  to  Effective Communication  in Animal  Collectives

using Plots
using Images
using ImageView


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
    
    function Model(width::Int, height::Int, max_epochs::Int, threshold::Int, refractory_period::Int)
        return new(width, height, 0, max_epochs,threshold,refractory_period, zeros((width, height)), zeros((width, height)), [])
    end
end

mutable struct Point
    x::Int
    y::Int
end

print("Done!")
function set_first_array!(model::Model, arr::Array{Int, 2})
    model.array = arr
end

function flip_points!(model::Model, point_list::Array{Point})
    for point in point_list
        model.array[point.x, point.y] = 1
    end
end

function left_edge(model::Model, xpos::Int, ypos::Int)
    if model.current_epoch - model.epochs_array[xpos, ypos] <model. refractory_period
        return 0
    end # don't change if above refractory period
    sum = 0
    for y in -1:1
        ycurr = ypos + y
        sum += model.array[xpos, ycurr]
        sum += model.array[xpos+1, ycurr]
    end
    if sum >= model.threshold
        model.epoch_array[xpos, ypos] = model.current_epoch
        return 1
    else
        return 0
    end
end

function right_edge(model::Model, xpos::Int, ypos::Int)
    if model.current_epoch - model.epochs_array[xpos, ypos] <model. refractory_period
        return 0
    end # don't change if above refractory period
    sum = 0
    for y in -1:1
        ycurr = ypos + y
        sum += model.array[xpos, ycurr]
        sum += model.array[xpos-1, ycurr]
    end
    if sum >= model.threshold
        model.epoch_array[xpos, ypos] = model.current_epoch
        return 1
    else
        return 0
    end
end

function top_edge(model::Model, xpos::Int, ypos::Int)
    if model.current_epoch - model.epochs_array[xpos, ypos] <model. refractory_period
        return 0
    end # don't change if above refractory period
    sum = 0
    for x in -1:1
        xcurr = xpos + x
        sum += model.array[xcurr, ypos-1]
        sum += model.array[xcurr, ypos]
    end
    if sum >= model.threshold
        model.epoch_array[xpos, ypos] = model.current_epoch
        return 1
    else
        return 0
    end
end

function bottom_edge(model::Model, xpos::Int, ypos::Int)
    if model.current_epoch - model.epochs_array[xpos, ypos] <model. refractory_period
        return 0
    end # don't change if above refractory period
    sum = 0
    for x in -1:1
        xcurr = xpos + x
        sum += model.array[xcurr, ypos+1]
        sum += model.array[xcurr, ypos]
    end
    if sum >= model.threshold
        model.epoch_array[xpos, ypos] = model.current_epoch
        return 1
    else
        return 0 
    end
end

function check_square(model::Model,xpos::Int, ypos::Int)
    # count number of active around
    if model.current_epoch - model.epochs_array[xpos, ypos] <model. refractory_period
        return 0
    end # don't change if above refractory period
        
    sum = 0
    for x in -1:1
        for y in -1:1
            currx = xpos + x
            curry = ypos + y
            sum += model.array[currx, curry]
        end
    end
    if sum >= model.threshold
        model.epoch_array[xpos, ypos] = model.current_epoch
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
    for y in 2:model.height -1
        arr[0,y] = left_edge(model, 1, y)
        arr[model.width, y] = right_edge(model, model.width, y)
    end
    for x in 2:model.width -1
        arr[x,0] = bottom_edge(model, x, 1)
        arr[x, model.height] = top_edge(model, x, model.height)
    end
    
        
    for x in 2:model.width-1
        for y in 2:model.height-1
            arr[x,y] = check_square(model, x,y)
        end
    end
    model.array = arr
    model.current_epoch +=1
    push!(model.array_list, arr) # add the model to the array list... and hope this works
    # if I can get anything cool out of this, it will be worthwhile!
end

function run_model(width::Int, height::Int, max_epochs::Int, threshold::Int, refractory_period::Int,save_name,animate=true)
    model = Model(width, height, max_epochs, threshold, refractory_period)
    run_model(model,save_name,animate)
end

function run_model(model::Model,save_name, animate=true)
    for i in 1:model.max_epochs
        step!(model)
    end
    
    # animate
    if !(save_name.split(',')[-1] in ['gif','mp4'])
        save_name *= '.mp4'
    end
    @gif for 1:model.max_epochs
        plot(model.array_list[i])
    end
end
    
run_model(50,50, 100, 2, 0,'bib', true)
    
            
            
            