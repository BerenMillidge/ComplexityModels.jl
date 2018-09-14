# A simple model of affecting how bias affects representation of different groups
# at different ability threshold.
# these results can almost certainly be derived analytically
# just playing around really

using Plots


mutable struct Agent
	skill::Float64
	agent_type::Int
	discrim_multiplier::Float64
	threshold::Float64
    status::Int
end


mutable struct Model
    num_places::Int
    num_applications_per_epoch::Int
    num_epochs::Int
    current_agents::Array{Agent}
end

type_1_mean_skill = 100
type_1_skill_variance = 15
type_2_mean_skill = 100
type_2_skill_variance = 15
agent_type_prob = 0.5
type_1_discrim_multiplier = 1
type_2_discrim_multiplier = 1.1
type_1_threshold = 150
type_2_threshold = 150


function generate_agent_types(funclist, numbers)
	agentlist = []
	for func in funclist
		agents = [func() for i in 1:numbers]
		push!(agentlist, agents)
	end
	return agentlist
end

function generate_type_1()
    type_1_skill = (randn()*type_1_skill_variance) + type_1_mean_skill
    return Agent(type_1_skill, 1, type_1_discrim_multiplier, type_1_threshold, 0)
end

function generate_type_2()
    type_2_skill = (randn()*type_2_skill_variance) + type_2_mean_skill
    return Agent(type_2_skill, 2, type_2_discrim_multiplier, type_2_threshold, 0)
end

function generate_applicant()
    val = rand()
    if val <= agent_type_prob
       return generate_type_1()
    else
        return generate_type_2()
    end
end

function generate_agent_list(num_agents)
    return [generate_applicant() for i in 1:num_agents]
end

function frac(l::Array{Agent})
    total = 0
    for el in l
        if l.agent_type == 1
            total ++1
        end
    end
    return total / length(l)
end

function step!(model)
    for i in 1:length(model.current_agents)
        replaced = false
        agent = model.current_agents[i]
        while replaced ==false
            applicant = generate_applicant()
            #define the threshold
            if applicant.agent_type != agent.agent_type
                threshold = agent.threshold * agent.discrim_multiplier
            else
                threshold = agent.threshold
            end
            if applicant.skill > threshold
                # replace current agent with new one if above skill threshold!
               # print("Over threshold!!! replacing \n")
                model.current_agents[i] = applicant
                #print(model.current_agents[i])
               # print("\n")
               # print(agent)
               # print("\n")
                replaced = true
            end
        end
    end
    agents = copy(model.current_agents)
    return agents
end

frac_type_2(agents::Array{Agent}) = length(filter(x -> (x.agent_type > 1), agents)) / length(agents)
frac_type_2(log::Array{Array{Agent}}) = [frac_type_2(i) for i in log]

mean(arr::Array{Float64,1}) = sum(arr) / length(arr)

function run_model(num_epochs, num_places)
    # for now run all as type 1
    time::Array{Array{Agent}} = []
    current_agents = generate_agent_list(num_places)
    model = Model(num_places,0,0,current_agents)
    for i in 1:num_epochs
        agents = step!(model)
        push!(time, agents)
        #print(agents)
        #print("\n")
    end
    return time, model 
end

function plot_biases_thresholds()
    biases = [1,1.05,1.1,1.2,1.3,1.5]
    thresholds = [80,100,110,120,130,140,150]
    for bias in biases
        threshold_list::Array{Float64} = []
        type_2_discrim_multiplier = bias
        for threshold in thresholds
            type_1_threshold = threshold
            type_2_threshold = threshold
            l,m = run_model(50,50)
            push!(threshold_list, mean(frac_type_2(l)))
        end
        plot!(threshold_list, label="Bias: $bias")
        end
    xlabel!("Threshold")
    title!("Bias plot")
    savefig("bias_plot.png")
end

plot_biases_thresholds()