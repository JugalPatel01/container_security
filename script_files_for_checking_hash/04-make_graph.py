import csv
import matplotlib.pyplot as plt

# Read data from CSV files
def read_csv(file_path):
    cpu_usage = []
    mem_usage = []
    with open(file_path, 'r') as file:
        csv_reader = csv.reader(file)
        for row in csv_reader:
            cpu_usage.append(float(row[0]))
            mem_usage.append(float(row[1]))
    return cpu_usage, mem_usage

# Read data from CSV files
cpu_usage_without_script, mem_usage_without_script = read_csv('metrics_without_script.csv')
cpu_usage_with_script, mem_usage_with_script = read_csv('metrics_with_script.csv')

# Calculate average CPU and memory usage
avg_cpu_without_script = sum(cpu_usage_without_script) / len(cpu_usage_without_script)
avg_mem_without_script = sum(mem_usage_without_script) / len(mem_usage_without_script)
avg_cpu_with_script = sum(cpu_usage_with_script) / len(cpu_usage_with_script)
avg_mem_with_script = sum(mem_usage_with_script) / len(mem_usage_with_script)

# Print the average CPU and memory usage
print("Average CPU usage without script: {:.2f}%".format(avg_cpu_without_script))
print("Average Memory usage without script: {:.2f}%".format(avg_mem_without_script))
print("Average CPU usage with script: {:.2f}%".format(avg_cpu_with_script))
print("Average Memory usage with script: {:.2f}%".format(avg_mem_with_script))

# Plot the CPU usage graph
plt.figure(figsize=(10, 6))
plt.plot(cpu_usage_without_script, label="Without Script")
plt.plot(cpu_usage_with_script, label="With Script")
plt.xlabel("Time (seconds)")
plt.ylabel("CPU Usage (%)")
plt.title("CPU Usage Comparison")
plt.legend()
plt.grid(True)
plt.text(0.1, 0.9, "Avg CPU Usage:\nWithout Script: {:.2f}%\nWith Script: {:.2f}%".format(avg_cpu_without_script, avg_cpu_with_script),
         transform=plt.gca().transAxes, fontsize=12, verticalalignment='top')
plt.savefig("cpu_usage_comparison.png")
plt.close()

# Plot the memory usage graph
plt.figure(figsize=(10, 6))
plt.plot(mem_usage_without_script, label="Without Script")
plt.plot(mem_usage_with_script, label="With Script")
plt.xlabel("Time (seconds)")
plt.ylabel("Memory Usage (%)")
plt.title("Memory Usage Comparison")
plt.legend()
plt.grid(True)
plt.text(0.1, 0.9, "Avg Memory Usage:\nWithout Script: {:.2f}%\nWith Script: {:.2f}%".format(avg_mem_without_script, avg_mem_with_script),
         transform=plt.gca().transAxes, fontsize=12, verticalalignment='top')
plt.savefig("memory_usage_comparison.png")
plt.close()

print("Graphs saved as 'cpu_usage_comparison.png' and 'memory_usage_comparison.png'")