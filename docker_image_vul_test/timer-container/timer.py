import time

class Timer:
    def __init__(self):
        self.start_time = None
    
    def start(self):
        self.start_time = time.time()
    
    def elapsed_seconds(self):
        if self.start_time is None:
            raise ValueError("Timer hasn't been started yet.")
        return int(time.time() - self.start_time)

if __name__ == "__main__":
    timer = Timer()
    timer.start()
    print("Timer started.")
    while True:
        print("Elapsed seconds:", timer.elapsed_seconds())
        time.sleep(1)

