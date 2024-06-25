from flask import Flask
import time
import threading

app = Flask(__name__)

# Flag to track if the application is responsive
is_responsive = True

# Function to simulate a long-running operation
def simulate_long_operation():
    global is_responsive
    is_responsive = False
    time.sleep(10)
    is_responsive = True

@app.route('/')
def hello_world():
    # Start a new thread to simulate the long-running operation
    thread = threading.Thread(target=simulate_long_operation)
    thread.start()

    # Check if the application is responsive
    if is_responsive:
        return 'Hello, World! The application is responsive.'
    else:
        return 'The application is currently unresponsive due to a long-running operation.'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
