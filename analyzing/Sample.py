#
# Title: Sample.py
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-06-13
# Description: 
# Example:  
#

import numpy as np

class Sample: 
    def __init__(self,
                 healthy: bool,
                 model: int, 
                 temp_avg: list[float],
                 temp_max: list[int],
                 cpu_avg: list[float],
                 cpu_max: list[int],
                 latency_avg: list[int],
                 latency_max: list[int]):
        
        self.healthy = healthy
        
        if (model == "anon_model_c"):
            self.model = 0
        elif (model == "anon_model_j"):
            self.model = 1

        self.temp_avg = float(np.mean(temp_avg))
        self.temp_avg_stdev = float(np.std(temp_avg))
        self.temp_avg_slope = self.slope(temp_avg)
        self.temp_max = float(np.max(temp_max))
        self.temp_max_stdev = float(np.std(temp_max))
        self.temp_max_slope = self.slope(temp_max)
        self.cpu_avg = float(np.mean(cpu_avg))
        self.cpu_avg_stdev = float(np.std(cpu_avg)) 
        self.cpu_avg_slope = self.slope(cpu_avg)
        self.cpu_max = float(np.max(cpu_max))
        self.cpu_max_stdev = float(np.std(cpu_max))
        self.cpu_max_slope = self.slope(cpu_max)
        self.latency_avg = float(np.mean(latency_avg))
        self.latency_avg_stdev = float(np.std(latency_avg))
        self.latency_avg_slope = self.slope(latency_avg)
        self.latency_max = float(np.max(latency_max))
        self.latency_max_stdev = float(np.std(latency_max))
        self.latency_max_slope = self.slope(latency_max)


    def slope(self, nums: list[int]) -> int:
        return (nums[-1] - nums[0]) / len(nums)


    def to_dict(self):
        return {
            'healthy': self.healthy,
            'model': self.model, 
            'temp_avg': self.temp_avg,
            'temp_max': self.temp_max,
            'cpu_avg': self.cpu_avg,
            'cpu_max': self.cpu_max,
            'latency_avg': self.latency_avg,
            'latency_max': self.latency_max
        }


    def to_array(self):
        if self.healthy:
            self.healthy = 1
        else:
            self.healthy = 0

        return [
            self.healthy,
            self.model,
            self.temp_avg,
            self.temp_max,
            self.cpu_avg,
            self.cpu_max,
            self.latency_avg,
            self.latency_max
        ]

    
    def __str__(self):
        model_str = "anon_model_c" if self.model == 0 else "anon_model_j"
        return (f"Sample(healthy={self.healthy}, model={model_str}, "
                f"temp_avg={self.temp_avg:.2f}, temp_avg_stdev={self.temp_avg_stdev:.2f}, temp_avg_slope={self.temp_avg_slope:.2f}, "
                f"temp_max={self.temp_max:.2f}, temp_max_stdev={self.temp_max_stdev:.2f}, temp_max_slope={self.temp_max_slope:.2f}, "
                f"cpu_avg={self.cpu_avg:.2f}, cpu_avg_stdev={self.cpu_avg_stdev:.2f}, cpu_avg_slope={self.cpu_avg_slope:.2f}, "
                f"cpu_max={self.cpu_max:.2f}, cpu_max_stdev={self.cpu_max_stdev:.2f}, cpu_max_slope={self.cpu_max_slope:.2f}, "
                f"latency_avg={self.latency_avg:.2f}, latency_avg_stdev={self.latency_avg_stdev:.2f}, latency_avg_slope={self.latency_avg_slope:.2f}, "
                f"latency_max={self.latency_max:.2f}, latency_max_stdev={self.latency_max_stdev:.2f}, latency_max_slope={self.latency_max_slope:.2f})")

