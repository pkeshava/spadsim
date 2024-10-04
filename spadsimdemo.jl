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
spad = spadsim.SPAD(40e6, 0.3, 1e3)  # SPAD parameters
gate = spadsim.Gate(10e6, 0.2)      # Gate with 10 MHz frequency and 20% duty cycle

# Run the simulation
gate_output = spadsim.run_spad_with_gate(spad, gate)

# Print results (for demonstration)
println("Gate output: ", gate_output)