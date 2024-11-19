#%% ----------------------------------------------------------------------------
include("./src/spadsim.jl")
using .spadsim

#%%
lambda = 70e6     # 40 million photons per second
pde = 0.3        # 30% photon detection efficiency
dcr = 1e3        # 1000 dark counts per second
sim_time = 1000.0e-6  # 10 microsecond
time_step = 1e-9

#%% ----------------------------------------------------------------------------
avalanche_times = spadsim.simulate_spad(lambda, pde, dcr,sim_time, time_step)
#println("Avalanche times: ", avalanche_times)

# Step 1: Calculate inter-arrival times
if length(avalanche_times) > 1
    inter_arrival_times = diff(avalanche_times)  # Compute differences between consecutive times
else
    inter_arrival_times = Float64[]  # Empty if no or single avalanche
end

#%% ----------------------------------------------------------------------------


using Plots
using PythonPlot
using UnicodePlots
#using GLMakie
using StatsBase  # For histogram binning
using PGFPlotsX
using LaTeXStrings
#using CairoMakie

function plot_interarrival_histogram(inter_arrival_times::Vector{Float64}, bin_width::Float64, yscale_option::Symbol, backend::Symbol=:pgfplotsx)
    # Step 1: Bin the data
    # Determine the range of data
    min_val = minimum(inter_arrival_times)
    max_val = maximum(inter_arrival_times)

    # Generate bin edges based on the specified bin width
    bin_edges = range(min_val, stop=max_val, step=bin_width)
    
    # Step 2: Choose backend
        
    if backend == :plotlyjs
        plotlyjs()
        plot(edges[1:end-1], counts, label="Inter-arrival Histogram", xlabel="Time (s)", ylabel="Counts", yscale=yscale_option)
        
    elseif backend == :pgfplotsx
        pgfplotsx()
        Plots.histogram(
            inter_arrival_times,
            bins=bin_edges[1:end-1],
            normalize= :probability,
            label = "Experimental"
        )
        #display(histogram_plot)
        
    elseif backend == :unicode
        unicodeplots()
        Plots.histogram(inter_arrival_times, bins=bin_edges)
        
    elseif backend == :glmakie
        fig = GLMakie.Figure(resolution = (800, 600))
        # Add an axis to the figure
        ax = GLMakie.Axis(
                fig[1, 1], 
                title = "Histogram", 
                xlabel = "Value", 
                ylabel = "Frequency",
            )

        # Plot a histogram on the axis
        GLMakie.hist!(
            ax, 
            inter_arrival_times, 
            bins=bin_edges[1:end-1], 
            color = :blue,
            label="Inter-arrival Histogram"
        )
        display(fig)

        
    else
        println("Unsupported backend. 
        Choose from, :pythonplot, 
        :pgfplotsx, :unicode, or :glmakie., 
        plotting in default pythonplot")
        pythonplot()
        Plots.histogram(
            inter_arrival_times, 
            bins=bin_edges, 
            title="Inter-Arrival Time Histogram", 
            xlabel="Inter-Arrival Time (s)", 
            ylabel="Frequency", 
            legend=false, 
            yscale=yscale_option
        )
    
    end
end

# Example usage:
bin_width = 5e-9
yscale_option = :log10
plot_interarrival_histogram(inter_arrival_times, bin_width, yscale_option, :normal)



#%% ----------------------------------------------------------------------------


using Plots

# Assuming simulate_spad has been run and you have avalanche_times

# Step 1: Calculate inter-arrival times
if length(avalanche_times) > 1
    inter_arrival_times = diff(avalanche_times)  # Compute differences between consecutive times
else
    inter_arrival_times = Float64[]  # Empty if no or single avalanche
end

bin_width = 5e-9
# Determine the range of data
min_val = minimum(inter_arrival_times)
max_val = maximum(inter_arrival_times)

# Generate bin edges based on the specified bin width
bin_edges = range(min_val, stop=max_val, step=bin_width)

yscale_option = :log10

# Step 2: Plot the histogram of inter-arrival times
p=histogram(inter_arrival_times, bins=bin_edges, title="Inter-Arrival Time Histogram", xlabel="Inter-Arrival Time (s)", ylabel="Frequency", legend=false, yscale=yscale_option)


#%% ----------------------------------------------------------------------------


using Statistics
using LsqFit
# Function to fit and plot inter-arrival times with exponential curve
exponential_model(x, p) = p[1] * exp.(-p[2] * x)


# Fit range for inter-arrival values between 10e-9 and 100e-9 seconds
fit_range = (10e-9, 100e-9)

# Set a custom bin width (for example, 10 nanoseconds)
bin_width = 10e-9  # 10 nanoseconds

log_axis=:none
fit_range=(minimum(inter_arrival_times), maximum(inter_arrival_times))
# Filter the data based on the fit range
filtered_data = filter(x -> fit_range[1] <= x <= fit_range[2], inter_arrival_times)

# Fit the data to an exponential model using LsqFit
initial_params = [maximum(filtered_data), 1 / mean(filtered_data)]  # Initial guess for [A, B]
fit = curve_fit(exponential_model, filtered_data, ones(length(filtered_data)), initial_params)
fitted_params = fit.param  # Fitted [A, B]

# Generate fitted curve data for plotting
x_fit = range(fit_range[1], stop=fit_range[2], length=100)
y_fit = exponential_model(x_fit, fitted_params)

# Determine the range of data
min_val = minimum(inter_arrival_times)
max_val = maximum(inter_arrival_times)

# Generate bin edges based on the specified bin width
bin_edges = range(min_val, stop=max_val, step=bin_width)

# Set the log scale for x and/or y axes based on log_axis input
xscale_option = log_axis in [:x, :both] ? :log10 : :ln
yscale_option = log_axis in [:y, :both] ? :log10 : :ln

# Plot the histogram with custom bin edges
pp = histogram(inter_arrival_times, bins=bin_edges, title="Inter-Arrival Time Histogram (with Exponential Fit)",
xlabel="Inter-Arrival Time (s)", ylabel="Frequency", legend=false, xscale=xscale_option, yscale=yscale_option)

# Add the fitted curve to the plot
plot!(pp, x_fit, y_fit, label="Exponential Fit", lw=2, color=:red)

# Return the fitted parameters for reference
fitted_params

# Example usage: Assuming inter_arrival_times is already computed from your SPAD simulation



# Print the fitted parameters for reference
println("Fitted parameters: A = $(fitted_params[1]), B = $(fitted_params[2])")

