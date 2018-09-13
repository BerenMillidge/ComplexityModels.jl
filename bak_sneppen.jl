# bak sneppen model of evolution simply implemented

mutable struct BakSneppenModel
    world::Array{Real, 1}
    current_epoch::Int
    threshold::Int
    maxVal::Int
    worldLength::Int
    
    function BakSneppenModel(threshold::Int, maxval::Int, worldLength::Int)
        return new(zeros(worldLength), 0, threshold, maxval, worldLength)
    end
end

const log_worlds = true
step_type = "minimum"

logs = zeros(20)

function indmin(arr::AbstractArray)
    val = 1e10
    min_i = 0
    for i in 1:length(arr)
        if arr[i] < val
            val = arr[i]
            min_i = i
        end
    end
    return min_i
end

function step!(model::BakSneppenModel)
    if step_type != "minimum"
       index = rand(1:model.worldLength)
    end
    if step_type =="minimum"
        index = indmin(model.world)
    end
    
    randval= rand(1:model.maxVal)
    model.world[index] = randval # randomise
    # then go through vector checkingto see if everything is random!
    for i in 1:model.worldLength
        if model.world[i] < model.threshold
            val = rand(1:model.maxVal)
            model.world[i] = val
            # and the ones around it
            minuspos = i-1
            pluspos = i+1
            # do a wrap aroudn the world -... I shold abstract this?
            if minuspos <=0
                minuspos = model.worldLength-1
            end
            if minuspos >= model.worldLength
                minuspos = 1
            end
            if pluspos <= 0
                pluspos = model.worldLength -1
            end
            if pluspos >= model.worldLength
                pluspos = 1
            end
            
            model.world[minuspos] = rand(1:model.maxVal)
            model.world[pluspos] = rand(1:model.maxVal)
        end
    end
    model.current_epoch +=1
    if log_worlds == true
        return model.world
    end
end

function run_model(num_epochs, threshold, maxval, worldLength)
    model = BakSneppenModel(threshold, maxval, worldLength)
    for i in 1:num_epochs
        log = step!(model)
        print(log)
        logs[i] = log[1]
        
    end
    return logs
end

logs = run_model(2, 40, 50, 5)