include("./src/spadsim.jl")
using .spadsim

#%%

lambda = 70e6     # 40 million photons per second
pde = 0.3        # 30% photon detection efficiency
dcr = 1e3        # 1000 dark counts per second
sim_time = 1000.0e-6  # 10 microsecond
time_step = 1e-9

avalanche_times = spadsim.simulate_spad(lambda, pde, dcr,sim_time, time_step)
println("Avalanche times: ", avalanche_times)

#%%

using Plots

# Assuming simulate_spad has been run and you have avalanche_times

# Step 1: Calculate inter-arrival times
if length(avalanche_times) > 1
    inter_arrival_times = diff(avalanche_times)  # Compute differences between consecutive times
else
    inter_arrival_times = Float64[]  # Empty if no or single avalanche
end

# Step 2: Plot the histogram of inter-arrival times
histogram(inter_arrival_times, bins=50, title="Inter-Arrival Time Histogram",
          xlabel="Inter-Arrival Time (s)", ylabel="Frequency", legend=false)

# No need to call display(), the plot should automatically render

#%%
# Create the SPAD and Gate modules
spad = spadsim.SPAD(40e6, 0.3, 1e3, 0e-9)  # SPAD parameters
gate = spadsim.Gate(10e6, 0.2)      # Gate with 10 MHz frequency and 20% duty cycle

# Run the simulation
gate_output = spadsim.run_spad_with_gate(spad, gate)

# Print results (for demonstration)
println("Gate output: ", gate_output)

#%% SPAD and gate with dead time

# Create the SPAD module with dead time
# Example usage
spad = spadsim.SPAD(40e6, 0.3, 1e3, 5e-9)  # SPAD with 5 ns dead time
gate = spadsim.Gate(10e6, 0.2)  # Gate with 10 MHz frequency and 20% duty cycle

# Run the SPAD and Gate concurrently
gate_output = spadsim.run_spad_with_dead_time_and_gate(spad, gate)

# Print results (for demonstration)
println("Gate output: ", gate_output)


#%% SPAD with dead time, no gate

# Example usage
spad = spadsim.SPAD(70e6, 0.3, 1e3, 200e-9)  # SPAD parameters with 50 ns dead time
event_channel = Channel{Float64}(1000)  # Buffer size of 100 events

# Run SPAD asynchronously
@async spadsim.run_spad_with_dead_time(spad, event_channel, 100e-6)  # Run for 100 µs

# Collect avalanche times from the channel
avalanche_times = spadsim.collect_avalanche_times(event_channel)

using Plots
# Plot histogram of inter-arrival times
if length(avalanche_times) > 1
    inter_arrival_times = diff(avalanche_times)  # Compute inter-arrival times
    histogram(inter_arrival_times, bins=50, title="Inter-Arrival Time Histogram", xlabel="Inter-Arrival Time (s)", ylabel="Frequency", legend=false)
end
