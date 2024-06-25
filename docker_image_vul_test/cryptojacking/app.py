import numpy as np

def calculate_pi(n):
    """
    Calculate the value of pi using a CPU-intensive algorithm.
    """
    k = 0
    x = 0
    for i in range(n):
        x += (-1)**k / (2*k + 1)
        k += 1
    return x * 4

if __name__ == '__main__':
    while True:
        # Calculate pi with a large number of iterations
        pi = calculate_pi(10**8)
        print(f"Calculated value of pi: {pi}")
