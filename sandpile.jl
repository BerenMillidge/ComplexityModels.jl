# julia code implementing and animating Bak's sandpile model of self-organised criticality

mutable struct avelanche_log 
    epoch::Int
    number_affected::Int
    coordinate_list::Array{Array{Int,1}, 1}
    
    function avelanche_log(epoch::Int)
        return new(epoch, 0, [])
    end
end

mutable struct Model
    map_size::Int # assumes a square model for now!
    epochs_to_run::Int
    epochs_ran::Int
    Map::Array{Int, 2}
    logs::Array{avelanche_log}
    threshold::Int
    maps::Array{Array{Int, 2},1}
    
    function Model(map_size::Int = 50, epochs_to_run::Int=1000, threshold::Int=4) 
        return new(
                     map_size,
                     epochs_to_run,
                     0,
                     zeros(map_size, map_size),
                     [],
                     threshold,
                    [])
    end
end


function trigger_avelanche(model::Model, x::Int, y::Int, log, map_size::Int, log_avelanches::Bool)
    model.Map[x,y] = 0
    for i in -1:1
        for j in -1:1
            if !(i == 0 && j==0) && !(i !=0 && j!=0)
                xpos = x+i
                ypos = y+j
                if xpos > 0 && ypos >0 && xpos <= map_size-1 && ypos <= map_size-1
                    model.Map[xpos, ypos] +=1
                    if  model.Map[xpos,ypos] > model.threshold
                        trigger_avelanche(model,xpos, ypos,log, map_size, log_avelanches)
                    end
                end
            end
        end
    end
    if log_avelanches == true
        push!(log.coordinate_list, [x,y])
    end
end
        
    

function run_epoch(model::Model, rand::Bool, log_avelanches::Bool)
    if rand == true
        randx = rand(1:model.map_size)
        randy = rand(1:model.map_size)
    else
        randx = 50
        randy = 50
    end
    model.Map[randx, randy] +=1
    if model.Map[randx,randy] >=model.threshold
        log = avelanche_log(model.epochs_ran)
        trigger_avelanche(model, randx,randy, log, model.map_size, log_avelanches)
        log.number_affected = length(log.coordinate_list)
        push!(model.logs, log)
                
    end
    model.epochs_ran +=1

end


function run_model(map_size::Int, num_epochs::Int, threshold::Int, rand::Bool, log_avelanches::Bool, log_maps::Bool)
    model = Model(map_size, num_epochs, threshold)
    for i in 1:num_epochs
        run_epoch(model,rand, log_avelanches)
        if log_maps == true
            push!(model.maps, model.Map)
        end
    end
    #print(model.Map)
    return model
end

anim = @animate for i in length(a.maps)
    heatmap(a.maps[i])
    end every 50
gif(anim, "test_anim.gif", fps=30)
