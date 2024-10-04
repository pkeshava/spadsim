module spadsim

using Random

function simulate_spad(lambda::Float64, pde::Float64, dcr::Float64, sim_time::Float64 = 1e-6, time_step::Float64 = 1e-9)
    # Initialize variables
    avalanche_times = Float64[]  # Array to store avalanche times
    current_time = 0.0           # Start time
    total_steps = Int(round(sim_time / time_step))  # Total steps to simulate

    for step in 1:total_steps
        current_time += time_step

        # Check if a photon arrives
        if rand() < lambda * time_step  # Poisson arrival for photons
            if rand() < pde             # Photon detected with PDE
                push!(avalanche_times, current_time)
            end
        end

        # Check for dark counts
        if rand() < dcr * time_step  # Poisson arrival for dark counts
            push!(avalanche_times, current_time)
        end
    end

    return avalanche_times
end

struct SPAD
    lambda::Float64  # Photon arrival rate
    pde::Float64     # Photon detection efficiency
    dcr::Float64     # Dark count rate
end

function run_spad(spad::SPAD, event_channel::Channel, sim_time::Float64=100e-6, time_step::Float64=1e-9)
    current_time = 0.0
    total_steps = Int(round(sim_time / time_step))

    for step in 1:total_steps
        current_time += time_step

        # Check for photon arrival and detection
        if rand() < spad.lambda * time_step
            if rand() < spad.pde
                put!(event_channel, current_time)  # Send event to channel
            end
        end

        # Check for dark count
        if rand() < spad.dcr * time_step
            put!(event_channel, current_time)  # Send dark count event to channel
        end
    end

    # Signal that SPAD is done producing events by closing the channel
    close(event_channel)
end

struct Gate
    freq::Float64      # Frequency of control signal (10 MHz)
    duty_cycle::Float64  # Duty cycle (0.2 for 20%)
end

function run_gate(gate::Gate, event_channel::Channel, output_channel::Channel, sim_time::Float64=100e-6)
    control_period = 1 / gate.freq
    high_time = control_period * gate.duty_cycle

    while isopen(event_channel)  # Check if the event channel is still open
        if isready(event_channel)  # Check if there is an event ready to be processed
            event_time = take!(event_channel)  # Take event from channel (blocking)
            
            # Check if event happens during the "high" gate period
            gate_open = mod(event_time, control_period) <= high_time
            put!(output_channel, gate_open)  # Send gate output to output channel
        end
    end

    close(output_channel)  # Signal that Gate is done processing
end

# Example usage with SPAD
function run_spad_with_gate(spad::SPAD, gate::Gate, sim_time::Float64=100e-6)
    # Create channels for communication between SPAD and Gate
    event_channel = Channel{Float64}(100)  # Buffer size of 100 events
    output_channel = Channel{Bool}(100)    # Output from the gate (True/False)

    # Run SPAD in a task to produce events asynchronously
    @async begin
        run_spad(spad, event_channel)
    end

    # Run Gate in another task to consume events asynchronously
    @async begin
        run_gate(gate, event_channel, output_channel)
    end

    # Collect the gate output after the simulation
    gate_output = []
    max_wait_time = 1_000  # Limit the number of attempts to check the output_channel
    wait_counter = 0

    while isopen(output_channel) || wait_counter < max_wait_time
        if isready(output_channel)
            push!(gate_output, take!(output_channel))  # Collect results from output channel
        else
            wait_counter += 1
            sleep(0.0001)  # Short delay to avoid busy waiting
        end
    end

    return gate_output
end


end # module spadsim
